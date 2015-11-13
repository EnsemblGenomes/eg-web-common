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

package EnsEMBL::Draw::GlyphSet::bigbed;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Draw::GlyphSet::_alignment EnsEMBL::Draw::GlyphSet_wiggle_and_block);

sub features {
  my ($self, $options) = @_;
  my %config_in = map { $_ => $self->my_config($_) } qw(colouredscore style);
  
  $options = { %config_in, %{$options || {}} };

  my $bba       = $options->{'adaptor'} || $self->bigbed_adaptor;
  return [] unless $bba;
  my $format    = $self->format;
  my $slice     = $self->{'container'};
  my $raw_feats = $bba->fetch_features($slice->seq_region_name, $slice->start, $slice->end + 1);

## EG
  unless (@$raw_feats) {
    foreach my $synonym (@{ $slice->get_all_synonyms }) {
      $raw_feats = $bba->fetch_features($synonym->name, $slice->start, $slice->end + 1);
      last if @$raw_feats;
    }
  }
##

  my $config    = {};
  my $max_score = 0;
  my $key       = $self->my_config('description') =~ /external webserver/ ? 'url' : 'feature';
  
  $self->{'_default_colour'} = $self->SUPER::my_colour($self->my_config('sub_type'));
  
  my $features = [];
  foreach (@$raw_feats) {
    my $bed = EnsEMBL::Web::Text::Feature::BED->new(@$_);
    $bed->coords([$_[0],$_[1],$_[2]]);
    ## Set score to undef if missing, to distinguish it from a genuine present but zero score
    $bed->score(undef) if @_ < 5;
    $bed->map($slice);
    $max_score = max($max_score, $bed->score);
    push @$features, $bed;
  }
  
  # WORK OUT HOW TO CONFIGURE FEATURES FOR RENDERING
  # Explicit: Check if mode is specified on trackline
  my $style = $options->{'style'} || $format->style;

  $config->{'simpleblock_optimise'} = 1; # No joins, etc, no need for composite.

  if ($style eq 'score' && !$self->my_config('colour')) {
    $config->{'useScore'}        = 1;
    $config->{'implicit_colour'} = 1;
    $config->{'greyscale_max'}   = $max_score;
  } elsif ($style eq 'colouredscore') {
    $config->{'useScore'} = 2;    
  } else {
    $config->{'useScore'} = 2;
    
    my $default_rgb_string;
    
    if ($options->{'fallbackcolour'}) {
      $default_rgb_string = join ',', $self->{'config'}->colourmap->rgb_by_name($options->{'fallbackcolour'} eq 'default' ? $self->{'_default_colour'} : $options->{'fallbackcolour'}, 1);
    } else {
      $default_rgb_string = $self->my_config('colour') || '0,0,0';
    }
   
    foreach (@$features) {
      if ($_->external_data->{'BlockCount'}) {
        $self->{'my_config'}->set('has_blocks', 1);
      }
      my $colour = $_->external_data->{'item_colour'};
      next if defined $colour && $colour->[0] =~ /^\d+,\d+,\d+$/;
      $_->external_data->{'item_colour'}[0] = $default_rgb_string;
    }
    
    $config->{'itemRgb'} = 'on';    
  }
  
  return ($key => [ $features, { %$config, %{$format->parse_trackline($format->trackline)} } ]);
}

sub wiggle_features {
  my ($self,$bins) = @_;

  return $self->{'_cache'}->{'wiggle_features'} if exists $self->{'_cache'}->{'wiggle_features'};
 
  my $slice = $self->{'container'}; 
  my $adaptor = $self->bigbed_adaptor;
  return [] unless $adaptor;
  my $features = $adaptor->fetch_features($slice->seq_region_name, $slice->start, $slice->end);

## EG
  unless (@$features) {
    foreach my $synonym (@{ $slice->get_all_synonyms }) {
      $features = $adaptor->fetch_features($synonym->name, $slice->start, $slice->end);
      last if @$raw_feats;
    }
  }
##

  $_->map($slice) for @$features;

  my $flip = ($slice->strand == -1) ? ($slice->length + 1) : undef;
  my @block_features;

  for(my $i=0; $i<scalar(@$features); $i++) {
    my $f = $features->[$i];
    #print STDERR "f = $f start = " . $f->start . " end =  " . $f->end . "\n";

    my ($a,$b) = ($f->start, $f->end);

    push @block_features,{
      start => $flip ? $flip - $b : $a,
      end => $flip ? $flip - $a : $b,
      score => $f->score,
#      score => $f->extra_data->{thick_start}->[0],
    };
    #print STDERR "block feature $a $b " . $f->extra_data->{thick_start}->[0] . "\n";
    #print STDERR "block feature $a $b " . $f->score . "\n";
  }
  
  return $self->{'_cache'}->{'wiggle_features'} = \@block_features;
}

1;

