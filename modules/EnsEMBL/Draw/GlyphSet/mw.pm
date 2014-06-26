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

package EnsEMBL::Draw::GlyphSet::mw;
use strict;

use base qw(EnsEMBL::Draw::GlyphSet);

use Data::Dumper;

sub render_normal {
  my ($self, %options) = @_;
  
  my $t1 = time;

  # show everything by default
  $options{show_reads} = 1 unless defined $options{show_reads}; # show reads by default 
  $options{show_coverage} = 1 unless defined $options{show_coverage}; # show coverage by default 
  #$options{show_consensus} = $options{show_reads} unless defined $options{show_consensus}; # show consensus if showing reads
  $options{show_consensus} = 1 unless defined $options{show_consensus};
  
  # check threshold
  my $slice = $self->{'container'};
  if (my $threshold = $self->my_config('threshold')) {
    if (($threshold * 1000) < $slice->length) {
      $self->errorTrack($self->error_track_name. " is displayed only for regions less then $threshold Kbp (" . $slice->length . ")");
      return;
    }
  }
  
  $self->{_yoffset} = 0; # used to track the y offset as we draw
  
  # wrap the rendering within a timeout alarm
  my $timeout = 30; # seconds
  eval {
    local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
    alarm $timeout;
    # render
    $self->render_wiggle(\%options);
    alarm 0;
  };
  if ($@) {
    die unless $@ eq "alarm\n"; # propagate unexpected errors
    # timed-out
    $self->errorTrack($self->error_track_name . " could not be rendered within the specified time limit (${timeout}sec)");
  }
  warn "Done in ", time -$t1, "s";
}


use Inline C => Config => INC => "-I$SiteDefs::MWIGGLE_DIR/src",
                          LIBS => "-L$SiteDefs::MWIGGLE_DIR/lib -lmw",
                          DIRECTORY => "$SiteDefs::ENSEMBL_WEBROOT/cbuild";

use Inline C => <<'END';

#include "mw.h"

#define REGION_NAME_LEN 32
#define REGION_META_KEY "Regions count"

HV* meta_info(char *fname) {
    HV *meta = (HV*) newHV();
    META *c, *m = mw_stats(fname);
    REGION *r, *regions = mw_regions(fname);
    int rnum = 0;

    int i = 0; 
    if (m) {
	c = m;
	while (i < META_NUM) { 
            if (strcmp(m->k, REGION_META_KEY) == 0) {
               rnum = atoi(m->v);
            }
	    hv_store(meta, m->k, strlen(m->k), newSVpv(m->v,strlen(m->v)), 0);
            m++;
	    i++;
	
	}    
	free(c);
    }
    if (regions) {
	char *str = (char*) malloc (sizeof(char) * REGION_NAME_LEN * rnum  + 1);
        memset(str, 0,   sizeof(char) * REGION_NAME_LEN * rnum  + 1);
	r = regions;
	i = 0;

	while (r->size) {
            strncat(str, " ", 1);
            strncat(str, r->name, strlen(r->name));
	    i++; 
            r = regions + i;
	}
	free(regions);
	hv_store(meta, "Regions", 7, newSVpv(str,strlen(str)), 0);
	free(str);
    }
    return meta;
}

AV* tracks(char *fname) {
  TRACK *tracks = mw_tracks(fname);
  AV* res = (AV*) newAV();
  HV *ht;
  TRACK *t;
  int i = 0; 

  if (tracks) {
      do {
	  t = tracks+i;
	  ht = (HV*) newHV();
	  hv_store(ht, "id", 2, newSViv(t->id), 0);
	  hv_store(ht, "name", 4, newSVpv(t->name, strlen(t->name)), 0);
          hv_store(ht, "strand", 6, newSViv(t->ori), 0);
          hv_store(ht, "min", 3, newSVnv(t->min), 0);
          hv_store(ht, "max", 3, newSVnv(t->max), 0);
          hv_store(ht, "desc", 4, newSVpv(t->desc, strlen(t->desc)), 0);
          av_push(res, newRV((SV*)ht));
          i++;
      } while (t->id < 10000);
      free(tracks);
  }
  return res;
}

