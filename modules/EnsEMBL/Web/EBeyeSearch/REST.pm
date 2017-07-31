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

package EnsEMBL::Web::EBeyeSearch::REST;

# Simple client for EBeye search REST service
# http://www.ebi.ac.uk/Tools/webservices/services/eb-eye_rest

use strict;
use warnings;
use Data::Dumper;
use HTTP::Message;
use LWP;
use URI::QueryParam;
use JSON;

my $debug = 0;

sub new {
  my ($class, %args) = @_;
  my  $self = {
    base_url => $args{base_url} || 'http://www.ebi.ac.uk/ebisearch/ws/rest',
  };
  bless $self, $class;
  return $self;
}

sub base_url { $_[0]->{base_url} }

sub user_agent { 
  my $self = shift;
  
  unless ($self->{user_agent}) {
    my $ua = LWP::UserAgent->new();
    $ua->agent('EnsemblGenomes Web ' . $ua->agent());
    $ua->env_proxy;
    $ua->timeout(30);
    $self->{user_agent} = $ua;
  }
  
  return $self->{user_agent};
}

sub get { 
  my ($self, $method, $args) = @_;
  $args ||= {};
  $args->{format} = 'json';

  my $uri = URI->new($self->base_url . ($method ? "/$method" : ''));
  $uri->query_param( $_, $args->{$_} ) for keys %$args;
  
  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };
  
  $debug && warn "GET " . $uri->as_string;

  my $response = $self->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;
  
  if ($response->is_error) {
    die 'EBeye search error: ' . $response->status_line;
  }

  return from_json($content);
}

#--- API methods ---

sub get_facet_values {
  my ($self, $domain, $query, $facet_id, $args) = @_;
  $args ||= {};
  $args->{facetcount} ||= 10;
  
  my $results = $self->get($domain, {%$args, query => $query, size => 0});

  my $facet_values = [];  
  foreach my $facet (@{$results->{facets}}) {
    if ($facet->{id} eq $facet_id) {
      $facet_values = $facet->{facetValues};  
      last;
    }
  }
  return $facet_values;
}

sub get_results {
  my ($self, $domain, $query, $args) = @_;
  $args ||= {};

  return $self->get($domain, {%$args, query => $query});
}

sub get_results_count {
  my ($self, $domain, $query) = @_;
  
  my $results = $self->get($domain, {query => $query, size => 0});
  return $results->{hitCount} || 0;
}

sub get_results_as_hashes {
  my ($self, $domain, $query, $args, $opts) = @_;
  $args ||= {};

  my $results = $self->get($domain, {%$args, query => $query});

  my $hashes = [];
  foreach my $entry (@{$results->{entries}}) {
    my %hash = map {$_ => $entry->{fields}->{$_}} keys %{$entry->{fields}};
    
    # by default all fields are returned as arrayrefs, but sometimes we know we will 
    # only have a single value so we can reduce those fields to scalars
    if (ref $opts->{single_values} eq 'ARRAY') { 
      $hash{$_} = $hash{$_}->[0] for @{$opts->{single_values}}; 
    } elsif ($opts->{single_values}) {
      $hash{$_} = $hash{$_} for keys %hash; # all fields
    }

    push @$hashes, \%hash;
  }
  return $hashes;
}

1;
