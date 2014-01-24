package EnsEMBL::Web::Component::Gene::S4DASLiterature;
use strict;
use EBeyeSearch::EBeyeWSWrapper;
use base qw(EnsEMBL::Web::Component::Gene::S4DAS);
use Data::Dumper;
use URI::Escape;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $gene_id      = $self->hub->param('g');
  my $species_defs = $hub->species_defs;
  my $logic_name   = $hub->referer->{'ENSEMBL_FUNCTION'} || $hub->function; # The DAS source this page represents
  my $html;

  return $self->_error('No DAS source specified', 'No parameter passed!', '100%') unless $logic_name;
  
  my $source = $hub->get_das_by_logic_name($logic_name);
  
  return $self->_error(qq{DAS source "$logic_name" specified does not exist}, 'Cannot find the specified DAS source key supplied', '100%') unless $source;
  
  my $query_object = $self->_das_query_object;   

  return $html . '<p>No data available.<p>' unless $query_object;

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
    if ($source_err eq 'Not applicable' or $source_err = 'No data for region') {
      return $html . '<p>No data available.<p>';
    } else {
      return $self->_error('Error', $source_err, '100%');
    }
  }
  
  my $segments = $self->_filter_segments($data->{'features'});
  
  my $table = $self->new_table(
    [
      { key => 'title',     title => 'Title',          width => '40%', align => 'left', sort => 'string' },
      { key => 'authors',   title => 'Authors',        width => '30%', align => 'left', sort => 'string' },
      { key => 'journal',   title => 'Journal',        width => '20%', align => 'left', sort => 'string' },
      { key => 'links',     title => 'Links',          width => '10%', align => 'left', sort => 'none' },
    ], 
    [], 
    { 
      class      => 'no_col_toggle',
      data_table => 1, 
      exportable => 0,
    }
  );
  
  my %unique_rows;
  
  foreach my $segment (@$segments) {
    #debug
    #$html .= sprintf qq{<a href="$segment->{url}">[view DAS response]</a>\n};
  
    if ($segment->{'error'}) {
      $html .= $self->_error('Error*', $segment->{'error'}, '100%');
      next;
    }
        
    my $features = $self->_filter_features($segment->{'objects'});
    next unless @$features;

    foreach my $summary ( @{$self->_parse_features_by_type($features, 'publication')} ) { 
      my ($title, $authors, $journal) = @{$summary->{notes}};
      my @links = map { qq(<a href="$_->{href}" style="white-space:nowrap">$_->{text}</a>) } @{$summary->{links}};
      
      $unique_rows{"$title/$authors/$journal"} = {
        title     => $title,
        authors   => $authors,
        journal   => $journal,
        links     => join('<br />', @links),
      };

    }
  } 
  
  $table->add_rows(values %unique_rows);
  
  $html .= $table->render;
 
  # debug
  #$html .= "<hr /><pre>" . Dumper($data->{'features'}) . "</pre>";

  return $html;
}

1;

