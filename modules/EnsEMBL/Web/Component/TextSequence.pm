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

package EnsEMBL::Web::Component::TextSequence;

use strict;
use warnings;
no warnings 'uninitialized';

use previous qw(buttons);

sub build_sequence {
  my ($self, $sequence, $config, $exclude_key) = @_;
  my $line_numbers   = $config->{'line_numbers'};
  my %class_to_style = %{$self->class_to_style}; # Firefox doesn't copy/paste anything but inline styles, so convert classes to styles
  my $single_line    = scalar @{$sequence->[0]||[]} <= $config->{'display_width'}; # Only one line of sequence to display
  my $s              = 0;
  my ($html, @output);

  my $adorn = $self->hub->param('adorn') || 'none';
 
  my $adid = 0;
  my $adoff = 0;
  my %addata;
  my %adlookup;
  my %adlookid;
  my %flourishes;

  foreach my $lines (@$sequence) {
    my %current  = ( tag => 'span', class => '', title => '', href => '' );
    my %previous = ( tag => 'span', class => '', title => '', href => '' );
    my %new_line = ( tag => 'span', class => '', title => '', href => '' );
    my ($row, $pre, $post, $count, $i);
    
    foreach my $seq (@$lines) {
      my $style;
      
      my $adorn = (($addata{$adid}||=[])->[$adoff] = {});
      $previous{$_}     = $current{$_} for keys %current;
      $current{'title'} = $seq->{'title'}  ? qq(title="$seq->{'title'}") : '';
      $current{'href'}  = $seq->{'href'}   ? qq(href="$seq->{'href'}")   : '';;
      $current{'tag'}   = $current{'href'} ? 'a class="sequence_info"'   : 'span';
      $current{'letter'} = $seq->{'new_letter'};
      
      if ($seq->{'class'}) {
        $current{'class'} = $seq->{'class'};
        chomp $current{'class'};
        
        if ($config->{'maintain_colour'} && $previous{'class'} =~ /\b(e\w)\b/ && $current{'class'} !~ /\b(e\w)\b/) {
          $current{'class'} .= " $1";
        }
      } elsif($seq->{'tag'}) {
        $current{'class'} = $seq->{'class'};
      } elsif ($config->{'maintain_colour'} && $previous{'class'} =~ /\b(e\w)\b/) {
        $current{'class'} = $1;
      } else {
        $current{'class'} = '';
      }
      
      $post .= $seq->{'post'};
      
      if ($current{'class'}) {
        my %style_hash;
        
        foreach (sort { $class_to_style{$a}[0] <=> $class_to_style{$b}[0] } split ' ', $current{'class'}) {
          my $st = $class_to_style{$_}[1];
          map $style_hash{$_} = $st->{$_}, keys %$st;
        }
        
        $style = sprintf 'style="%s"', join ';', map "$_:$style_hash{$_}", keys %style_hash;
      }
    
      foreach my $k (qw(style title href tag letter)) {
        my $v = $current{$k};
        $v = $style if $k eq 'style';
        $v = $seq->{'tag'} if $k eq 'tag';
        next unless $v;
        $adlookup{$k} ||= {};
        $adlookid{$k} ||= 1;
        my $id = $adlookup{$k}{$v};
        unless(defined $id) {
          $id = $adlookid{$k}++;
          $adlookup{$k}{$v} = $id;
        }
        $adorn->{$k} = $id;
      }
 
      $row .= $seq->{'letter'};
      $adoff++;
      
      $count++;
      $i++;
      
      if ($count == $config->{'display_width'} || $i == scalar @$lines) {
        if ($i == $config->{'display_width'} || $single_line) {
        } else {
          
          if ($new_line{'class'} eq $current{'class'}) {
          } elsif ($new_line{'class'}) {
            my %style_hash;
            
            foreach (sort { $class_to_style{$a}[0] <=> $class_to_style{$b}[0] } split ' ', $new_line{'class'}) {
              my $st = $class_to_style{$_}[1];
              map $style_hash{$_} = $st->{$_}, keys %$st;
            }
            
          }
        }
        
        if ($config->{'comparison'}) {
          if (scalar keys %{$config->{'padded_species'}}) {
            $pre = $config->{'padded_species'}{$config->{'seq_order'}[$s]} || $config->{'display_species'};
          } else {
            $pre = $config->{'display_species'};
          }
          
          $pre .= '  ';
        }
        
        push @{$output[$s]}, { line => $row, length => $count, pre => $pre, post => $post, adid => $adid };
        
        if($post) {
          ($flourishes{'post'}||={})->{$adid} = $self->jsonify({ v => $post });
        }
        $adid++;
        
        $new_line{$_} = $current{$_} for keys %current;
        $count        = 0;
        $row          = '';
        $adoff        = 0;
        $pre          = '';
        $post         = '';
      }
    }
    
    $s++;
  }

  my %adref;
  foreach my $k (keys %adlookup) {
    $adref{$k} = [""];
    $adref{$k}->[$adlookup{$k}->{$_}] = $_ for keys $adlookup{$k};
  }

  my %adseq;
  foreach my $ad (keys %addata) {
    $adseq{$ad} = {};
    foreach my $k (keys %adref) {
      $adseq{$ad}->{$k} = [];
      foreach (0..@{$addata{$ad}}-1) {
        $adseq{$ad}->{$k}[$_] = $addata{$ad}->[$_]{$k}//undef;
      }
    }
  }

  # We can fix this above and remove this hack when we've got the
  # adorn system finished
  foreach my $k (keys %adref) {
    $adref{$k} = [ map { s/^\w+="(.*)"$/$1/s; $_; } @{$adref{$k}} ];
  }

  # RLE
  foreach my $a (keys %adseq) {
    foreach my $k (keys %{$adseq{$a}}) {
      my @rle;
      my $lastval;
      foreach my $v (@{$adseq{$a}->{$k}}) {
        $v = -1 if !defined $v;
        if(@rle and $v == $lastval) {
          if($rle[-1] < 0) { $rle[-1]--; } else { push @rle,-1; }
        } elsif($v == -1) {
          push @rle,undef;
        } else {
          push @rle,$v;
        }
        $lastval = $v;
      }
      pop @rle if @rle and $rle[-1] and $rle[-1] < 0;
      if(@rle > 1 and !defined $rle[0] and defined $rle[1] and $rle[1]<0) {
        shift @rle;
        $rle[0]--;
      }
      if(@rle == 1 and !defined $rle[0]) {
        delete $adseq{$a}->{$k};
      } else {
        $adseq{$a}->{$k} = \@rle;
      }
    }
    delete $adseq{$a} unless keys %{$adseq{$a}};
  }

  # PREFIX
  foreach my $k (keys %adref) {
    # ... sort
    my @sorted;
    foreach my $i (0..$#{$adref{$k}}) {
      push @sorted,[$i,$adref{$k}->[$i]];
    }
    @sorted = sort { $a->[1] cmp $b->[1] } @sorted;
    my %pmap; 
    foreach my $i (0..$#sorted) {
      $pmap{$sorted[$i]->[0]} = $i;
    }
    @sorted = map { $_->[1] } @sorted;
    # ... calculate prefixes
    my @prefixes;
    my $prev = "";
    my $prevlen = 0;
    foreach my $s (@sorted) {
      if($prev) {
        my $match = "";
        while(substr($s,0,length($match)) eq $match and 
              length($match) < length($prev)) {
          $match .= substr($prev,length($match),1);
        }
        my $len = length($match)-1;
        push @prefixes,[$len-$prevlen,substr($s,length($match)-1)];
        $prevlen = $len;
      } else {
        push @prefixes,[-$prevlen,$s];
        $prevlen = 0;
      }
      $prev = $s; 
    } 
    # ... fix references
    foreach my $a (keys %adseq) {
      next unless $adseq{$a}->{$k};
      my @seq;
      foreach my $v (@{$adseq{$a}->{$k}}) {
        if(defined $v) {
          if($v>0) {
            push @seq,$pmap{$v};
          } else {
            push @seq,$v;
          }
        } else {
          push @seq,undef;
        }
      }
      $adseq{$a}->{$k} = \@seq;
      $adref{$k} = \@prefixes;
    }
  }

  my (@adseq_raw,@adseq);
  foreach my $k (keys %adseq) { $adseq_raw[$k] = $adseq{$k}; }
  my $prev;
  foreach my $i (0..$#adseq_raw) {
    if($i and adseq_eq($prev,$adseq_raw[$i])) {
      if(defined $adseq[-1] and !ref($adseq[-1])) { $adseq[-1]--; } else { push @adseq,-1; }
    } else {
      $prev = $adseq_raw[$i];
      push @adseq,$prev;
    }
  }
  
  my $key = $self->get_key($config,undef,1);

  # Put things not in a type into a 'other' type
  $key->{'other'} ||= {};
  foreach my $k (keys %$key) {
    next if $k eq '_messages';
    if($key->{$k}{'class'}) {
      $key->{'other'}{$k} = $key->{$k};
      delete $key->{$k};
    }
  }

  if($adorn eq 'only') {
    $key->{$_}||={} for @{$config->{'loading'}||[]};
  }
  $key->{$_}||={} for @{$config->{'loaded'}||[]};

  my $adornment = {
    seq => \@adseq,
    ref => \%adref,
    flourishes => \%flourishes,
    legend => $key,
    loading => $config->{'loading'}||[],
  };
  my $adornment_json = encode_entities($self->jsonify($adornment),"<>");

  my $length = $output[0] ? scalar @{$output[0]} - 1 : 0;
  
  for my $x (0..$length) {
    my $y = 0;
    
    foreach (@output) {
      my $line = $_->[$x]{'line'};
      my $adid = $_->[$x]{'adid'};
      $line =~ s/".*?"//sg;
      $line =~ s/<.*?>//sg;
## EG - only tag the main sequence with '_seq' class for BLAST
      my $seq_class = (!$config->{'seq_order'}->[$y] or $self->hub->species eq $config->{'seq_order'}->[$y]) ? ' _seq' : '';    
      $line = qq(<span class="adorn adorn-$adid$seq_class">$line</span>);
##
      my $num  = shift @{$line_numbers->{$y}};
      
      if ($config->{'number'}) {
        my $pad1 = ' ' x ($config->{'padding'}{'pre_number'} - length $num->{'label'});
        my $pad2 = ' ' x ($config->{'padding'}{'number'}     - length $num->{'start'});
           $line = $config->{'h_space'} . sprintf('%6s ', "$pad1$num->{'label'}$pad2$num->{'start'}") . $line;
      }
      
      $line .= ' ' x ($config->{'display_width'} - $_->[$x]{'length'}) if $x == $length && ($config->{'end_number'} || $_->[$x]{'post'});
      
      if ($config->{'end_number'}) {
        my $n    = $num->{'post_label'} || $num->{'label'};
        my $pad1 = ' ' x ($config->{'padding'}{'pre_number'} - length $n);
        my $pad2 = ' ' x ($config->{'padding'}{'number'}     - length $num->{'end'});
        
        $line .= $config->{'h_space'} . sprintf ' %6s', "$pad1$n$pad2$num->{'end'}";
      }
     
      $line = "$_->[$x]{'pre'}$line" if $_->[$x]{'pre'};
      $line .= qq(<span class="ad-post-$adid">);
      $line .= $_->[$x]{'post'} if $_->[$x]{'post'};
      $line .= qq(</span>);
      $html .= "$line\n";
      
      $y++;
    }
    
    $html .= $config->{'v_space'};
  }
  
  $config->{'html_template'} ||= qq{<pre class="text_sequence">%s</pre><p class="invisible">.</p>};  
  $config->{'html_template'} = sprintf $config->{'html_template'}, $html;
  
  if ($config->{'sub_slice_start'}) {
    my $partial_key;
    $partial_key->{$_} = $config->{$_} for grep $config->{$_},        @{$self->{'key_params'}};
    $partial_key->{$_} = 1             for grep $config->{'key'}{$_}, @{$self->{'key_types'}};
    
    foreach my $type (grep $config->{'key'}{$_}, qw(exons variations)) {
      $partial_key->{$type}{$_} = 1 for keys %{$config->{'key'}{$type}};
    }
    
    $config->{'html_template'} .= sprintf '<div class="sequence_key_json hidden">%s</div>', $self->jsonify($partial_key) if $partial_key;
  }

  my $random_id = random_string(8);

  my $key_html = '';
  unless($exclude_key) {
    $key_html = qq(<div class="_adornment_key adornment-key"></div>);
  }

  my $id = $self->id;
  my $panel_type = qq(<input type="hidden" class="panel_type" value="TextSequence" name="panel_type_$id" />);
  if($adorn eq 'none') {
    my $ajax_url = $self->hub->apache_handle->unparsed_uri;
    my ($path,$params) = split(/\?/,$ajax_url,2);
    my @params = split(/;/,$params);
    for(@params) { $_ = 'adorn=only' if /^adorn=/; }
    $ajax_url = $path.'?'.join(';',@params,'adorn=only');
    my $ajax_json = encode_entities($self->jsonify({ url => $ajax_url, provisional => $adornment }),"<>");
    return qq(
      <div class="js_panel" id="$random_id">
        $key_html
        <div class="adornment">
          <span class="adornment-data" style="display:none;">
            $ajax_json
          </span>
          $config->{'html_template'}
        </div>
        $panel_type
      </div>
    );

  } elsif($adorn eq 'only') {
    return qq(<div><span class="adornment-data">$adornment_json</span></div>);
  } else {
    return qq(
      <div class="js_panel" id="$random_id">
        $key_html
        <div class="adornment">
          <span class="adornment-data" style="display:none;">
            $adornment_json
          </span>
          $config->{'html_template'}
        </div>
        $panel_type
      </div>
    );
  }
}

1;
