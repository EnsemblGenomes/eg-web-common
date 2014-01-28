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

package EnsEMBL::Web::Text::FeatureParser;

### This object parses data supplied by the user and identifies 
### sequence locations for use by other Ensembl objects

use strict;
use warnings;
no warnings "uninitialized";
use EnsEMBL::Web::Root;
use List::MoreUtils;
use Carp qw(cluck);
use Data::Dumper;
use EnsEMBL::Web::SpeciesDefs;

sub parse { 
  my ($self, $data, $format) = @_;
  $format = 'BED' if $format eq 'BEDGRAPH';
  return 'No data supplied' unless $data;
  #use Carp qw(cluck); cluck $format;

  my $error = $self->check_format($data, $format);
  if ($error) {
    return $error;
  }
  else {
    $format = uc($self->format); 
    my $filter = $self->filter;

    ## Some complex formats need extra parsing capabilities
    my $sub_package = __PACKAGE__."::$format";
    if (EnsEMBL::Web::Root::dynamic_use(undef, $sub_package)) {
      bless $self, $sub_package;
    }
    ## Create an empty feature that gives us access to feature info
    my $feature_class = 'EnsEMBL::Web::Text::Feature::'.uc($format);  
    my $empty = $feature_class->new();
    my $count;
    my $current_max = 0;
    my $current_min = 0;
    my $valid_coords = $self->{'valid_coords'}; 

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
          #$chr =~ s/chr//
          
          ## EG - only strip the chr prefix if we don't have an exact chr name match
          $chr =~ s/chr// unless grep {$_ eq $chr} @{$self->drawn_chrs};
          
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
          
          if (keys %$valid_coords && scalar(@$columns) >1 && $format !~ /snp|pileup|vcf/i) { 
            ## We only validate on chromosomal coordinates, to prevent errors on vertical code
            next unless $valid_coords->{$chr}; ## Chromosome is valid and has length
            next unless $start > 0 && $end <= $valid_coords->{$chr};
          
          } 

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
              $current_max = $self->{'tracks'}{$self->current_key}{'config'}{'max_score'};
              $current_min = $self->{'tracks'}{$self->current_key}{'config'}{'min_score'};
              $current_max = $feature->score if $feature->score > $current_max;
              $current_min = $feature->score if $feature->score < $current_min;
              $current_max = 0 unless $current_max; ## Because shit happens...
              $current_min = 0 unless $current_min;
              $self->{'tracks'}{$self->current_key}{'config'}{'max_score'} = $current_max;
              $self->{'tracks'}{$self->current_key}{'config'}{'min_score'} = $current_min;
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

sub parse_track_def {
  my ($self, $row) = @_;
  my $config = {'name' => 'default'};

  ## Pull out any parameters with "-delimited strings (without losing internal escaped '"')
  $row =~ s/^track\s+(.*)$/$1/i;
  while ($row =~ s/(\w+)\s*=\s*"(([\\"]|[^"])+?)"//) {
    my $key = $1;
    (my $value = $2) =~ s/\\//g;
    $config->{$key} = $value;
  }
  ## Grab any remaining whitespace-free content
  if ($row) {
    while ($row =~ s/(\w+)\s*=\s*(\S+)//) {
      $config->{$1} = $2;
    }
  }
  ## Now any value-less parameters (e.g. WIG style)
  if ($row) {
    while ($row =~ s/(\w+)//) {
      $config->{$1} = 1;
    }
  }
  ## Clean up chromosome names
  if (defined $config->{'chrom'}) {
    my $chr = $config->{'chrom'};
    #$chr =~ s/chr//;
    
    ## EG - only strip the chr prefix if we don't have an exact chr name match
    $chr =~ s/chr// unless grep {$_ eq $chr} @{$self->drawn_chrs};
    
    $config->{'chrom'} = $chr;
  }
  ## Add a description
  unless (defined $config->{'description'}) {
    $config->{'description'} = $config->{'name'};
  }

  return $config;
}

sub store_density_feature {
  my ( $self, $chr, $start, $end ) = @_;
  #$chr =~ s/chr//;  
  
  ## EG - only strip the chr prefix if we don't have an exact chr name match
  $chr =~ s/chr// unless grep {$_ eq $chr} @{$self->drawn_chrs};
  
  if (!$self->{'tracks'}{$self->current_key}) {
    $self->add_track();
  }
  elsif (!$self->{'tracks'}{$self->current_key}{'config'}{'color'}) {
    $self->_set_track_colour($self->{'tracks'}{$self->current_key}{'config'});
  }
  $start = int($start / $self->{'_bin_size'} );
  $end = int( $end / $self->{'_bin_size'} );
  $end = $self->{'_no_of_bins'} - 1 if $end >= $self->{'_no_of_bins'};
  $self->{'tracks'}{$self->current_key}{'bins'}{$chr} ||= [ map { 0 } 1..$self->{'_no_of_bins'} ];
  foreach( $start..$end ) {
    $self->{'tracks'}{$self->current_key}{'bins'}{$chr}[$_]++; 
  }
  $self->{'tracks'}{$self->current_key}{'counts'}++;
}

1;