AV* get_data(char *fname, char *region, char *tracks, int winsize) {
  int tcount = 0;
  AV* tfeat = (AV*) newAV();

  if (!region) {
    printf("Error: fetch function requires the region parameter, e.g -r I:1-1000\n");
    return tfeat;
  }

  RESULT *res = mw_fetch(fname, region, tracks, winsize, &tcount);

  if (res) {
    int i ;
    RESULT *tr = res;
    while (tcount --) {
	AV* feat = (AV*) newAV();
        for( i = 0; i < winsize; i++) {
	   av_push(feat, newSVnv(tr->v[i]));
        }
        free(tr->v);
        tr++;
        av_push(tfeat, newRV((SV*)feat));
    }
    free(res);
  }
  return tfeat;
}


END

sub features {
  my ($self) = @_;
  
  my $slice = $self->{'container'};
  my $START = $slice->start;
  my $ppbp = $self->scalex;
  my $slength = $slice->length;

  my $pcx = $slength * $ppbp;
  my $bpx = $slength / $pcx;

  my $sample_size  = $slength / $pcx;
  my $lbin = $pcx;

  if ($sample_size < 1) {
    $sample_size = 1;
    $lbin = $slength;
  }

  my $url = $self->my_config('url');
  my $region = sprintf("%s:%d-%d", $slice->seq_region_name, $slice->start, $slice->end);

#  warn "URL : $url \n";
#  warn "region : $region (win $pcx)\n";
  $pcx = $slength  if ($slength < $pcx);
  my $tracks = '';#'0,1';# unless defined $tracks;

  return get_data($url, $region, $tracks, $pcx);
}

sub get_trackinfo {
    my ($self) = @_;

    my $url = $self->my_config('url');

    my $tinfo = {}; 
    foreach (@{tracks($url)||[]}) {
	$tinfo->{ $_->{id} } = $_;
    }
    return $tinfo;
}

sub draw_track_name {
  ### Predicted features
  ### Draws the name of the predicted features track
  ### Arg1: arrayref of Feature objects
  ### Arg2: colour of the track
  ### Returns 1

  my ($self, $name, $colour, $x_offset, $y_offset, $no_offset) = @_; 
  my $x  = $x_offset || 1;  
  my $y  = $self->_offset; 
     $y += $y_offset if $y_offset;
  $colour = 'contigblue2';   
  my %font_details = $self->get_font_details('innertext', 1); 
  my @res_analysis = $self->get_text_width(0, $name, '', %font_details);

  $self->push($self->Text({
    x         => $x,
    y         => $y,
    text      => $name,
    height    => $res_analysis[3],
    width     => $res_analysis[2],
    halign    => 'left',
    valign    => 'bottom',
    colour    => $colour,
    absolutey => 1,
    absolutex => 1,
    'zindex' => 10,
    'title' => "Description is empty",
    %font_details,
  }));

  $self->_offset($res_analysis[3]) unless $no_offset;
  
  return 1;
}

sub draw_axis {
    my ($self, $min, $max, $colour) = @_;

    my $slice           = $self->{'container'};
    my $offset          = $self->_offset;
    my $row_height  = $self->{'height'} || $self->my_config('height') || 50;

    my $pix_per_score   = ($max - $min) ? $row_height / ($max - $min) : 0; 
    my $zero_line_offset = $max * $pix_per_score;    


    my $axis_colour     = $colour  || 'red';
    $self->push($self->Line({ # horizontal line
	'x'         => 0,
	'y'         => $offset + $zero_line_offset,
	'width'     => $slice->length,
	'height'    => 0,
	'absolutey' => 1,
	'colour'    => $axis_colour,
	'dotted'    => 1,
			    }));
    $self->push($self->Line({ # vertical line
	'x'         => 0,
	'y'         => $offset,
	'width'     => 0,
	'height'    => $row_height,
	'absolutey' => 1,
	'absolutex' => 1,
	'colour'    => $axis_colour,
	'dotted'    => 0,
			    }));

    my $display_max_score = sprintf '%.2f', $max;
    my %font            = $self->get_font_details('innertext', 1);
    my @res_i           = $self->get_text_width(0, $display_max_score, '', %font);
    my $textheight_i    = $res_i[3];
    my $pix_per_bp      = $self->scalex;
    $colour = 'black';
    $self->push($self->Text({ 
	'text'          => $display_max_score,
	'width'         => $res_i[2],
	'textwidth'     => $res_i[2],
	'halign'        => 'right',
	'valign'        => 'top',
	'colour'        => $colour,
	'height'        => $textheight_i,
	'y'             => $offset,
	'x'             => -4 - $res_i[2],
	'absolutey'     => 1,
	'absolutex'     => 1,
	'absolutewidth' => 1,
	%font,
			    }));
	      
    if ($min < 0) {
	my $display_min_score = sprintf '%.2f', $min;
	my @res_min           = $self->get_text_width(0, $display_min_score, '', %font);
		  
	$self->push($self->Text({
	    'text'         => $display_min_score,
	    'height'       => $textheight_i,
	    'width'        => $res_min[2],
	    'textwidth'    => $res_min[2],
	    'halign'       => 'right',
	    'valign'       => 'bottom',
	    'colour'       => $colour,
	    'y'            => $offset + $row_height - $textheight_i,
	    'x'            => -4 - $res_min[2],
	    'absolutey'     => 1,
	    'absolutex'     => 1,
	    'absolutewidth' => 1,
	    %font,
				}));
    }
    return $zero_line_offset;
}

