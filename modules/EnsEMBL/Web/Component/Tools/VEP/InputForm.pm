=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::VEP::InputForm;

use strict;
use warnings;

use List::Util qw(first);

use EnsEMBL::Web::VEPConstants qw(INPUT_FORMATS CONFIG_SECTIONS);

use parent qw(
  EnsEMBL::Web::Component::Tools::VEP
  EnsEMBL::Web::Component::Tools::InputForm
);


sub get_cacheable_form_node {


  ## Abstract method implementation
  my $self            = shift;
  my $hub             = $self->hub;
  my $object          = $self->object;
  my $sd              = $hub->species_defs;
  my $species         = $object->species_list;
  my $form            = $self->new_tool_form;
  my $fd              = $object->get_form_details;
  my $input_formats   = INPUT_FORMATS;


 my $input_fieldset = $form->add_fieldset({'class' => @$species <= 100 ? '' : 'long_species_fieldset' , 'no_required_notes' => 1});

  

  #####EG Start - Adding AJAX type species selector to VEP form#######

  # Species dropdown list with stt classes to dynamically toggle other fields
  if ( @$species <= 100 ) {
    $input_fieldset->add_field({
      'label'         => 'Species',
      'elements'      => [{
        'type'          => 'speciesdropdown',
        'name'          => 'species',
        'values'        => [ map {
          'value'         => $_->{'value'},
          'caption'       => $_->{'caption'},
          'class'         => [  #selectToToggle classes for JavaScript
            '_stt', '_sttmulti',
            $_->{'variation'}             ? '_stt__var'   : '_stt__novar',
            $_->{'refseq'}                ? '_stt__rfq'   : (),
            $_->{'variation'}{'POLYPHEN'} ? '_stt__pphn'  : (),
            $_->{'variation'}{'SIFT'}     ? '_stt__sift'  : ()
          ]
        }, @$species ]
      }, {
        'type'          => 'noedit',
        'value'         => 'Assembly: '. join('', map { sprintf '<span class="_stt_%s _vep_assembly" rel="%s">%s</span>', $_->{'value'}, $_->{'assembly'}, $_->{'assembly'} } @$species),
        'no_input'      => 1,
        'is_html'       => 1
      }]
    });
  }
  else {
    $input_fieldset->add_field({
      'label' => 'Species',
      'field_class' => 'long_species_field',
       'elements' => [{
         'type'   => 'DropDown',
         'class'  => 'ajax-species-selector',
         'name'   => 'species',
         'values' => [{
           'value' => $hub->data_species,
           'caption' => $hub->data_species =~ /^Multi$/ ? 'Select a species' : $hub->species_defs->species_display_label($hub->data_species)
          }]
        }]
    });
  }
  
 #####EG End#####


 

  $input_fieldset->add_field({
    'type'          => 'string',
    'name'          => 'name',
    'label'         => 'Name for this data (optional)'
  });

  
  $input_fieldset->add_field({
    'label'         => 'Either paste data',
    'elements'      => [{
      'type'          => 'text',
      'name'          => 'text',
    }, {
      'type'          => 'noedit',
      'noinput'       => 1,
      'is_html'       => 1,
      'caption'       => sprintf('<span class="small"><b>Examples:&nbsp;</b>%s</span>',
        join(', ', map { sprintf('<a href="#" class="_example_input" rel="%s">%s</a>', $_->{'value'}, $_->{'caption'}) } @$input_formats)
      )
    }, {
      'type'          => 'button',
      'name'          => 'preview',
      'class'         => 'hidden',
      'value'         => 'Instant results for first variant &rsaquo;',
      'helptip'       => 'See a quick preview of results for data pasted above',
    }]
  });


  $input_fieldset->add_field({
    'type'          => 'file',
    'name'          => 'file',
    'label'         => 'Or upload file',
    'helptip'       => sprintf('File uploads are limited to %sMB in size. Files may be compressed using gzip or zip', $sd->ENSEMBL_TOOLS_CGI_POST_MAX->{'VEP'} / (1024 * 1024))
  });

  $input_fieldset->add_field({
    'type'          => 'url',
    'name'          => 'url',
    'label'         => 'Or provide file URL',
    'size'          => 30,
    'class'         => 'url'
  });

  # This field is shown only for the species having refseq data
  if (first { $_->{'refseq'} } @$species) {
    $input_fieldset->add_field({
      'field_class'   => '_stt_rfq',
      'type'          => 'radiolist',
      'name'          => 'core_type',
      'label'         => $fd->{core_type}->{label},
      'helptip'       => $fd->{core_type}->{helptip},
      'value'         => 'core',
      'class'         => '_stt',
      'values'        => $fd->{core_type}->{values}
    });
    
    $input_fieldset->add_field({
      'field_class'   => '_stt_rfq _stt_merged _stt_refseq',
      'type'    => 'checkbox',
      'name'    => "all_refseq",
      'label'   => $fd->{all_refseq}->{label},
      'helptip' => $fd->{all_refseq}->{helptip},
      'value'   => 'yes',
      'checked' => 0
    });
  }

  ## Output options header
  $form->add_fieldset({'no_required_notes' => 1});

  ### Advanced config options
  my $sections = CONFIG_SECTIONS;
  foreach my $section (@$sections) {

    $self->togglable_fieldsets($form, {
      'title' => $section->{'title'},
      'desc'  => $section->{'caption'}
    }, $self->can('_build_'.$section->{'id'})->($self, $form));
  }

  # Run/Close buttons
  $self->add_buttons_fieldset($form, {'reset' => 'Clear', 'cancel' => 'Close form'});

  return $form;

}


1;
