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

package EnsEMBL::Web::JobDispatcher::NcbiBlast;

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);
use HTTP::Request;
use JSON qw(to_json);
use LWP::UserAgent;
use XML::Simple;
use URI;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents file_put_contents);
use EnsEMBL::Web::Parsers::Blast;

use parent qw(EnsEMBL::Web::JobDispatcher);

my $DEBUG = 1;

sub dispatch_job {
  my ($self, $ticket_type, $job_data) = @_;

  $DEBUG && warn "DISPATCH JOB DATA " . Dumper $job_data;

  my $species    = $job_data->{'config'}{'species'};
  my $input_file = join '/', $job_data->{'work_dir'}, $job_data->{'sequence'}{'input_file'};
  my $sequence   = join '', file_get_contents($input_file);
  my $stype      = {dna => 'dna', peptide => 'protein'}->{$job_data->{query_type}};

  my $args = {
    email    => $SiteDefs::ENSEMBL_SERVERADMIN,
    title    => $job_data->{ticket_name},
    program  => $job_data->{program},
    stype    => $stype,
    database => $job_data->{source_file},
    sequence => $sequence,
    %{ $job_data->{configs} }  
  };
  
  # fetch (retry on fail) 
  my $job_ref;
  
  for (1..3) {
    my $response = $self->_post('run', $args);
    last if $response and $job_ref = $response->content;
  }

  if (!$job_ref) {
    throw exception('InputError', 'There was a problem contacting the BLAST service, please try again later');
  }

  $DEBUG && warn "CREATED JOB REF $job_ref";

  return $job_ref;
}

sub delete_jobs {
  ## Nothing needs to be done here
}

sub update_jobs {
  my ($self, $jobs) = @_;

  for my $job (@$jobs) {
    my $job_ref  = $job->dispatcher_reference;
    my $job_data = $job->dispatcher_data;
    my $status   = $self->_get('status', [ $job_ref ])->content;

    if ($status eq 'RUNNING') {
      
      $job->dispatcher_status('running') if $job->dispatcher_status ne 'running';
    
    } elsif ($status eq 'FINISHED') {

      $DEBUG && warn "UPDATE JOB DATA " . Dumper $job_data;

      # fetch and process the output
      my $out_file = $job_data->{work_dir} . '/blast.out';
      my $xml_file = $job_data->{work_dir} . '/blast.xml';

      my $text = $self->_get('result', [ $job_ref, 'out' ])->content;
      file_put_contents($out_file, $text);

      my $xml = $self->_get('result', [ $job_ref, 'xml' ])->content;
      file_put_contents($xml_file, $text);

      my $parser   = EnsEMBL::Web::Parsers::Blast->new($self->hub);
      my $hits     = $parser->parse_xml($xml, $job_data->{species}, $job_data->{source});
      my $orm_hits = [ map { {result_data => $_ || {}} } @$hits ];
      
      $job->result($orm_hits);
      $job->status('done');
      $job->dispatcher_status('done');      

    } elsif ($status =~ '^FAILED|FAILURE$') {
      
      my $error = $self->_get('result', [ $job_ref, 'error' ])->content; 
      $self->_fatal_job($job, $error, $self->default_error_message);
    
    } elsif ($status eq 'NOT_FOUND') {
      
      $self->_fatal_job($job, $status, $self->default_error_message);

    } elsif ($status eq 'ERROR') {
      
      $job->job_message([{
        'display_message' => 'Error while trying to check job status',
        'fatal'           => 0
      }]);

    }

    $job->save('changes_only' => 1);
  }
}

sub _fatal_job {
  my ($self, $job, $exception, $message) = @_;
  $job->status('awaiting_user_response');
  $job->dispatcher_status('failed');
  $job->job_message([{
    'display_message' => $message,
    'exception'       => {'exception' => $exception},
    'fatal'           => 1
  }]);
}

sub _post {
  my ($self, $method, $data) = @_;
  my $uri = $self->_uri($method);
  
  $DEBUG && warn "POST URI $uri";
  $DEBUG && warn "POST DATA " . Dumper($data);

  my $response = $self->_user_agent->post($uri, $data);

  unless ($response->is_success) {
    $DEBUG && warn "RESPONSE " . Dumper($response);
    my ($error) = $response->content =~ m/<description>([^<]+)<\/description>/;   
    warn sprintf 'BLAST REST error: %s (%s)', $response->status_line, $error;
    return undef;
  }
  return $response;
}

sub _get {
  my ($self, $method, $args) = @_;
  my $uri = $self->_uri($method, $args);

  $DEBUG && warn "GET URI $uri";

  my $response = $self->_user_agent->get($uri);
  
  #debug("RESPONSE", Dumper($response));
  
  #die $response->status_line unless $response->is_success;  ## don't die or it upsets the BLAST interface
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
  $args ||= [];
  return join '/', $SiteDefs::NCBIBLAST_REST_ENDPOINT, $method, @$args;
}

1;
