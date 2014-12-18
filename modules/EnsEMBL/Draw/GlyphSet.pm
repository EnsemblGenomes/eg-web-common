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

package EnsEMBL::Draw::GlyphSet;
use strict;
use warnings;
no warnings "uninitialized";

use URI::Escape qw(uri_escape);

sub init_label {
  my $self = shift;
  
  return $self->label(undef) if defined $self->{'config'}->{'_no_label'};
  
  my $text = $self->my_config('caption');
## EG  
  if($SiteDefs::ENSEMBL_SITETYPE =~ /bacteria/i){
    $text =~ s/^chromosome //; # EB chromosomes don't have names
  }
##

  my $img = $self->my_config('caption_img');
  $img = undef if $SiteDefs::ENSEMBL_NO_LEGEND_IMAGES;
  if($img and $img =~ s/^r:// and $self->{'strand'} ==  1) { $img = undef; }
  if($img and $img =~ s/^f:// and $self->{'strand'} == -1) { $img = undef; }

  return $self->label(undef) unless $text;
  
  my $config    = $self->{'config'};
  my $hub       = $config->hub;
  my $name      = $self->my_config('name');
  my $desc      = $self->my_config('description');
  my $style     = $config->species_defs->ENSEMBL_STYLE;
  my $font      = $style->{'GRAPHIC_FONT'};
  my $fsze      = $style->{'GRAPHIC_FONTSIZE'} * $style->{'GRAPHIC_LABEL'};
  my @res       = $self->get_text_width(0, $text, '', font => $font, ptsize => $fsze);
  my $track     = $self->type;
  my $node      = $config->get_node($track);
  my $component = $config->get_parameter('component');
  my $hover     = $component && !$hub->param('export') && $node->get('menu') ne 'no';
  my $class     = random_string(8);

  if ($hover) {
    my $fav       = $config->get_favourite_tracks->{$track};
    my @renderers = grep !/default/i, @{$node->get('renderers') || []};
    my $subset    = $node->get('subset');
    my @r;
    
    my $url = $hub->url('Config', {
      species  => $config->species,
      action   => $component,
      function => undef,
      submit   => 1
    });
    
    if (scalar @renderers > 4) {
      while (my ($val, $text) = splice @renderers, 0, 2) {
        push @r, { url => "$url;$track=$val", val => $val, text => $text, current => $val eq $self->{'display'} };
      }
    }
    
    $config->{'hover_labels'}->{$class} = {
      header    => $name,
      desc      => $desc,
      class     => "$class $track",
      component => lc($component . ($config->multi_species && $config->species ne $hub->species ? '_' . $config->species : '')),
      renderers => \@r,
      fav       => [ $fav, "$url;$track=favourite_" ],
      off       => "$url;$track=off",
      conf_url  => $self->species eq $hub->species ? $hub->url($hub->multi_params) . ";$config->{'type'}=$track=$self->{'display'}" : '',
      subset    => $subset ? [ $subset, $hub->url('Config', { species => $config->species, action => $component, function => undef, __clear => 1 }), lc "modal_config_$component" ] : '',
    };
  }
 
  my $ch = $self->my_config('caption_height') || 0;
  $self->label($self->Text({
    text      => $text,
    font      => $font,
    ptsize    => $fsze,
    colour    => $self->{'label_colour'} || 'black',
    absolutey => 1,
    height    => $ch || $res[3],
    class     => "label $class",
    alt       => $name,
    hover     => $hover,
  }));
  if($img) {
    $img =~ s/^([\d@-]+)://; my $size = $1 || 16;
    my $offset = 0;
    $offset = $1 if $size =~ s/@(-?\d+)$//;
    $self->label_img($self->Sprite({
        z             => 1000,
        x             => 0,
        y             => $offset,
        sprite        => $img,
        spritelib     => 'species',
        width         => $size,
        height         => $size,
        absolutex     => 1,
        absolutey     => 1,
        absolutewidth => 1,
        pixperbp      => 1,
        alt           => '',
    }));
  }
}

### Circular
sub bump_row {
  my ($self, $start, $end, $truncate_if_outside, $key) = @_;
  
  $key ||= '_bump';

  ($end, $start) = ($start, $end) if $end < $start;

  $start = 1 if $start < 1;
  
  return -1 if $end > $self->{$key}{'length'} && $truncate_if_outside; # used to not display partial text labels
  
  $end = $self->{$key}{'length'} if $end > $self->{$key}{'length'};

  $start = floor($start);
  $end   = ceil($end);
  
  #the following line is added for the purposes of CircularSlice presentation                                                                                                               
  #otherwise an error is generated                                                                                                                                                                         
  ($end, $start) = ($start, $end) if $end < $start;

  my $length  = $end - $start + 1;
  my $element = '0' x $self->{$key}{'length'};
  my $row     = 0;

  substr($element, $start, $length) = '1' x $length;
  
  while ($row < $self->{$key}{'rows'}) {
    unless ($self->{$key}{'array'}[$row]) { # We have no entries in this row - so create a new row
      $self->{$key}{'array'}[$row] = $element;
      return $row;
    }
    if (($self->{$key}{'array'}[$row] & $element) == 0) { # We already have a row, but the element fits so include it
      $self->{$key}{'array'}[$row] |= $element;
      return $row;
    }
    $row++; # Can't fit in on this row go to the next row..
  }
  
  return 1e9; # If we get to this point we can't draw the feature so return a very large number!
}


1;

