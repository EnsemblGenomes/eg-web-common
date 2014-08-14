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

# $Id: VariationImageTop.pm,v 1.1 2012-07-30 13:24:52 it2 Exp $

package EnsEMBL::Web::Component::Gene::VariationImageTop;

use strict;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
  $self->has_image(1);
}

sub caption {
  return undef;
}

sub _content {
  my $self    = shift;
  my $no_snps = shift;
  my $ic_type = shift || 'gene_variation'; 
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $image_width  = $self->image_width || 800;  
  my $context      = $object->param( 'context' ) || 100; 
  my $extent       = $context eq 'FULL' ? 1000 : $context;
  my $hub          = $self->hub;
  my $config_type;

  if ($object->isa('EnsEMBL::Web::Object::Gene') || $object->isa('EnsEMBL::Web::Object::LRG')){
    $config_type = 'gene_variation';
  } else {
    $object = $self->hub->core_object('gene');
    $config_type = $ic_type;
  }

  my $config = $hub->get_imageconfig($config_type, 'gene_top');
  $config->set_parameters({ 'image_width' => $image_width, 'context' => $context, 'slice_number' => '1|1' });
  
  $object->get_gene_slices( ## Written...
    $config,
    [ 'gene',        'normal', '33%'  ],
    [ 'transcripts', 'munged', $extent ]
  );

  my $transcript_slice = $object->__data->{'slices'}{'transcripts'}[1]; 
  my $sub_slices       = $object->__data->{'slices'}{'transcripts'}[2];  

  # Fake SNPs -----------------------------------------------------------
  # Grab the SNPs and map them to subslice co-ordinate
  # $snps contains an array of array each sub-array contains [fake_start, fake_end, B:E:Variation object] # Stores in $object->__data->{'SNPS'}
  my ($count_snps, $snps, $context_count) = $object->getVariationsOnSlice( $transcript_slice, $sub_slices );  
  my $start_difference =  $object->__data->{'slices'}{'transcripts'}[1]->start - $object->__data->{'slices'}{'gene'}[1]->start;

  my @fake_filtered_snps;
  map { push @fake_filtered_snps,
     [ $_->[2]->start + $start_difference,
       $_->[2]->end   + $start_difference,
       $_->[2]] } @$snps;

  $config->{'filtered_fake_snps'} = \@fake_filtered_snps unless $no_snps;

  ## -- Render image ------------------------------------------------------ ##
  my $image = $self->new_image($object->__data->{'slices'}{'gene'}[1], $config);

  return if $self->_export_image($image, 'no_text');

  $image->imagemap = 'yes';
  $image->{'panel_number'} = 'top';
  $image->set_button('drag', 'title' => 'Click or drag to centre display');

  my $html = $image->render; 
  if ($no_snps){
    $html .= '';
    return $html;
  }

  return $html;
}


sub content {
  return $_[0]->_content(0);
}

1;

