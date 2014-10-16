=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::Blast::InputForm;

use strict;
use warnings;
use URI;
use previous qw(get_form_node);
use List::Util qw(min);

sub get_form_node {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;
  my $form            = $self->PREV::get_form_node(@_);
  my $default_species = $species_defs->valid_species($hub->species) ? $hub->species : $species_defs->ENSEMBL_PRIMARY_SPECIES;
  my @species         = $hub->param('species') || $default_species;
  
  my $list            = join '<br />', map { $species_defs->species_display_label($_) } @species;
  my $checkboxes      = join '<br />', map { sprintf('<input type="checkbox" name="species" value="%s" checked>%s', $_, $_) } @species;
  
  # set uri for the modal link
  my $modal_uri = URI->new("/${default_species}/Component/Blast/Web/TaxonSelector/ajax?");
  $modal_uri->query_form(s => [map {lc($_)} @species]); 
  
  my $html = qq{
    <div class="js_panel taxon_selector_form">
      <input class="panel_type" value="BlastSpeciesList" type="hidden">
      <div class="list-wrapper">
        <div class="list">$list</div>
        <div class="links"><a class="modal_link data" href="${modal_uri}">Add/remove species</a></div>
      </div>
      <div class="checkboxes">$checkboxes</div>
    </div>
  };

  my $ele = shift @{$form->get_elements_by_class_name('_species_dropdown')};
  $ele->inner_HTML($html);

  return $form;
}

1;
