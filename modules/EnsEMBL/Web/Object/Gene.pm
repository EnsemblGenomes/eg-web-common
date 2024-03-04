=head1 LICENSE

Copyright [2009-2024] EMBL-European Bioinformatics Institute

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

use JSON;
use EnsEMBL::Web::TmpFile::Text;
use Compress::Zlib;

use strict;
use previous qw(get_homology_matches availability);

sub availability {
  my $self = shift;
  $self->PREV::availability(@_);
  $self->{_availability}->{"has_interactions"} = $self->interaction_check;
  return $self->{_availability};
}

sub interaction_check {
  my $self = shift;
  my $interactionsGenelist = $self->species_defs->get_config($self->species, 'INTERACTION_GENELIST');
  my $gene = $self->gene->stable_id;
  my $match = grep /$gene/, @$interactionsGenelist;
  return $match ? 1 : 0;
}

sub get_go_list {
  my $self = shift ;
  
  # The array will have the list of ontologies mapped 
  my $ontologies = $self->species_defs->SPECIES_ONTOLOGIES || return {};

  my $dbname_to_match = shift || join '|', @$ontologies;
  my $ancestor=shift;
  my $gene = $self->gene;
  my $goadaptor = $self->hub->get_adaptor('get_OntologyTermAdaptor', 'go');

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

      my $info_text = $goxref->info_text;
      my $sources;

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

      if ($goadaptor) {
        my $term;
        eval { 
          $term = $goadaptor->fetch_by_accession($go); 
        };

        warn $@ if $@;

        my $term_name = $term ? $term->name : '';
        $term_name ||= $goxref->description || '';

        my $has_ancestor = (!defined ($ancestor));
        if (!$has_ancestor){
          $has_ancestor=($go eq $ancestor);
          my $term = $goadaptor->fetch_by_accession($go);

          if ($term) {
            my $ancestors = $goadaptor->fetch_all_by_descendant_term($term);
            for(my $i=0; $i< scalar (@$ancestors) && !$has_ancestor; $i++){
              $has_ancestor=(@{$ancestors}[$i]->accession eq $ancestor);
            }
          }
        }
     
        if($has_ancestor){        
          my $hub = $self->hub;
          my ($source, $mapped);
          if ($info_text =~ /from ([a-z]+[ _][a-z]+) (gene|translation) (\S+)/i) {
            my $gene        = $3;
            my $type        = $2;
            my $sci_name    = ucfirst $1;

            (my $species   = $sci_name) =~ s/ /_/g;     
      
            my $param_type = $type eq 'translation' ? 'p' : substr $type, 0, 1;
            my $url        = $hub->url({
                                        species     => $species,
                                        type        => 'Gene',
                                        action      => $type eq 'translation' ? 'Ontologies/'.$hub->function : 'Summary',
                                        $param_type => $gene,
                                        __clear     => 1,
                                      });

            $mapped = qq{Propagated from $sci_name <a href="$url">$gene</a> by orthology};
            $source = 'Ensembl';

          } else {
            $mapped = join ', ', @{$sources || []};
            $source = $info_text;
          }


          $go_hash{$go} = {
            transcript_id => $transcript_id,
            evidence      => $evidence,
            term          => $term_name,
            source        => $source,
            mapped        => $mapped,
## EG
            extensions    => \@extensions,
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

1;
