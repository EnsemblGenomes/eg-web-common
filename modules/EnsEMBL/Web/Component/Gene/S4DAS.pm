# $Id: S4DAS.pm,v 1.8 2012-06-20 10:56:47 nl2 Exp $

package EnsEMBL::Web::Component::Gene::S4DAS;

use strict;

use Data::Dumper;
use HTML::Entities qw(encode_entities decode_entities);
use XHTML::Validator;

use LWP::UserAgent;
use Image::Size;

use Bio::EnsEMBL::ExternalData::DAS::Coordinator;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
  $self->{'validator'}          = new XHTML::Validator('extended');
  $self->{'validate_error'}     = 'Data provided by this DAS source contains HTML markup, but it contains errors or has dangerous content. As a security precaution it has not been processed.';
  $self->{'timeout_multiplier'} = 3;
}

sub _das_query_object {
  my $self = shift;
  return $self->object->Obj;
}

# given segment hashref, return filtered segments arrayref
sub _filter_segments {
  my ($self, $segments) = @_; 
  return [values %$segments];
}

# given features arrayref, return filtered features arrayref
sub _filter_features {
  my ($self, $features) = @_; 
  return $features;
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $logic_name   = $hub->referer->{'ENSEMBL_FUNCTION'} || $hub->function; # The DAS source this page represents
  my $html;
    
  return $self->_error('No DAS source specified', 'No parameter passed!', '100%') unless $logic_name;
  
  my $source = $hub->get_das_by_logic_name($logic_name);
  
  return $self->_error(qq{DAS source "$logic_name" specified does not exist}, 'Cannot find the specified DAS source key supplied', '100%') unless $source;
  
  my $query_object = $self->_das_query_object;   

  return 'No data available.' unless $query_object;

  my $engine = new Bio::EnsEMBL::ExternalData::DAS::Coordinator(
    -sources => [ $source ],
    -proxy   => $species_defs->ENSEMBL_WWW_PROXY,
    -noproxy => $species_defs->ENSEMBL_NO_PROXY,
    -timeout => $species_defs->ENSEMBL_DAS_TIMEOUT * $self->{'timeout_multiplier'}
  );
  
  # Perform DAS requests
  my $data = $engine->fetch_Features($query_object)->{$logic_name};
  
  # Check for source errors (bad configs)
  my $source_err = $data->{'source'}->{'error'};
  
  if ($source_err) {
    if ($source_err =~ /^(Not applicable|No data for region)$/i) {
      return 'No data available.';
    } else {
      return $self->_error('Error', $source_err, '100%');
    }
  }
          
  my $segments = $self->_filter_segments($data->{'features'});
  

  my $segments_rendered = 0;
     
  foreach my $segment (@$segments) {
    
    #debug
    #$html .= sprintf qq{<a href="$segment->{url}">[view DAS response]</a>\n};
    
    if ($segment->{'error'}) {
      $html .= $self->_error('Error*', $segment->{'error'}, '100%');
      next;
    }
    
    # get the features
    my $features     = $self->_filter_features($segment->{'objects'});
    next unless @$features;

    my $description  = @{$self->_parse_features_by_type($features, 'description')}[0];
    my $main_image   = @{$self->_parse_features_by_type($features, 'image')}[0];
    my $block_image  = @{$self->_parse_features_by_type($features, 'image-block')}[0];
    my @summaries    = @{$self->_parse_features_by_type($features, 'summary')};
    my @provenances  = @{$self->_parse_features_by_type($features, 'provenance')};
    
    $html .= '<div class="segment">';
    
    # description
    if ($description) {
    $html .= sprintf qq{<h1>%s</h1>\n}, @{$description->{notes}}[0];
    $html .= qq{<a href="$_->{href}">$_->{text}</a>\n} foreach(@{$description->{links}});
    }
    
    # main image
    if ($main_image) {
      my ($img, $ref) = @{$main_image->{links}};
      
#      # interpro seem to return dud images if there is no architecture image
#      # so check that the image we get is > 1px wide
#      my $response = LWP::UserAgent->new->get($img->{href});
#      my $bin_image = $response->is_success ? $response->content : undef;
#      my ($image_width) = $bin_image ? imgsize(\$bin_image) : 0;

      my $href = $ref ? $ref->{href} : $description->{href};
      $html .= qq{<div class="main-image">\n};
#      if ($image_width > 1) {
        $html .= qq{<a href="$href"><img src="$img->{href}" alt="$img->{text}" /></a>\n};
#      } else {
#        $html .= qq{<br />(No architecture image available)<br /><br />};
#      }
      $html .= qq{<div><a href="$href">$img->{text}</a></div>\n};
      $html .= qq{</div>\n};
    }
 
    # summaries
    my $label;
    foreach my $summary (@summaries) {
      $html .= qq{<div class="summary">\n};
      if ($label ne $summary->{label}) { # only display label if different to last
        $html .= qq{<h3>$summary->{label}</h3>\n}; 
        $label = $summary->{label};
      }
      $html .= qq{<p>$_</p>\n} foreach(@{$summary->{notes}});
      $html .= qq{<a href="$_->{href}">$_->{text}</a>\n} foreach(@{$summary->{links}});
      $html .= qq{</div>\n};
    }
    
    # block image
    if ($block_image) {
      my ($img, $ref) = @{$block_image->{links}};
      my $href = $ref ? $ref->{href} : $description->{href};
      $html .= qq{<div class="block-image">\n};
      $html .= qq{<a href="$href"><img src="$img->{href}" alt="$img->{text}" /></a>\n};
      $html .= qq{<div><a href="$href">$img->{text}</a></div>\n};
      $html .= qq{</div>\n};
    }
    
    # provenances
    if (@provenances) {
      $html .= qq{<div class="provenance">\n};
      foreach my $provenance (@provenances) {
        $html .= qq{<div>\n};
        $html .= qq{<p>$_</p>\n} foreach(@{$provenance->{notes}});
        $html .= qq{<a href="$_->{href}">$_->{text}</a>\n} foreach(@{$provenance->{links}});
        $html .= qq{</div>\n};
      }
      $html .= qq{</div>\n};
    }
    
    $html = qq{<div id="s4das-page">$html</div>};
    $segments_rendered ++;

  }

  $html .= '<p>No data available.</p>' if !$segments_rendered;
  
  # debug
  #$html .= "<hr /><pre>" . Dumper($data->{'features'}) . "</pre>";
  
  $html .= '</div>';
  return $html;
}

