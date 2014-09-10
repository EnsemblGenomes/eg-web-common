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
    
    $s = 1  if $s < 1;
    $s = $e if $s > $e;
  }
##                                            
  
  return $object->seq_region_name . ":$s-$e" if $self->{'update'};
  
  return $hub->url({ 
    %{$hub->multi_params(0)},
    r => $object->seq_region_name . ":$s-$e"
  });
}

sub ramp {
  my ($self, $ramp_entries, $wd, @url_params) = @_;

  my $scale = $self->hub->species_defs->ENSEMBL_MAX_ZOOM_OUT_LEVEL || $self->hub->species_defs->ENSEMBL_GENOME_SIZE || 1;
  my $x     = 0;
  my (@ramp, @mp);

  foreach (@$ramp_entries) {
    $_->[1] *= $scale;
    push @mp, sqrt($x * $_->[1]);
    $x = $_->[1];
  }

  push @mp, 1e30;

  my $l = shift @mp;

  my $img_url = $self->img_url;

  foreach (@$ramp_entries) {
    my $r = shift @mp;

    push @ramp, [
      '<a href="%s" name="%d" class="ramp%s" title="%d bp" style="height:%dpx"></a>',
      $self->ramp_url($_->[1], @url_params),
      $_->[1],
      $wd > $l && $wd <= $r ? ' selected' : '',
      $_->[1],
      $_->[0]
    ];

    $l = $r;
  }

  return $self->{'update'} ? \@ramp : join '', map { sprintf shift @$_, @$_ } @ramp;
}

1;
