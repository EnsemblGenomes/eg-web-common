package Bio::EnsEMBL::GlyphSet;
use strict;
use warnings;
no warnings "uninitialized";

use URI::Escape qw(uri_escape);

sub init_label {
  my $self = shift;
  
  return $self->label(undef) if defined $self->{'config'}->{'_no_label'};
  
  
  my $config    = $self->{'config'};
  my $hub       = $config->hub;
  my $text = $self->my_config('caption');
  if($hub->species_defs->GENOMIC_UNIT =~ /bacteria/i){
    $text =~ s/^chromosome //; # EB chromosomes don't have names
  }
  return $self->label(undef) unless $text;
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
  (my $class    = $self->species . "_$track") =~ s/\W/_/g;
  
  if ($hover) {
    my $fav       = $config->get_favourite_tracks->{$track};
    my @renderers = @{$node->get('renderers') || []};
    my $subset    = $node->get('subset');
    my @r;
    
    my $url = $hub->url('Config', {
      species  => $config->species,
      action   => $component,
      function => undef,
      submit   => 1,
      __clear  => 1
    });
    
    if (scalar @renderers > 4) {
      while (my ($val, $text) = splice @renderers, 0, 2) {
        push @r, { url => "$url;$track=$val", val => $val, text => $text, current => $val eq $self->{'display'} };
      }
    }
    
    $config->{'hover_labels'}->{$class} = {
      header    => $name,
      desc      => $desc,
      class     => $class,
      component => lc($component . ($config->multi_species && $config->species ne $hub->species ? '_' . $config->species : '')),
      renderers => \@r,
      fav       => [ $fav, "$url;$track=favourite_" ],
      off       => "$url;$track=off",
      conf_url  => $self->species eq $hub->species ? $hub->url($hub->multi_params) . ";$config->{'type'}=$track=$self->{'display'}" : '',
      subset    => $subset ? [ $subset, $hub->url('Config', { species => $config->species, action => $component, function => undef, __clear => 1 }), lc "modal_config_$component" ] : '',
    };
  }
  
  $self->label($self->Text({
    text      => $text,
    font      => $font,
    ptsize    => $fsze,
    colour    => $self->{'label_colour'} || 'black',
    absolutey => 1,
    height    => $res[3],
    class     => "label $class",
    alt       => $name,
    hover     => $hover
  }));
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

