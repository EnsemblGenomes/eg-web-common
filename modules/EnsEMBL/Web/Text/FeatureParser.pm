=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Text::FeatureParser;

### This object parses data supplied by the user and identifies 
### sequence locations for use by other Ensembl objects
sub parse { 
  my ($self, $data, $format) = @_;
  ## Make sure format is given as uppercase
  $format = uc($format);
  $format = 'BED' if $format =~ /BEDGRAPH|BGR/;
  return 'No data supplied' unless $data;

  my $error = $self->check_format($data, $format);
  if ($error) {
    return $error;
  }
  else {
    $format = uc($self->format);
    my $filter = $self->filter;

    ## Some complex formats need extra parsing capabilities
    my $sub_package = __PACKAGE__."::$format";
    if (EnsEMBL::Root::dynamic_use(undef, $sub_package)) {
      bless $self, $sub_package;
    }
    ## Create an empty feature that gives us access to feature info
    my $feature_class = 'EnsEMBL::Web::Text::Feature::'.$format;  
    my $empty = $feature_class->new();
    my $count;
    my $current_max = 0;
    my $current_min = 0;

    ## On upload, keep track of current location so we can find nearest feature
    my ($current_index, $current_region, $current_start, $current_end);    
    if (@{$self->{'drawn_chrs'}} && (my $location = $self->{'current_location'})) {
      ($current_region, $current_start, $current_end) = split(':|-', $location);
      $current_index = List::MoreUtils::first_index {$_ eq $current_region} @{$self->drawn_chrs} if $current_region;
    }

    my ($track_def, $track_def_base);
    foreach my $row ( split /\n|\r/, $data ) { 
      ## Clean up the row
      next if $row =~ /^#/;
      $row =~ s/^[\t\r\s]+//g;
      $row =~ s/[\t\r\s]+$//g;
      $row =~ tr/\x80-\xFF//d;
      next unless $row;

      ## Parse as appropriate
      if ( $row =~ /^browser\s+(\w+)\s+(.*)/i ) {
        $self->{'browser_switches'}{$1} = $2;
      }
      ## Build track definition - could be multiple lines
      elsif ($row =~ /^track/) {
        $track_def_base = $row;
        $track_def      = $track_def_base;
      }
      elsif ($format eq 'WIG' && $row !~ /^\d+/) {
        ## Some WIG files have partial track definitions
        if (!$track_def) {
          $track_def = $track_def_base;
        }
        $track_def .= ' '.$row;
      }
      else { 
        ## Parse track definition, if any
        if ($track_def) {
          my $config = $self->parse_track_def($track_def);
          $self->add_track($config);
          if (ref($self) eq 'EnsEMBL::Web::Text::FeatureParser::WIG') {
            $self->style('wiggle');
            $self->set_wig_config;
          }
          elsif ($config->{'type'} eq 'bedGraph' || $config->{'type'} =~ /^wiggle/ 
                || ($config->{'useScore'} && $config->{'useScore'} > 2)) {
            $self->style('wiggle');
          }

          ## Reset values in case this is a multi-track file
          $track_def = '';
          $current_max = 0;
          $current_min = 0;
        }

        my $columns; 
        if (ref($self) eq 'EnsEMBL::Web::Text::FeatureParser') { 
          ## 'Normal' format consisting of a straightforward feature 
          ($columns) = $self->split_into_columns($row, $format);  
        }
        else { 
          ## Complex format requiring special parsing (e.g. WIG)
          $columns = $self->parse_row($row);
        }
        if ($columns && scalar(@$columns)) {   
          my ($chr, $start, $end) = $empty->coords($columns); 
          
          $chr =~ s/[cC]hr// unless grep {$_ eq $chr} @{$self->drawn_chrs};
          
          ## We currently only do this on initial upload (by passing current location)  
          $self->{'_find_nearest'}{'done'} = $self->_find_nearest(
                      {
                        'region'  => $current_region, 
                        'start'   => $current_start, 
                        'end'     => $current_end, 
                        'index'   => $current_index,
                      }, 
                      {
                        'region'  => $chr, 
                        'start'   => $start, 
                        'end'     => $end,
                        'index'   => List::MoreUtils::first_index {$_ eq $chr} @{$self->drawn_chrs},
                      }
            ) unless $self->{'_find_nearest'}{'done'};
          
          ## Optional - filter content by location
          if ($filter->{'chr'}) {
            next unless ($chr eq $filter->{'chr'} || $chr eq 'chr'.$filter->{'chr'}); 
            if ($filter->{'start'} && $filter->{'end'}) {
              next unless (
                ($start >= $filter->{'start'} && $end <= $filter->{'end'}) ## feature lies within coordinates
                || ($start < $filter->{'start'} && $end >= $filter->{'start'}) ## feature overlaps start
                || ($end > $filter->{'end'} && $start <= $filter->{'end'}) ## feature overlaps end
  
              );
            }
          }

          ## Everything OK, so store
          if ($self->no_of_bins) {
            $self->store_density_feature($empty->coords($columns));
          }
          else {
            my $feature = $feature_class->new($columns); 
            if ($feature->can('score')) {
          
## EG - ENSEMBL-3226 infinity        
              if ($feature->score =~ /INF$/i) {
                $self->{'tracks'}{$self->current_key}{'config'}{'has_pos_infinity'} = 1 if uc($feature->score) eq 'INF';
                $self->{'tracks'}{$self->current_key}{'config'}{'has_neg_infinity'} = 1 if uc($feature->score) eq '-INF';
              } else {
##              
                $current_max = $self->{'tracks'}{$self->current_key}{'config'}{'max_score'};
                $current_min = $self->{'tracks'}{$self->current_key}{'config'}{'min_score'};
                $current_max = $feature->score if $feature->score > $current_max;
                $current_min = $feature->score if $feature->score < $current_min;
                $current_max = 0 unless $current_max; ## Because bad things can happen...
                $current_min = 0 unless $current_min;
                $self->{'tracks'}{$self->current_key}{'config'}{'max_score'} = $current_max;
                $self->{'tracks'}{$self->current_key}{'config'}{'min_score'} = $current_min;
              }
            }
            $self->store_feature($feature);
          }
          $count++;
        }
      }
    }
    $self->{'feature_count'} = $count;
    ## Extend sample coordinates a bit!
    if ($self->{'_find_nearest'}{'nearest_region'}) {
      my $midpoint = int(abs($self->{'_find_nearest'}{'nearest_start'} 
                              - $self->{'_find_nearest'}{'nearest_end'})/2) 
                              + $self->{'_find_nearest'}{'nearest_start'};
      my $start = $midpoint < 50000 ? 0 : ($midpoint - 50000);
      my $end = $start + 100000;
      $self->{'nearest'} = $self->{'_find_nearest'}{'nearest_region'}.':'.$start.'-'.$end;
    }
  }
}

1;