sub render_wiggle {
  my ($self, $options) = @_;

# If the track is configured f or r - we display all tracks on the selected strand
# otherwise each track is displayed on its strand

  my $strand  = $self->strand();
  my $strand_flag   = $self->my_config('strand');  
  return if ( $strand_flag eq 'f' && $strand != 1 ) || ( $strand_flag eq 'r'  && $strand == 1 );
  my $default_colour = 'darkseagreen';

  if (my @values  = @{$self->features}) {
      my $row_height  = $self->{'height'} || $self->my_config('height') || 50;
      my $slice           = $self->{'container'};
      my $smax = 100;
      my $scale = 3;
      my $ppbp = $self->scalex;


      my $tracks = $self->get_trackinfo();

      my @tcolour = @{$self->my_config('track_colour') || []};

      my $i = 0;
      my $colours = ['pink', 'blue', 'blue', 'green'];
      foreach my $track (@values) {
	  my $tstrand = $tracks->{$i}->{strand} || -1;
	  $tstrand = 1 if ($tstrand > 1);

	  if ($strand_flag eq 'b') {	      
	      if ($tstrand != $strand) {
		  $i++;
		  next;
	      }
	  }

	  my $max = (sort {$b <=> $a} @$track)[0];
	  my $min = (sort {$b <=> $a} @$track)[-1];
#	  warn sprintf("Range : %.3f.. %.3f\n", $min, $max);

	  my $label           = $tracks->{$i}->{'desc'} || $tracks->{$i}->{'name'} || $options->{'description'}   || "My Track $i";
#	  my $colour          = $options->{'score_colour'}  || $self->my_colour('score') || 'blue';
	  my $axis_colour     = $options->{'axis_colour'}   || $self->my_colour('axis')  || 'red';
	  $axis_colour = 'lightblue';


#	  $self->draw_track_name($label, $colour, 10, 10);	  

	  $max = 0 if ($max < 0);
	  $min = 0 if ($min > 0);
	  
	  my $zero = $self->draw_axis($min, $max, $axis_colour);

	  my $offset          = $self->_offset;

	  my $colour = $tcolour[$i] || $self->my_config('score_colour') || $default_colour;

	  my $j = 0;
	  my $range = abs($max - $min);
	  foreach my $cvrg (@$track) {
	      if( my $title = $cvrg ) {
		  my $y = $cvrg > 0 ? int(($max - $cvrg) * $row_height / $range + 0.4) : $zero;
		  my $h1 = int (abs($cvrg) * $row_height / $range + 0.4);
		  
		  $self->push($self->Rect({
		      'x'      => $j,
		      'y'      => $offset + $y,
		      'width'  => 0.97,
		      'height' => $h1, 
		      'colour' => $colour,
		      'absolutex' => $ppbp < 1 ? 1 : 0,
		      'title' => $title,
'zindex' => -10,
					  }));

	      }
	      $j++;
	  }
	  $self->draw_track_name($label, $colour, 10, 0);	  
	  $i++;
	  $offset = $self->_offset($row_height);
      }
 # Draw the labels ----------------------------------------------
  ## Only done if we have multiple data sets
  } else {
      $self->no_features unless @values;
  }

}

sub _offset {
  ### Arg1 : (optional) number to add to offset
  ### Description: Getter/setter for offset
  ### Returns : integer

  my ($self, $offset) = @_;
  $self->{'offset'} += $offset if $offset;
  return $self->{'offset'} || 0;
}

1;
