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

# $Id: VariationImageNav.pm,v 1.3 2013-06-11 13:06:19 jk10 Exp $

package EnsEMBL::Web::Component::Gene::VariationImageNav;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Component::Location::ViewBottomNav);


## EG - make the nav work with the gene region 
sub content {
  my ($self,$min,$max) = @_;
  my $hub    = $self->hub;
  my $object = $self->object;

  my $r                = $hub->param('r');
  my $g                = $hub->param('g');
  my ($reg_name, $seq_region_start, $seq_region_end) = $r =~ /(.+?):(\d+)-(\d+)/ if $r =~ /:/;

  my $context      = $object->param( 'context' ) || 100;
  my $extent       = $context eq 'FULL' ? 1000 : $context;

  unless ($object->isa('EnsEMBL::Web::Object::Gene') || $object->isa('EnsEMBL::Web::Object::LRG')){
    $object = $self->hub->core_object('gene');
  }

  $object->get_gene_slices(                                                   
    undef,
    [ 'gene',        'normal', '33%'  ],
    [ 'transcripts', 'munged', $extent ],
  );

  my $start_difference =  $object->__data->{'slices'}{'transcripts'}[1]->start - $object->__data->{'slices'}{'gene'}[1]->start;
  $start_difference = $start_difference > 0 ? $start_difference : $start_difference * -1;

  my $region_start = $object->Obj->start - $start_difference;   #gene start - $start_difference
  my $region_end   = $object->Obj->end   + $start_difference;   #gene end + $start_difference

  my $ramp = $self->ramp($min||1e3,$max||1e6,$region_start, $region_end);
  return $self->navbar($ramp);
}
##

1;