sub _parse_features_by_type {
  my ($self, $features, $type) = @_;
  #my $error;
  my @objs;
  
  foreach my $f (sort { $a->type_label cmp $b->type_label || $a->display_label cmp $b->display_label } @{$features}) {    
    next if $type and ($f->type_id !~ /$type$/i and $f->type_label !~ /^$type$/i);
    
    my (@notes, @links);
    
    foreach my $raw (@{$f->notes}) {
      # support embeded html
      my ($note, $warning) = $self->_decode_and_validate($raw);
      #$error = $warning unless $error; # keep only first error
      push @notes, $note;
    }
    
    foreach my $link (@{$f->links}) {
      my $raw         = $link->{'href'};
      my ($cdata, $w) = $self->_decode_and_validate($link->{'txt'});
      my ($href, $warning) = $self->_validate($raw);
      #$error = $warning unless $error; # keep only first error
      push @links, {href => $href, text => $cdata};
    }
        
    my ($display_label , $w) = $self->_decode_and_validate($f->display_label);
    
    push @objs, {
      label => $display_label,
      notes => \@notes,
      links => \@links,
    }; 
  }
  
  return \@objs;
}

sub _decode_and_validate {
  my ($self, $text) = @_;
  return $self->_validate(decode_entities($text));
}

sub _validate {
  my ($self, $text) = @_;
  
  # Check for naughty people trying to do XSS...
  if (my $warning = $self->{'validator'}->validate($text)) {
    $text = encode_entities($text);
    return ($text, $warning);
  }
  
  return ($text, undef);
}

1;

