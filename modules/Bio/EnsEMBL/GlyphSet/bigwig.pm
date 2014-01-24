package Bio::EnsEMBL::GlyphSet::bigwig;

use strict;

use Bio::EnsEMBL::ExternalData::BigFile::BigWigAdaptor;

use base qw(Bio::EnsEMBL::GlyphSet::_alignment  Bio::EnsEMBL::GlyphSet_wiggle_and_block);

# get the alignment features
sub wiggle_features {
  my ($self, $bins) = @_;

  my $slice = $self->{'container'};
  if (!exists($self->{_cache}->{wiggle_features})) {
    my $summary_e = $self->bigwig_adaptor->fetch_extended_summary_array($slice->seq_region_name, $slice->start, $slice->end, $bins);

    # check summary by synonym name unless not found by name
    if ( !@$summary_e ){
      my $synonym_obj = $slice->get_all_synonyms(); # arrayref of Bio::EnsEMBL::SeqRegionSynonym objects
      foreach my $synonym (@$synonym_obj) {
        $summary_e =  $self->bigwig_adaptor->fetch_extended_summary_array($synonym->name, $slice->start, $slice->end, $bins);
        last if (ref $summary_e eq 'ARRAY' && @$summary_e > 0);
      }
    }

    my $binwidth  = ($slice->length/$bins);
    my $flip      = $slice->strand == -1 ? $slice->length + 1 : undef;
    my @features;
    
    for (my $i=0; $i<$bins; $i++) {
      my $s = $summary_e->[$i];
      my $mean = $s->{validCount} > 0 ? $s->{sumData}/$s->{validCount} : 0;

      my $feat = {
        start => $flip ? $flip - (($i+1)*$binwidth) : ($i*$binwidth+1),
        end   => $flip ? $flip - ($i*$binwidth+1)   : (($i+1)*$binwidth),
        score => $mean
      };
      
      push @features,$feat;
    }
    
    $self->{_cache}->{wiggle_features} = \@features;
  }

  return $self->{_cache}->{wiggle_features};
}

sub draw_features {
  my ($self, $wiggle)= @_;  

  my $drawn_wiggle_flag = $wiggle ? 0: "wiggle"; 

  my $slice = $self->{'container'};

  my $feature_type = $self->my_config('caption');

  my $colour = $self->my_config('colour');

  # render wiggle if wiggle
  if ($wiggle) { 
    my $max_bins = $self->{'config'}->image_width();
    if ($max_bins > $slice->length) {
      $max_bins = $slice->length;
    }

    my $features =  $self->wiggle_features($max_bins);
    $drawn_wiggle_flag = "wiggle";

    my $min_score;
    my $max_score;

    my $viewLimits = $self->my_config('viewLimits');

    if (defined($viewLimits)) {
      ($min_score,$max_score) = split ":",$viewLimits;
    } else {
      $min_score = $features->[0]->{score};
      $max_score = $features->[0]->{score};
      foreach my $feature (@$features) { 
        my $fscore = $feature->{score};
        if ($fscore < $min_score) { $min_score = $fscore };
        if ($fscore > $max_score) { $max_score = $fscore };
      }
    }

    my $no_titles = $self->my_config('no_titles');

    my $params = { 'min_score'    => $min_score, 
                   'max_score'    => $max_score, 
## EG
## TODO - push this back to ensembl-draw                    
                   #'description'  =>  $self->my_config('caption'),
                   'description'  => $self->my_config('name'),
##      
                   'score_colour' =>  $colour,
                 };

    if (defined($no_titles)) {
      $params->{'no_titles'} = 1;
    }

    # render wiggle plot        
    $self->draw_wiggle_plot(
          $features,                      ## Features array
          $params
          #[$colour],
          #[$feature_type],
        );
    $self->draw_space_glyph() if $drawn_wiggle_flag;
  }

  if( !$wiggle || $wiggle eq 'both' ) { 
    warn("bigwig glyphset doesn't draw blocks\n");
  }

  my $error = $self->draw_error_tracks($drawn_wiggle_flag);
  return 0;
}


1;
