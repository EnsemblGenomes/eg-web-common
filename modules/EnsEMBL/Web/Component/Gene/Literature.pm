=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::Literature;
use strict;

use URI::Escape qw(uri_escape);

use EnsEMBL::Web::Utils::Publications qw(get_publications_by_query_string);

use base qw(EnsEMBL::Web::Component::Gene);

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $html;
  
  my $query = uri_escape(sprintf '("%s") AND ("%s")', join('" OR "', @{$self->get_gene_names}),$hub->species_defs->SPECIES_SCIENTIFIC_NAME).'&synonym=true';
  ## Fetch a maximum of 50 results from this query
  my ($results, $error) = get_publications_by_query_string($query.'&pageSize=50', $hub);

  if ($error) {
  
    $html .= $self->_info_panel('error', 'Failed to fetch articles from EuropePMC', $results);
  
  } 
  else {

    if (scalar @$results) {

      $html .= sprintf '<p>Showing the top %d hits from <a href="https://europepmc.org/search?query=%s">Europe PubMed Central</a></p>', scalar(@$results), $query;

      my $table = $self->new_table(
        [
          { key => 'pubmed_id', title => 'PubMed&nbsp;ID', width => '6%',  align => 'left', sort => 'html' },
          { key => 'title',     title => 'Title',          width => '50%', align => 'left', sort => 'string' },
          { key => 'authors',   title => 'Authors',        width => '22%', align => 'left', sort => 'html' },
          { key => 'journal',   title => 'Journal',        width => '22%', align => 'left', sort => 'string' },
        ], 
        $results, 
        { 
          class      => 'no_col_toggle',
          data_table => 1, 
          exportable => 0,
          data_table_config => {
            iDisplayLength => 10
          },
        }
      );

      $html .= $table->render;  
    }
    else {
      $html .= sprintf '<p>There are no hits for this gene from <a href="https://europepmc.org/search?query=%s">Europe PubMed Central</a></p>', uri_escape($query); 
    }
  }
  return $html;
}

sub get_gene_names {
  my $self   = shift;
  my $obj    = $self->object->Obj;
  my @names  = ($obj->display_id);

  if ($obj->can('display_xref')) {
    if (my $xref = $obj->display_xref) {
      push @names, $xref->display_id;
      #push @names, @{$xref->get_all_synonyms}
    }
  }
  
  return \@names;
}

1;

