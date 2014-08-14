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

package EnsEMBL::Web::Component::Location::ViewBottom;

use strict;

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $threshold   = 1000100 * ($hub->species_defs->ENSEMBL_GENOME_SIZE || 1);
  my $image_width = $self->image_width;
  
  return $self->_warning('Region too large', '<p>The region selected is too large to display in this view - use the navigation above to zoom in...</p>') if $object->length > $threshold;
  
  my $slice        = $object->slice;
  my $image_config = $hub->get_imageconfig('contigviewbottom');
  
  ## Force display of individual low-weight markers on pages linked to from Location/Marker
  if (my $marker_id = $hub->param('m')) {
    $image_config->modify_configs(
      [ 'marker' ],
      { marker_id => $marker_id }
    );
  }

  my $length = $slice->end -$slice->start + 1;

## disabled flanking for now
## Todo: apply flanking only if we entered the view restricted to a single gene
  # # adding 10% length at either end of the feature view if REGION_EXTENSION_VIEW is set in MULTI.ini
  # my $k = $hub->species_defs->get_config('MULTI', 'REGION_EXTENSION_VIEW') || '';

  # if (0 && $hub->param('t') && $k && $k < 1) {
  #   my $extension = int (($slice->end - $slice->start) * $k);
  #   my $start = $slice->start - $extension;
  #   my $end = $slice->end + $extension;
  #   $length = $end -$start + 1;
  

  #   $slice = Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->coord_system(),
  #                                       -SEQ_REGION_NAME => $slice->seq_region_name,
  #                                       -SEQ_REGION_LENGTH  => $length,
  #                                       -START              => $start,
  #                                       -END                => $end,
  #                                       -STRAND             => $slice->strand,
  #                                       -ADAPTOR            => $slice->adaptor);
  # }
##

  # Add multicell configuration
  $image_config->set_parameters({
      container_width => $length,
      image_width     => $image_width || 800, # hack at the moment
      slice_number    => '1|3'
  });
  $image_config->{'data_by_cell_line'} = $self->new_object('Slice', $slice, $object->__data)->get_cell_line_data($image_config) if keys %{$hub->species_defs->databases->{'DATABASE_FUNCGEN'}{'tables'}{'cell_type'}{'ids'}};
  $image_config->_update_missing($object);
  
  my $info = $self->_add_object_track($image_config);
  my $image = $self->new_image($slice, $image_config, $object->highlights);

	return if $self->_export_image($image);

  $image->{'panel_number'} = 'bottom';
  $image->imagemap         = 'yes';
  $image->set_button('drag', 'title' => 'Click or drag to centre display');
  return $info . $image->render;
}

1;
