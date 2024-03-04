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

# $Id: Tabs.pm,v 1.4 2012-12-17 14:18:30 nl2 Exp $

package EnsEMBL::Web::Document::Element::Tabs;
use strict;
use warnings;

use previous qw(init);

## EG disable species dropdown (if specified)
sub init {
  my $self = shift;

  $self->PREV::init(@_);
  
  return unless $self->species_defs->DISABLE_SPECIES_DROPDOWN;

  if (my ($info_tab) = grep {($_->{'type'} || '') eq 'Info'} @{$self->entries}) {
    $info_tab->{'dropdown'} = undef;
  }
}
##

## EG use simple alphabetical list
sub species_list {
  my $self      = shift;

  my $html;
  foreach my $sp (@{$self->{'species_list'}}) {
    $html .= qq{<li><a class="constant" href="$sp->[0]">$sp->[1]</a></li>};
  }
  
  return qq{<div class="dropdown species"><h4>Select a species</h4><ul>$html</ul></div>};
}
##

1;
