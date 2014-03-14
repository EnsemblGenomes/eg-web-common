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

# $Id: VariationImageNav.pm,v 1.3 2013-06-11 13:06:19 jk10 Exp $

package EnsEMBL::Web::Component::Gene::VariationImageNav;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1); # Must be ajaxable for slider/button nav stuff to work properly.
}

sub content_region {
  return shift->content([ [4,1e4], [6,5e4], [8,1e5], [10,5e5], [12,1e6], [14,2e6], [16,5e6], [18,1e7] ], 'region')
}

sub content {
  my $self             = shift;
  my $ramp_entries     = shift || [ [4,1e3], [6,5e3], [8,1e4], [10,5e4], [12,1e5], [14,2e5], [16,5e5], [18,1e6] ];
  my $hub              = $self->hub;
  my $object           = $self->object;
  my $image_width      = $self->image_width . 'px';
  my $r                = $hub->param('r');
  my $g                = $hub->param('g');
  my ($reg_name, $seq_region_start, $seq_region_end) = $r =~ /(.+?):(\d+)-(\d+)/ if $r =~ /:/;

  my $context      = $object->param( 'context' ) || 100;
  my $extent       = $context eq 'FULL' ? 1000 : $context;

  $object->get_gene_slices(                                                   
    undef,
    [ 'gene',        'normal', '33%'  ],
    [ 'transcripts', 'munged', $extent ],
			    );

  my $start_difference =  $object->__data->{'slices'}{'transcripts'}[1]->start - $object->__data->{'slices'}{'gene'}[1]->start;
  $start_difference = $start_difference > 0 ? $start_difference : $start_difference * -1;

  my $region_start = $object->Obj->start - $start_difference;   #gene start - $start_difference
  my $region_end   = $object->Obj->end   + $start_difference;   #gene end + $start_difference

  my $gene_length = (($region_end - $region_start) > 0) ? ($region_end - $region_start) : ($region_start - $region_end);
  my $index = 7;
  my $un1 = 18;
  my $un2 = $gene_length;
  my $scale = $self->hub->species_defs->ENSEMBL_GENOME_SIZE || 1;  
  while ($index >= 0) {
    $ramp_entries->[$index] = [$un1, int($un2/$scale)];  
    $un2 = int($un2/2);
    $un1 -= 2;
    $index--;
  }

  my $lim = $gene_length;
  my $add = 1;
  while ($lim >= 10) {
    $lim = int($lim/10);
    $add *= 10;
  }
  $add = 1e3 if ($add <= 1);
 
  my $cp               = int(($seq_region_end + $seq_region_start) / 2);
  my $wd               = $seq_region_end - $seq_region_start + 1;

  $self->{'update'} = $hub->param('update_panel');

  my $values = [
    $self->ajax_url(shift, {__clear=>1,r=>$r,g=>$g}),
    $r,
    $self->nav_url($seq_region_start - $add, $seq_region_end - $add),
    $self->nav_url($seq_region_start - $wd, $seq_region_end - $wd),
    $self->nav_url($cp - int($wd/4) + 1, $cp + int($wd/4)),
    $self->nav_url($cp - $wd + 1, $cp + $wd),
    $self->nav_url($seq_region_start + $wd, $seq_region_end + $wd),
    $self->nav_url($seq_region_start + $add, $seq_region_end + $add)
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

sub navbar {
  my ($self, $ramp, $wd, $values) = @_;
  
  my $hub          = $self->hub;
  my $img_url      = $self->img_url;
  my $image_width  = $self->image_width . 'px';
  my $url          = $hub->url({ %{$hub->multi_params(0)}, r => undef, g => undef }, 1);
  my $psychic      = $hub->url({ type => 'psychic', action => 'Gene', __clear => 1 });
  my $extra_inputs = join '', map { sprintf '<input type="hidden" name="%s" value="%s" />', encode_entities($_), encode_entities($url->[1]->{$_}) } keys %{$url->[1] || {}};
  my $g            = $hub->param('g');
  my $g_input      = $g ? qq{<input name="g" value="$g" type="hidden" />} : '';
  my $rbcp         = $hub->param('r');

  return sprintf (qq{
    <div class="navbar print_hide" style="width:$image_width">
      <input type="hidden" class="panel_type" value="LocationNav" />
      <input type="hidden" class="update_url" value="%s" />
      <div class="relocate">
        <form action="$url->[0]" method="get">    
          <label for="loc_r">Location:</label>
          $extra_inputs
          $g_input
          <input type="hidden" name="mod" value="GeneSNPImageNav_L" />
          <input type="hidden" name="rbcp" value="$rbcp" />
          <input name="r" id="loc_r" class="location_selector" style="width:250px" value="%s" type="text" />
          <a class="go-button" href="">Go</a>
        </form>
        <div class="js_panel" style="float: left; margin: 0;">
          <input type="hidden" class="panel_type" value="AutoComplete" />
          <form action="$psychic" method="get">
            <label for="loc_q" style="margin-left: 5px; width: 80px;">Variation ID:</label>
            $extra_inputs
            <input name="q" id="loc_q" style="width:200px" value="" type="text" />
            $g_input
            <input type="hidden" name="mod" value="GeneSNPImageNav" />
            <a class="go-button" href="">Go</a>
          </form>
        </div>
      </div>
      <div class="image_nav">
        <a href="%s" class="move left_2" title="Back 2 windows"></a>
        <a href="%s" class="move left_1" title="Back 1 window"></a>
        <a href="%s" class="zoom_in" title="Zoom in"></a>
        <span class="ramp">$ramp</span>
        <span class="slider_wrapper">
          <span class="slider_left"></span>
          <span class="slider"><span class="slider_label floating_popup">$wd</span></span>
          <span class="slider_right"></span>
        </span>
        <a href="%s" class="zoom_out" title="Zoom out"></a>
        <a href="%s" class="move right_1" title="Forward 1 window"></a>
        <a href="%s" class="move right_2" title="Forward 2 windows"></a>
      </div>
      <div class="invisible"></div>
    </div>},
    @$values
  );
}

sub ramp {
  my ($self, $ramp_entries, $wd, @url_params) = @_;
  
  my $scale = $self->hub->species_defs->ENSEMBL_GENOME_SIZE || 1;
  my $x     = 0;
  my (@ramp, @mp);
  
  foreach (@$ramp_entries) {
    $_->[1] *= $scale;
    push @mp, sqrt($x * $_->[1]);
    $x = $_->[1];
  }
  
  push @mp, 1e30;
  
  my $l = shift @mp;
 
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

sub ramp_url {
  my ($self, $entry, $cp) = @_;
  return $self->nav_url($cp - int($entry/2) + 1, $cp + int($entry/2));
}

sub nav_url {
  my ($self, $s, $e) = @_;

  my $hub    = $self->hub;
  my $object = $self->object;

  my $start_difference =  $object->__data->{'slices'}{'transcripts'}[1]->start - $object->__data->{'slices'}{'gene'}[1]->start;
  $start_difference = $start_difference > 0 ? $start_difference : $start_difference * -1;

  my $min    = $object->Obj->start - $start_difference;
  my $max    = $object->Obj->end   + $start_difference;  

  #warn "BEFORE $s, $e";
  ($s, $e) = (1, $e - $s || 1) if $s < 1;
  ($s, $e) = ($max - ($e - $s), $max) if $e > $max;
 
  ($s, $e) = ($min, $min + ($e - $s)) if $s < $min;
  $e       =  $max if $e > $max;

  $s = $e if $s > $e;
  #warn "AFTER $s, $e\n\n";
  return $object->seq_region_name . ":$s-$e" if $self->{'update'};
  
  return $hub->url({ 
    %{$hub->multi_params(0)},
    r => $object->seq_region_name . ":$s-$e"
  });
}

1;
