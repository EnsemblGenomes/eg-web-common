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

package EnsEMBL::Web::JobDispatcher::EbiWuBlast;

use strict;
use warnings;
use HTTP::Request;
use JSON qw(to_json);
use LWP::UserAgent;
use URI;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents file_put_contents);

use parent qw(EnsEMBL::Web::JobDispatcher);

my $ENDPOINT = 'http://www.ebi.ac.uk/Tools/services/rest/wublast';

sub dispatch_job {
  my ($self, $ticket_type, $job_data) = @_;

  warn "*** dispatch_job ***";
  warn Data::Dumper::Dumper $ticket_type, $job_data;

  my $species    = $job_data->{'config'}{'species'};
  my $input_file = join '/', $job_data->{'work_dir'}, $job_data->{'sequence'}{'input_file'};
  my $sequence   = file_get_contents($input_file);

  my $args = {
    sequence => $sequence
  };

  warn "POST ARGS " . Data::Dumper::Dumper($args);
  
  my $job_id = $self->_post('run', $args)->content;  

  warn "JOB ID $job_id";

  return $job_id;
}

sub delete_jobs {
  ## Nothing needs to be done here
}

sub update_jobs {
  ## Abstract method implementation
  my ($self, $jobs) = @_;

  #warn "*** update jobs ***";

  # for (@$jobs) {
  #   my $job_data = $_->dispatcher_data;
  #   warn Data::Dumper::Dumper $job_data;
  # }
}

# webservice methods

sub _post {
  my ($self, $method, $data) = @_;
  my $response = $self->_user_agent->post($self->_uri($method), $data);
  die $response->status_line unless $response->is_success;
  return $response;
}

sub _get {
  my ($self, $method, $args) = @_;
  my $response = $self->_user_agent->get($self->_uri($method, $args));
  die $response->status_line unless $response->is_success;
  return $response;
}

sub _user_agent {
  my $self = shift;
  my $ua = LWP::UserAgent->new;
  $ua->agent($SiteDefs::SITE_NAME . ' ' . $SiteDefs::SITE_RELEASE_VERSION);
  $ua->env_proxy;
  return $ua;
}

sub _uri {
  my ($self, $method, $args) = @_;
  my $uri = URI->new("$ENDPOINT/$method");
  $uri->query_param($_, $args->{$_}) for keys %$args;
  return $uri->as_string;
}

1;
