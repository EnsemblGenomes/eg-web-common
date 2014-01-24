package EnsEMBL::Web::Component::Gene::S4DASPUBMED;

use strict;
use EBeyeSearch::EBeyeWSWrapper;
use base qw(EnsEMBL::Web::Component::Gene::S4DAS);

sub _filter_features {
  my ($self, $features) = @_; 
  return [] unless @{$features};
  # only want features labelled 'All Articles'
  return [grep {$_->display_label =~ /^All Articles$/i} @{$features}];
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
        
    my ($pubmed_id) = $segment->{url} =~ /segment=([^;]+)$/i;

    #debug
    #$html .= sprintf qq{<a href="$segment->{url}">[view DAS response]</a>\n};
    
    if ($segment->{'error'}) {
      $html .= $self->_error('Error*', $segment->{'error'}, '100%');
      next;
    }
    
    # get the features
    my $features     = $self->_filter_features($segment->{'objects'});
    next unless @$features;

    my @summaries    = @{$self->_parse_features_by_type($features, 'summary')};
    
    $html .= '<div class="segment">';
       
    # summaries
    my $label;
    foreach my $summary (@summaries) { # in reality probably only one item here
      
      push @{$summary->{links}}, {href => $hub->get_ExtURL('PUBMED', $pubmed_id), text => 'View in PubMed'} if $pubmed_id;

      $html .= qq{<div class="summary">\n};
      $html .= qq{<p>$_</p>\n} foreach(@{$summary->{notes}});
      $html .= join(' | ', map {qq{<a href="$_->{href}">$_->{text}</a>\n}} @{$summary->{links}});
      $html .= qq{</div>\n};
    }
       
    $html = qq{<div id="s4das-page">$html</div>};
    $segments_rendered ++;

  }

  $html = '<h1>All Articles</h1>' . $html if $segments_rendered;
  $html .= '<p>No data available.</p>'    if !$segments_rendered;
  
  # debug
  #$html .= "<hr /><pre>" . Dumper($data->{'features'}) . "</pre>";
 
  $html .= '<br /><br</div>';

  return $html;
}

1;

