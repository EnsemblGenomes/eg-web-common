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

package EnsEMBL::Web::Component::TextSequence;

use strict;
use warnings;

use previous qw(buttons);

sub buttons {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my @buttons      = $self->PREV::buttons(@_);

  my $show_seq_search = $species_defs->ENSEMBL_ENASEARCH_ENABLED && $hub->type ne 'Tools' && $hub->action !~ /Align/;

  if ($self->can('blast_options') and my $options = $self->blast_options) {
    $show_seq_search = 0 if $options->{no_button};
  }

  if ($show_seq_search) {
    push @buttons, {
      'caption'   => 'Search Ensembl Genomes with this sequence',
      'url'       => '/Multi/enasearch',
      'class'     => 'find hidden _enasearch_button'
    };
  }

  return @buttons;
}

1;
