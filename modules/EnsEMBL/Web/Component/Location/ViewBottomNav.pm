# $Id: ViewBottomNav.pm,v 1.5 2013-07-04 13:53:42 jk10 Exp $

package EnsEMBL::Web::Component::Location::ViewBottomNav;

sub content {
  my $self             = shift;
  my $ramp_entries     = shift || [ [4,1e3], [6,5e3], [8,1e4], [10,5e4], [12,1e5], [14,2e5], [16,5e5], [18,1e6] ];
  my $hub              = $self->hub;
  my $object           = $self->object;
  my $image_width      = $self->image_width . 'px';
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;
  my $cp               = int(($seq_region_end + $seq_region_start) / 2);
  my $wd               = $seq_region_end - $seq_region_start + 1;
  my $r                = $hub->param('r');
  
  $self->{'update'} = $hub->param('update_panel');
  
## EG
  if($seq_region_start > $seq_region_end) { # circular
    my $seq_region_len = $object->seq_region_length;
    $wd = $seq_region_end + $seq_region_len - $seq_region_start + 1;
    $cp = $seq_region_start + int($wd / 2);
    $cp = $cp - $seq_region_len + 1 if $cp > $seq_region_len;
  }
  
 # EG <</>> buttons shift 2 windows rather than 1e6 

 my $values = [
    $self->ajax_url(shift, { __clear => 1, r => $r }),
    $r,
    $self->nav_url($seq_region_start - 2*$wd, $seq_region_end - 2*$wd),
    $self->nav_url($seq_region_start - $wd, $seq_region_end - $wd),
    $self->nav_url($cp - int($wd/4) + 1, $cp + int($wd/4)), 
    $self->nav_url($cp - $wd + 1, $cp + $wd),
    $self->nav_url($seq_region_start + $wd, $seq_region_end + $wd),
    $self->nav_url($seq_region_start + 2*$wd, $seq_region_end + 2*$wd)
  ];
  
  my $ramp = $self->ramp($ramp_entries, $wd, $cp);
  
  if ($self->{'update'}) {
    my $i = 0;
    my @ramp_values;
    
    foreach (@$ramp) {
      push @ramp_values, $_->[1];
      unshift @$values, $i if $_->[3];
      $i++;
    }
    
    splice @$values, 6, 0, @ramp_values;
    
    return $self->jsonify($values);
  }

  return $self->navbar($ramp, $wd, $values);
}

sub nav_url {
  my ($self, $s, $e) = @_;
  my $hub    = $self->hub;
  my $object = $self->object;
  my $max    = $object->seq_region_length;

## EG    
  if ($object->slice->is_circular) {
  
    my $window_size = ($s <= $e ? $e - $s : $e + $max - $s) + 1; 
    
    if ($window_size >= $max) {
      # window covers whole region
      ($s, $e) = (1, $max);
    } else {
      # wrap start pos
      $s += $max if $s < 0;
      $s -= $max if $s > $max;
      $s  = 1    if $s == 0;
      # wrap end pos
      $e += $max if $e < 0;
      $e -= $max if $e > $max;
      $e  = 1    if $e == 0;
    }
  
  } else {
 
    ($s, $e) = (1, $e - $s || 1) if $s < 1;
    ($s, $e) = ($max - ($e - $s), $max) if $e > $max;
    
    $s = $e if $s > $e;
  }
##                                            
  
  return $object->seq_region_name . ":$s-$e" if $self->{'update'};
  
  return $hub->url({ 
    %{$hub->multi_params(0)},
    r => $object->seq_region_name . ":$s-$e"
  });
}

1;
