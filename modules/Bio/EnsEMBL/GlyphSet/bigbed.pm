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

package Bio::EnsEMBL::GlyphSet::bigbed;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Bio::EnsEMBL::GlyphSet::_alignment Bio::EnsEMBL::GlyphSet_wiggle_and_block);

sub features {
  my ($self, $options) = @_;

  my %config_in = map { $_ => $self->my_config($_) } qw(colouredscore style);
  $options = { %config_in, %{$options || {}} };

  my $bba = $options->{'adaptor'} || $self->bigbed_adaptor;

  my $format = $self->format;

  my $slice = $self->{'container'};
  $self->{'_default_colour'} = $self->SUPER::my_colour($self->my_config('sub_type'));
  my $features = $bba->fetch_features($slice->seq_region_name,$slice->start,$slice->end);

  # unless region name exists, check synonyms
  if ( !@$features ){
    my $synonym_obj = $slice->get_all_synonyms(); # arrayref of Bio::EnsEMBL::SeqRegionSynonym objects
    foreach my $synonym (@$synonym_obj) {
      $features =  $bba->fetch_features($synonym->name, $slice->start, $slice->end);
      last if (ref $features eq 'ARRAY' && @$features > 0);
    }
  }

  $_->map($slice) for @$features;
  my $config = {};

  # WORK OUT HOW TO CONFIGURE FEATURES FOR RENDERING
  # Explicit: Check if mode is specified on trackline
  my $style = $options->{'style'} || $format->style;

  if($style eq 'score') {
    $config->{'useScore'} = 1;
    $config->{'implicit_colour'} = 1;
  } elsif($style eq 'colouredscore') {
    $config->{'useScore'} = 2;    
  } elsif($style eq 'colour') {
    $config->{'useScore'} = 2;
    my $default_rgb_string = $self->my_config('colour') || '0,0,0';
    if($options->{'fallbackcolour'}) {
      my $colour = $options->{'fallbackcolour'};
      $colour = $self->{'_default_colour'} if($colour eq 'default');
      my ($r, $g, $b) =  $self->{'config'}->colourmap->rgb_by_name($colour,1);
      $default_rgb_string = "$r,$g,$b";
    }
    foreach (@$features) {
      next if (defined $_->external_data->{'item_colour'} && $_->external_data->{'item_colour'}[0] =~ /^\d+,\d+,\d+$/);
      $_->external_data->{'item_colour'}[0] = $default_rgb_string;
    }
    $config->{'itemRgb'} = 'on';    
  }

  my $trackline = $format->parse_trackline($format->trackline);
  $config = { %$config, %$trackline };

  return( 
    'url' => [ $features, $config ],
  );
}
 
1;

