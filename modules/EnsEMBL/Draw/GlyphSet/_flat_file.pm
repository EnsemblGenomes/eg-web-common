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

package EnsEMBL::Draw::GlyphSet::_flat_file;

use strict;

use List::Util qw(reduce min max);

use EnsEMBL::Web::Text::FeatureParser;
use EnsEMBL::Web::File::User;
use Bio::EnsEMBL::Variation::Utils::Constants;

sub draw_features {
  my ($self, $wiggle) = @_; 
  my %data = $self->features;
  
  return 0 unless keys %data;
  
  if ($wiggle) {
    foreach my $key ($self->sort_features_by_priority(%data)) {
      my ($features, $config)     = @{$data{$key}};
      my $graph_type              = ($config->{'useScore'} && $config->{'useScore'} == 4) || ($config->{'graphType'} && $config->{'graphType'} eq 'points') ? 'points' : 'bar';
      my ($min_score, $max_score) = split ':', $config->{'viewLimits'};
      
      $min_score = $config->{'min_score'} unless $min_score;
      $max_score = $config->{'max_score'} unless $max_score;

      $self->draw_wiggle_plot($features, { 
        min_score           => $min_score,
        max_score           => $max_score, 
        score_colour        => $config->{'color'},
        axis_colour         => 'black',
## EG        
        description         => $config->{'name'},
        has_pos_infinity    => $config->{'has_pos_infinity'},
        has_neg_infinity    => $config->{'has_neg_infinity'},        
##
        graph_type          => $graph_type,
        use_feature_colours => (lc($config->{'itemRgb'}||'') eq 'on'),
      });
    }
  }
  
  return 1;
}

sub features {
  my $self         = shift;
  my $container    = $self->{'container'};
  my $species_defs = $self->species_defs;
  my $sub_type     = $self->my_config('sub_type');
  my $parser = EnsEMBL::Web::Text::FeatureParser->new($species_defs);
  my $features     = [];
  my %results;
  
  $self->{'_default_colour'} = $self->SUPER::my_colour($sub_type);

## EG: Cannot attach a track with seq_region_names to a translation object as there are no seq_region_names
  next if $container->isa("Bio::EnsEMBL::Translation");
##

  $parser->filter($container->seq_region_name, $container->start, $container->end);

  $self->{'parser'} = $parser;

  if ($sub_type eq 'single_feature') {
    $parser->parse($self->my_config('data'), $self->my_config('format'));
  }
  else {
    my %args = ('hub' => $self->{'config'}->hub);

    if ($sub_type eq 'url') {
      $args{'file'} = $self->my_config('url');
      $args{'input_drivers'} = ['URL']; 
    }
    else {
      $args{'file'} = $self->my_config('file');
      if ($args{'file'} !~ /\//) { ## TmpFile upload
        $args{'prefix'} = 'user_upload';
      }
    }

    my $file = EnsEMBL::Web::File::User->new(%args);

    return $self->errorTrack(sprintf 'The file %s could not be found', $self->my_config('caption')) if !$file->exists;

    my $response = $file->read;

    if (my $data = $response->{'content'}) {
      $parser->parse($data, $self->my_config('format'));

## EG  
      # if no tracks found, filter by synonym name
      unless ($parser->{'tracks'}){
        foreach my $synonym (@{$container->get_all_synonyms}) {
          $parser->filter($synonym->name, $container->start, $container->end);
          $parser->parse($data, $self->my_config('format'));
          last if $parser->{'tracks'};
        }
      }
##
    } else {
      warn "!!! $response->{'error'}";
    }
  } 

  ## Now we translate all the features to their rightful co-ordinates
  while (my ($key, $T) = each (%{$parser->{'tracks'}})) {
    $_->map($container) for @{$T->{'features'}};
 
    ## Set track depth a bit higher if there are lots of user features
    $T->{'config'}{'dep'} = scalar @{$T->{'features'}} > 20 ? 20 : scalar @{$T->{'features'}};

    ## Quick'n'dirty BED hack
    foreach (@{$T->{'features'}}) {
      if ($_->can('external_data') && $_->external_data && $_->external_data->{'BlockCount'}) {
        $self->{'my_config'}->set('has_blocks', 1);
        last;
      }
    }

    ### ensure the display of the VEP features using colours corresponding to their consequence
    if ($self->my_config('format') eq 'VEP_OUTPUT') {
      my %overlap_cons = %Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES;      
      my %cons_lookup = map { $overlap_cons{$_}{'SO_term'} => $overlap_cons{$_}{'rank'} } keys %overlap_cons;
    
      ## Group results into sets by start, end and allele, so we can treat them 
      ## as single features in the next step 
      my %cons = map { # lowest rank consequence from comma-list
        $_->consequence => reduce { $cons_lookup{$a} < $cons_lookup{$b} ? $a : $b } split(/,/,$_->consequence); 
      } @{$T->{'features'}};
      @{$T->{'features'}} = sort {$a->start <=> $b->start
          || $a->end <=> $b->end
          || $a->allele_string cmp $b->allele_string
          || $cons_lookup{$cons{$a->consequence}} <=> $cons_lookup{$cons{$b->consequence}}
        } @{$T->{'features'}};

      my $colours = $species_defs->colour('variation');
      
      $T->{'config'}{'itemRgb'} = 'on';
    
      ## Merge raw features into a set of unique variants with multiple consequences 
      my ($start, $end, $allele);
      foreach (@{$T->{'features'}}) {
        my $last = $features->[-1];
        if ($last && $last->start == $_->start && $last->end == $_->end && $last->allele_string eq $_->allele_string) {
          push @{$last->external_data->{'Type'}[0]}, $_->consequence;
        }
        else {
          $_->external_data->{'item_colour'}[0] = $colours->{lc $cons{$_->consequence}}->{'default'} || $colours->{'default'}->{'default'};
          $_->external_data->{'Type'}[0]        = [$_->consequence];
          push @$features, $_;
          $start = $_->start;
          $end = $_->end;
          $allele = $_->allele_string;
        }
      }
      ## FinallY dedupe the consequences
      foreach (@$features) {
        my %dedupe;
        foreach my $c (@{$_->external_data->{'Type'}[0]||[]}) {
          $dedupe{$c}++;
        }
        $_->external_data->{'Type'}[0] = join(', ', sort {$cons_lookup{$a} <=> $cons_lookup{$b}} keys %dedupe);
      }
    }
    else {
      $features = $T->{'features'};
    }

    $results{$key} = [$features, $T->{'config'}];

## EG
    if (my $description = $T->{'config'}->{'description'}) {
      $self->append_hover_label_description( $description );
    }
##      
  }

  return %results;
}

