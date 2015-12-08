=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

# $Id: Gene.pm,v 1.29 2013-12-06 12:09:01 nl2 Exp $

package EnsEMBL::Web::Object::Gene;

use Data::Dumper;
use JSON;
use EnsEMBL::Web::TmpFile::Text;
use Compress::Zlib;
use Data::Dumper;

use strict;
use previous qw(
  counts 
  availability 
  get_homology_matches 
  get_desc_mapping
);

## EG suppress the default Ensembl display label
sub get_homology_matches {
  my $self = shift;
  my $matches = $self->PREV::get_homology_matches(@_);
  foreach my $sp (values %$matches) {
    $_->{display_id} =~ s/^Novel Ensembl prediction$// for (values %$sp);
  }
  return $matches;
}


## EG add eg-specific mappings
sub get_desc_mapping {
  my $self = shift;
  my %mapping = $self->PREV::get_desc_mapping(@_);
  return (
    %mapping,
    gene_split          => 'gene split',
    homoeolog_one2one   => '1-to-1',
    homoeolog_one2many  => '1-to-many',
    homoeolog_many2many => 'many-to-many',   
  )
}

sub availability {
  my $self = shift;
  $self->PREV::availability(@_);
 
  my $obj = $self->Obj;
    
  if ($obj->isa('Bio::EnsEMBL::Gene')) {
    my $member     = $self->database('compara') ? $self->database('compara')->get_GeneMemberAdaptor->fetch_by_stable_id($obj->stable_id) : undef;
    my $pan_member = $self->database('compara_pan_ensembl') ? $self->database('compara_pan_ensembl')->get_GeneMemberAdaptor->fetch_by_stable_id($obj->stable_id) : undef;
    my $counts     = $self->counts($member, $pan_member);
    
    $self->{_availability}->{has_homoeologs} = $counts->{homoeologs};
    
    $self->{_availability}->{has_gene_supporting_evidence} = $counts->{gene_supporting_evidence};
  }

  return $self->{_availability};
}

sub _counts {
  my ($self, $member, $pan_member) = @_;
  my $obj = $self->Obj;

  return {} unless $obj->isa('Bio::EnsEMBL::Gene');
  
  my $counts = $self->{'_counts'};
 
  if (!$counts) {    
    if ($member) {
      $counts->{'homoeologs'} = $member->number_of_homoeologues;
    }
    $counts->{'gene_supporting_evidence'} = $self->count_gene_supporting_evidence;
  }
    
  return $counts || {};
}

sub store_TransformedTranscripts {
  my $self = shift;
## EG  
  my $offset = shift;  
##

  $offset ||= $self->__data->{'slices'}{'transcripts'}->[1]->start -1;

  foreach my $trans_obj ( @{$self->get_all_transcripts} ) {
    my $transcript = $trans_obj->Obj;
  my ($raw_coding_start,$coding_start);
  if (defined( $transcript->coding_region_start )) {    
    $raw_coding_start = $transcript->coding_region_start;
    $raw_coding_start -= $offset;
    $coding_start = $raw_coding_start + $self->munge_gaps( 'transcripts', $raw_coding_start );
  }
  else {
    $coding_start  = undef;
    }

  my ($raw_coding_end,$coding_end);
  if (defined( $transcript->coding_region_end )) {
    $raw_coding_end = $transcript->coding_region_end;
    $raw_coding_end -= $offset;
    $coding_end = $raw_coding_end + $self->munge_gaps( 'transcripts', $raw_coding_end );
  }
  else {
    $coding_end = undef;
  }
    my $raw_start = $transcript->start;
    my $raw_end   = $transcript->end  ;
    my @exons = ();
    foreach my $exon (@{$transcript->get_all_Exons()}) {
      my $es = $exon->start - $offset; 
      my $ee = $exon->end   - $offset;
      my $O =  $self->munge_gaps( 'transcripts', $es );

      push @exons, [ $es + $O, $ee + $O, $exon ];
    }
    $coding_start ||= 1;
    $coding_end   ||= 1;
    $trans_obj->__data->{'transformed'}{'exons'}        = \@exons;
    $trans_obj->__data->{'transformed'}{'coding_start'} = $coding_start;
    $trans_obj->__data->{'transformed'}{'coding_end'}   = $coding_end;
    $trans_obj->__data->{'transformed'}{'start'}        = $raw_start;
    $trans_obj->__data->{'transformed'}{'end'}          = $raw_end;
  }
}

