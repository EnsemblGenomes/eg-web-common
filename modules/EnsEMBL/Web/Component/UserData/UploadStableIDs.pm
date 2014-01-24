package EnsEMBL::Web::Component::UserData::UploadStableIDs;

use strict;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $hub->data_species;
  my $id_limit     = 30;
  my $form         = $self->modal_form('select', $hub->url({ action => 'CheckConvert', __clear => 1 }));
  
  $form->add_notes({
    heading => 'IMPORTANT NOTE:', 
    text    => qq{
      <p>Please note that we limit the number of ID's processed to $id_limit. If the uploaded file contains more entries than this only the first $id_limit will be mapped.</p>
      <p>If you would like to convert more IDs, please use our <a href="http://cvs.sanger.ac.uk/cgi-bin/viewvc.cgi/ensembl-tools/scripts/id_history_converter/?root=ensembl">api script</a>.</p>
    }
  });

## EG - use species selector instead of simple dropdown
   my @species = sort { $a->{'name'} cmp $b->{'name'} } map { value => $_, name => $species_defs->species_label($_, 1) }, $species_defs->valid_species;
   my $select = $form->add_element(
    'type'    => 'DropDown',
    'name'    => 'species',
    'label'   => "Species",
    'values'  => @species <= 100 ? \@species : [{ value => $species, caption => $hub->species_defs->species_display_label($species) }],
    'value'   => $species,
    'select'  => 'select',
    'class'   => @species <= 100 ? 'species-selector' : 'ajax-species-selector',
  );
  $select->set_attribute('class', $select->get_attribute('class') . ' species-selector');
##

  $form->add_element(type => 'Hidden', name => 'id_mapper',     value => 1);
  $form->add_element(type => 'Hidden', name => 'id_limit',      value => $id_limit);
  $form->add_element(type => 'Hidden', name => 'filetype',      value => 'ID History Converter');
  $form->add_element(type => 'Hidden', name => 'nonpositional', value => 1);
  $form->add_element(type => 'SubHeader',                       value => 'Upload file');
  $form->add_element(type => 'String', name => 'name', label => 'Name for this data (optional)');
  $form->add_element(type => 'Text',   name => 'text', label => 'Paste data');
  $form->add_element(type => 'File',   name => 'file', label => 'Upload file');
  $form->add_element(type => 'URL',    name => 'url',  label => 'or provide file URL', size => 30);
 
  return $form->render;
}


1;