sub render_gradient {
  my $self = shift;

  my %data = $self->features;
  
  return 0 unless keys %data;
  
  foreach my $key ($self->sort_features_by_priority(%data)) {
    my ($features, $config)     = @{$data{$key}};
    
    my ($min_score, $max_score) = split ':', $config->{'viewLimits'};
    $min_score = $config->{'min_score'} unless $min_score;
    $max_score = $config->{'max_score'} unless $max_score;

    $self->draw_gradient($features, { 
      min_score => $min_score,
      max_score => $max_score,
      caption   => $config->{'name'},
      no_bump   => 1
    });
  }
}

sub render_pvalue {
  my $self = shift;

  my %data = $self->features;
  
  return 0 unless keys %data;
  
  foreach my $key ($self->sort_features_by_priority(%data)) {
    my ($features, $config)     = @{$data{$key}};

    $self->draw_gradient($features, { 
      min_score      => 0,
      max_score      => 1,
      key_labels     => [ 0, 0.05, 1 ],
      transform      => 'log2',
      decimal_places => 5,
      caption        => $config->{'name'},
    });
  }
}

## EG - really, really, really nasty hack to put the the track description into the hover
##      label pop-up by making lots of assumptions about object internals

sub append_hover_label_description {
  my ($self, $description) = @_;
  
  my $species  = $self->{config}->{hub}->species;
  my $track_id = $self->{my_config}->{id};
  my $label_id = $species . '_' . $track_id;
  
  # add html markup for url links (regex from http://blog.mattheworiordan.com/post/13174566389/url-regular-expression-for-links-with-or-without-the)
  my $url_regex   = qr/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/;
  my $description = join ' ', map {$_ =~ $url_regex ? qq(<a href="$_">$_</a>") : $_ } split(/\s/, $description);

  $self->{config}->{hover_labels}->{$label_id}->{desc} .= "<p>$description</p>";
}

##

sub feature_title {
  my ($self, $f, $db_name) = @_;
  my @strand_name = qw(- Forward Reverse);
  my $title       = sprintf(
    '%s: %s; Start: %d; End: %d; Strand: %s',
    $self->{'track_key'},
    $f->id,
    $f->seq_region_start,
    $f->seq_region_end,
    $strand_name[$f->seq_region_strand]
  );

  $title .= '; Hit start: ' . $f->hstart if $f->hstart;
  $title .= '; Hit end: ' . $f->hend if $f->hend;
  $title .= '; Hit strand: ' . $f->hstrand if $f->hstrand;
  $title .= '; Score: ' . $f->score if $f->score; 
 
  my %extra = $f->extra_data && ref $f->extra_data eq 'HASH' ? %{$f->extra_data} : (); 
 
  foreach my $k (sort keys %extra) {
    next if $k eq '_type';
    next if $k eq 'item_colour';
    $title .= "; $k: " . join ', ', @{$extra{$k}};
  }
## EG - add optional external link 
  my $external_link = $self->my_config('external_link');
  if ($external_link) {
    my ($url, $caption) = @$external_link;
    my $id = $f->id;
    $url =~ s/###ID###/$id/g;
    $title .= sprintf '; %s: <a href="%s">%s</a>', $caption, $url, $id;
  }
##

  return $title;
}


1;
