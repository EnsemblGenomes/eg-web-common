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

package EnsEMBL::Web::Document::HTML::HomeSearchMulti;

use strict;

use EnsEMBL::Web::Form;
use EnsEMBL::Web::Hub;


sub render {
  my $self = shift;

  return $self->gene_search . 
         $self->genome_search;
}

sub gene_search {
  my $self = shift;
    
  my $hub          = EnsEMBL::Web::Hub->new;
  my $species_defs = $hub->species_defs;
  my $search_url   = $species_defs->ENSEMBL_WEB_ROOT . "Multi/psychic";
  my $q            = $hub->param('q');

  my $examples;
  my $sample_data = $species_defs->get_config('MULTI', 'GENERIC_DATA') || {};
  if (keys %$sample_data) {
    $examples = join ' or ', map { $sample_data->{$_}
      ? qq(<a class="nowrap" href="$search_url?q=$sample_data->{$_};site=ensemblunit">$sample_data->{$_}</a>)
      : ()
    } qw(GENE_TEXT LOCATION_TEXT SEARCH_TEXT);
    $examples = qq(<p class="search-example">e.g. $examples</p>) if $examples;
  }

  my $form = EnsEMBL::Web::Form->new({
    'action' => $search_url, 
    'method' => 'get', 
    'skip_validation' => 1, 
    'class' => [ 'homepage-search-form-multi', 'homepage-search-form', 'search-form', 'clear' ]
  });

  $form->add_hidden({'name' => 'site', 'value' => 'ensemblunit'});

  my $field = $form->add_field({'notes' => $examples});

  $field->add_element({
    'type'  => 'string', 
    'value' => 'Search all species...', 
    'id'    => 'q', 
    'name'  => 'q', 
    'size'  => 30, 
    'class' => 'query input inactive'
  }, 1);

  $field->add_element({'type' => 'submit', 'value' => 'Go'}, 1);

  my $elements_wrapper = $field->elements->[0];
  $elements_wrapper->append_child('span', {'class' => 'inp-group', 'children' => [ splice @{$elements_wrapper->child_nodes}, 0, 2 ]})->after({'node_name' => 'wbr'}) for (0..1);
  
  return sprintf (
    '<div id="SpeciesSearch" class="js_panel home-search-flex"><h3 class="first">Search for a gene</h3>
     <input type="hidden" class="panel_type" value="SearchBox" />%s</div>', 
    $form->render
  );
}

sub genome_search {
  
  my $hub          = EnsEMBL::Web::Hub->new;
  my $species_defs = $hub->species_defs;
  my $sample_data  = $species_defs->get_config('MULTI', 'GENERIC_DATA') || {};

  return qq{
    <div class="home-search-flex">
      <div id="species_list" class="js_panel">
        <input type="hidden" class="panel_type" value="SpeciesList" />
        <h3 class="first">Search for a genome</h3>
        <form id="species_autocomplete_form" action="species.html" style="margin-bottom:5px" method="get">
          <div>
           <input name="search" type="text" id="species_autocomplete" class="ui-autocomplete-input inactive" style="width:95\%; margin: 0; padding-left:4px" title="Start typing the name of a genome..." value="Start typing the name of a genome...">
          </div>
        </form>
        <p style="margin-bottom:0">
          e.g. $sample_data->{GENOME_SEARCH_TEXT}
        </p>
      </div>
    </div>
  };
}

1;
