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
use previous qw(get_homology_matches get_desc_mapping);

sub get_go_list {
  my $self = shift ;
  
  # The array will have the list of ontologies mapped 
  my $ontologies = $self->species_defs->SPECIES_ONTOLOGIES || return {};

  my $dbname_to_match = shift || join '|', @$ontologies;
  my $ancestor=shift;
  my $gene = $self->gene;
  my $goadaptor = $self->hub->database('go');

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
            source   => join(', ', @{$sources || []}),
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

sub filtered_family_data {
  my ($self, $family) = @_;
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

## EG Revert genome_db name hack
## see comments here https://github.com/Ensembl/ensembl-webcode/commit/cf7605438bc0a7bbf8df3ca90b149bfdd48ebaee
sub fetch_homology_species_hash {
  my $self                 = shift;
  my $homology_source      = shift;
  my $homology_description = shift;
  my $compara_db           = shift || 'compara';
  my ($homologies, $classification, $query_member) = $self->get_homologies($homology_source, $homology_description, $compara_db);
  my %homologues;

  foreach my $homology (@$homologies) {
    my ($query_perc_id, $target_perc_id, $genome_db_name, $target_member, $dnds_ratio, $goc_score, $wgac, $highconfidence, $goc_threshold, $wga_threshold);
    
    foreach my $member (@{$homology->get_all_Members}) {
      my $gene_member = $member->gene_member;

      if ($gene_member->stable_id eq $query_member->stable_id) {
        $query_perc_id = $member->perc_id;
      } else {
        $target_perc_id = $member->perc_id;
        $genome_db_name = $member->genome_db->name;
        $target_member  = $gene_member;
        $dnds_ratio     = $homology->dnds_ratio; 
        $goc_score      = $homology->goc_score;
        $goc_threshold  = $homology->method_link_species_set->get_value_for_tag('goc_quality_threshold');        
        $wgac           = $homology->wga_coverage;
        $wga_threshold  = $homology->method_link_species_set->get_value_for_tag('wga_quality_threshold');
        $highconfidence = $homology->is_high_confidence;
      }      
    }

    # FIXME: ucfirst $genome_db_name is a hack to get species names right for the links in the orthologue/paralogue tables.
    # There should be a way of retrieving this name correctly instead.
    push @{$homologues{ucfirst $genome_db_name}}, [ $target_member, $homology->description, $homology->species_tree_node(), $query_perc_id, $target_perc_id, $dnds_ratio, $homology->{_gene_tree_node_id}, $homology->dbID, $goc_score, $goc_threshold, $wgac, $wga_threshold, $highconfidence ];    
  }

  @{$homologues{$_}} = sort { $classification->{$a->[2]} <=> $classification->{$b->[2]} } @{$homologues{$_}} for keys %homologues;  

  return \%homologues;
}
##

1;
