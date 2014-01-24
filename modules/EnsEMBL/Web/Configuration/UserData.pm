package EnsEMBL::Web::Configuration::UserData;

use strict;

sub modify_tree {
  my $self = shift;

  my $convert_menu = $self->get_node( 'Conversion' );
  ## Slice file attachment
 $convert_menu->append(
  $self->create_node( 'SelectSlice', "Data Slicer",
   [qw(select_vcf EnsEMBL::Web::Component::UserData::SelectSlice)],
    { 'availability' => 1 }
  ));

 $convert_menu->append(
  $self->create_node( 'SliceFile', '',
    [], { 'command' => 'EnsEMBL::Web::Command::UserData::SliceFile',
    'availability' => 1, 'no_menu_entry' => 1 }
  ));

 $convert_menu->append(
  $self->create_node( 'SliceFeedback', '',
   [qw(vcf_feedback EnsEMBL::Web::Component::UserData::SliceFeedback)],
    { 'availability' => 1, 'no_menu_entry' => 1 }
  ));

}


1;