sub store_TransformedDomains {
    my $self = shift;
    my $key  = shift;
## EG    
    my $offset = shift;
##
    my %domains;

    $offset ||= $self->__data->{'slices'}{'transcripts'}->[1]->start -1;
    foreach my $trans_obj ( @{$self->get_all_transcripts} ) {
	my %seen;
	my $transcript = $trans_obj->Obj;
	next unless $transcript->translation;
	foreach my $pf ( @{$transcript->translation->get_all_ProteinFeatures( lc($key) )} ) {
## rach entry is an arry containing the actual pfam hit, and mapped start and end co-ordinates
	    if (exists $seen{$pf->id}{$pf->start}){
		next;
	    } else {
		$seen{$pf->id}->{$pf->start} =1;
		my @A = ($pf);
		foreach( $transcript->pep2genomic( $pf->start, $pf->end ) ) {
		    my $O = $self->munge_gaps( 'transcripts', $_->start - $offset, $_->end - $offset) - $offset;
		    push @A, $_->start + $O, $_->end + $O;
		}
		push @{$trans_obj->__data->{'transformed'}{lc($key).'_hits'}}, \@A;
	    }
	}
    }
}

sub get_Slice {
  my ($self, $context, $ori) = @_;
## EG
  # HORRIBLE HACK: if we've got a variation zoom slice, serve it instead of the original slice
  my $slice;
  if ($self->{_variation_zoom_slice}) {
    $slice   = $self->{_variation_zoom_slice};
    $context = 'FULL';
  } else {
    $slice   = $self->Obj->feature_Slice;
    $context = $slice->length * $1 / 100 if $context =~ /(\d+)%/;
  }
##  
  $slice    = $slice->invert if $ori && $slice->strand != $ori;
  
  return $slice->expand($context, $context);
}

## EG - remove status from gene type
sub gene_type {
  my $self = shift;
  my $db = $self->get_db;
  my $type = '';
  if( $db eq 'core' ){
    #$type = ucfirst(lc($self->Obj->status))." ".$self->Obj->biotype;
    $type = $self->Obj->biotype;
    $type =~ s/_/ /;
    $type ||= $self->db_type;
  } elsif ($db =~ /vega/) {
    #my $biotype = ($self->Obj->biotype eq 'tec') ? uc($self->Obj->biotype) : ucfirst(lc($self->Obj->biotype));
    #$type = ucfirst(lc($self->Obj->status))." $biotype";
    my $type = ($self->Obj->biotype eq 'tec') ? uc($self->Obj->biotype) : ucfirst(lc($self->Obj->biotype));
    $type =~ s/_/ /g;
    $type =~ s/unknown //i;
    return $type;
  } else {
    $type = $self->logic_name;
    if ($type =~/^(proj|assembly_patch)/ ){
      #$type = ucfirst(lc($self->Obj->status))." ".$self->Obj->biotype;
      $type = ucfirst($self->Obj->biotype);
    }
    $type =~ s/_/ /g;
    $type =~ s/^ccds/CCDS/;
  }
  $type ||= $db;
  if( $type !~ /[A-Z]/ ){ $type = ucfirst($type) } #All lc, so format
  return $type;
}

sub filtered_family_data {
  my ($self, $family) = @_;                                                                                              1;
  my $hub       = $self->hub;
  my $family_id = $family->stable_id;
  
  my $members = []; 
  my $temp_file = EnsEMBL::Web::TmpFile::Text->new(prefix => 'genefamily', filename => "$family_id.json"); 
   
  if ($temp_file->exists) {
    $members = eval{from_json($temp_file->content)} || [];
  } 

  if(!@$members) {
    my $member_objs = $family->get_all_Members;

    # API too slow, use raw SQL to get name and desc for all genes   
    my $gene_info = $self->database('compara')->dbc->db_handle->selectall_hashref(
      'SELECT g.gene_member_id, g.display_label, g.description FROM family f 
       JOIN family_member fm USING (family_id) 
       JOIN seq_member s USING (seq_member_id) 
       JOIN gene_member g USING (gene_member_id) 
       WHERE f.stable_id = ?',
      'gene_member_id',
      undef,
      $family_id
    );

    foreach my $member (@$member_objs) {
      my $gene = $gene_info->{$member->gene_member_id};
      push (@$members, {
        name        => $gene->{display_label},
        id          => $member->stable_id,
        taxon_id    => $member->taxon_id,
        description => $gene->{description},
        species     => $member->genome_db->name
      });  
    }

    if($temp_file->exists){
        $temp_file->delete;
        $temp_file->content('');
    }

    $temp_file->print($hub->jsonify($members));
    
  }  
  
  my $total_member_count  = scalar @$members;
     
  my $species;   
  $species->{$_->{species}} = 1 for (@$members);
  my $total_species_count = scalar keys %$species;
 
  # apply filter from session
 
  my @filter_species;
  if (my $filter = $hub->session->get_data(type => 'genefamilyfilter', code => $hub->data_species . '_' . $family_id )) {
    @filter_species = split /,/, uncompress( $filter->{filter} );
  }
    
  if (@filter_species) {
    $members = [grep {my $sp = $_->{species}; grep {$sp eq $_} @filter_species} @$members];
    $species = {};
    $species->{$_->{species}} = 1 for (@$members);
  } 
  
  # return results
  
  my $data = {
    members             => $members,
    species             => $species,
    member_count        => scalar @$members,
    species_count       => scalar keys %$species,
    total_member_count  => $total_member_count,
    total_species_count => $total_species_count,
    is_filtered         => @filter_species ? 1 : 0,
  };
  
  return $data;
}

