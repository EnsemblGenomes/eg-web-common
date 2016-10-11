=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ViewConfig::Gene::ComparaOrthologs;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init_cacheable {
  my $self = shift;
## EG  
  $self->set_default_options({ map { 'species_' . lc($_) => 'yes' } $self->_get_compara_species() });
##  
  $self->title('Homologs');
}

sub form {
  my $self = shift;
  
  $self->add_fieldset('Selected species');
  
  my $species_defs = $self->species_defs;
## EG  
  my %species      = map { $species_defs->species_label($_) => $_ } $self->_get_compara_species();
##  
  foreach (sort { ($a =~ /^<.*?>(.+)/ ? $1 : $a) cmp ($b =~ /^<.*?>(.+)/ ? $1 : $b) } keys %species) {
    $self->add_form_element({
      type  => 'CheckBox', 
      label => $_,
      name  => 'species_' . lc $species{$_},
      value => 'yes',
      raw   => 1
    });
  }
}

## EG - get species list from compara db (ENSEMBL-4604, ENSEMBL-4584)
sub _get_compara_species {
  my $self       = shift;
  my $hub        = $self->hub; 
  my $function   = $hub->function;
  
  if ($hub->action eq 'ComparaOrthologs') {
    # running in modal context, need to get function from referer
    $function = $hub->referer->{ENSEMBL_FUNCTION};
  }

  my $compara_db = $function eq 'pan_compara' ? 'compara_pan_ensembl' : 'compara';
  my $genome_dbs = $hub->database($compara_db)->get_GenomeDBAdaptor->fetch_all;
  
  return map {$_->name} @$genome_dbs;
}
##

1;
