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

package EBeyeSearch::REST;

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
    $ua->timeout(10);
    $self->{user_agent} = $ua;
  }
  
  return $self->{user_agent};
}

sub get { 
  my ($self, $method, %args) = @_;

  $args{format} = 'json';

  my $uri = URI->new($self->{base_url . ($method ? "/$method" : ''));
  $uri->query_param( $_, $args{$_} ) for keys %args;
  
  my $can_accept;
  eval { $can_accept = HTTP::Message::decodable() };

  $debug && warn "GET " . $uri->as_string;

  my $response = $self->user_agent->get($uri->as_string, 'Accept-Encoding' => $can_accept);
  my $content  = $can_accept ? $response->decoded_content : $response->content;
  
  if ($response->is_error) {
    die 'EBeye search error: ' . $response->status_message;
  }

  return from_json($content);
}

#--- search methods ---

sub get_domain_hierarchy {
  my $self = shift;
  my $json = $self->get();
  return from_json($json);
}

sub get_domain_details {
  my ($self, $domain) = @_;
  return $self->get($domain);
}

sub get_results_count {
  my ($self, $domain, $query) = @_;
  my $result = $self->get($domain, (query => $query, size => 0));
  return $result->{hitCount} || 0;
}

sub get_results {
  my ($self, $domain, $query, %args) = @_;
  return $self->get($domain, (%args, query => $query));
}

sub get_faceted_results {
  my ($self, $domain, $query, %args) = @_;
  $args{facetcount} ||= 10;
  return $self->get($domain, (%args, query => $query));
}

sub get_entries {
  my ($self, $domain, $entries, %args) = @_;
  return $self->get("$domain/entry/$entries", %args);
}

sub get_domains_referenced_in_domain {
  my ($self, $domain) = @_;
  return $self->get("$domain/xref");
}

sub get_domains_referenced_in_entry {
  my ($self, $domain, $entry) = @_;
  return $self->get("$domain/entry/$entry/xref");
}

sub get_referenced_entries {
  my ($self, $domain, $entries, $ref_domain, %args) = @_;
  return $self->get("$domain/entry/$entries/xref/$ref_domain", %args);
}

1;