sub get_go_list {
  my $self = shift ;
  
  # The array will have the list of ontologies mapped 
  my $ontologies = $self->species_defs->SPECIES_ONTOLOGIES || return {};

  my $dbname_to_match = shift || join '|', @$ontologies;
  my $ancestor=shift;
  my $gene = $self->gene;
  my $goadaptor = $self->hub->get_databases('go')->{'go'};

  my @goxrefs = @{$gene->get_all_DBLinks};
  my @my_transcripts= @{$self->Obj->get_all_Transcripts};

  my %hash;
  my %go_hash;  
  my $transcript_id;
  foreach my $transcript (@my_transcripts) {    
    $transcript_id = $transcript->stable_id;
    
    foreach my $goxref (sort { $a->display_id cmp $b->display_id } @{$transcript->get_all_DBLinks}) {
      my $go = $goxref->display_id;
      chomp $go; # Just in case
      next unless ($goxref->dbname =~ /^($dbname_to_match)$/);

      my ($otype, $go2) = $go =~ /([\w|\_]+):0*(\d+)/;
      my $term;
      
      if(exists $hash{$go2}) {      
        $go_hash{$go}{transcript_id} .= ",$transcript_id" if($go_hash{$go} && $go_hash{$go}{transcript_id}); # GO terms with multiple transcript
        next;
      }

      my $info_text;
      my $sources;

      if ($goxref->info_type eq 'PROJECTION') {
        $info_text= $goxref->info_text; 
      }

      my $evidence = '';
## EG
      my @extensions;
##      
      if ($goxref->isa('Bio::EnsEMBL::OntologyXref')) {
        $evidence = join ', ', @{$goxref->get_all_linkage_types}; 

        foreach my $e (@{$goxref->get_all_linkage_info}) {      
          my ($linkage, $xref) = @{$e || []};
          next unless $xref;
          my ($did, $pid, $db, $db_name) = ($xref->display_id, $xref->primary_id, $xref->dbname, $xref->db_display_name);
          my $label = "$db_name:$did";

          #db schema won't (yet) support Vega GO supporting xrefs so use a specific form of info_text to generate URL and label
          my $vega_go_xref = 0;
          my $info_text = $xref->info_text;
          if ($info_text =~ /Quick_Go:/) {
            $vega_go_xref = 1;
            $info_text =~ s/Quick_Go://;
            $label = "(QuickGO:$pid)";
          }
          my $ext_url = $self->hub->get_ExtURL_link($label, $db, $pid, $info_text);
          $ext_url = "$did $ext_url" if $vega_go_xref;
          push @$sources, $ext_url;
        }
## EG
        push @extensions, @{$goxref->get_extensions()};
##        
      }

      $hash{$go2} = 1;

      if (my $goa = $goadaptor->get_GOTermAdaptor) {
        my $term;
        eval { 
          $term = $goa->fetch_by_accession($go); 
        };

        warn $@ if $@;

        my $term_name = $term ? $term->name : '';
        $term_name ||= $goxref->description || '';

        my $has_ancestor = (!defined ($ancestor));
        if (!$has_ancestor){
          $has_ancestor=($go eq $ancestor);
          my $term = $goa->fetch_by_accession($go);

          if ($term) {
            my $ancestors = $goa->fetch_all_by_descendant_term($term);
            for(my $i=0; $i< scalar (@$ancestors) && !$has_ancestor; $i++){
              $has_ancestor=(@{$ancestors}[$i]->accession eq $ancestor);
            }
          }
        }
     
        if($has_ancestor){        
          $go_hash{$go} = {
            transcript_id => $transcript_id,
            evidence => $evidence,
            term     => $term_name,
            info     => $info_text,
            source   => join(' ,', @{$sources || []}),
## EG
            extensions => \@extensions,
##
          };
        }
      }

    }
  }

  return \%go_hash;
}

1;
