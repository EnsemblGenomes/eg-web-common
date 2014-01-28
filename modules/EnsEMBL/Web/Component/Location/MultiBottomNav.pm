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

package EnsEMBL::Web::Component::Location::MultiBottomNav;

sub content {
  my $self = shift;
  my $ramp_entries = shift || [ [4,1e3], [6,5e3], [8,1e4], [10,5e4], [12,1e5], [14,2e5], [16,5e5], [18,1e6] ];
  my $hub          = $self->hub;

  return if $hub->param('show_panels') eq 'top';
  
  my $object = $self->object;
  my $image_width      = $self->image_width . 'px';
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;
  my $seq_region_mid = $object->seq_region_length;

  my $wd;
  if($seq_region_start <= $seq_region_end) {
      $wd = $seq_region_end - $seq_region_start + 1;
  }  else {
      $wd = $seq_region_end + $seq_region_mid - $seq_region_start + 1;
  }

  my $values = [
    $self->ajax_url,
    $hub->param('r'),
    $self->nav_url(-$wd*2),
    $self->nav_url(-$wd),
    $self->nav_url($wd/2, 'resize'),
    $self->nav_url($wd*2, 'resize'),
    $self->nav_url($wd),
    $self->nav_url($wd*2)
  ];

  return $object->param('update_panel') ? $self->jsonify($values) : $self->navbar($self->ramp($ramp_entries, $wd), $wd, $values);
}


1;
