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

package EnsEMBL::Web::JobDispatcher::WuBlast;

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);
use HTTP::Request;
use JSON qw(to_json);
use LWP::UserAgent;
use XML::Simple;
use URI;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents file_put_contents);
use EnsEMBL::Web::Parsers::WuBlast;

use parent qw(EnsEMBL::Web::JobDispatcher);

my $DEBUG = 1;

sub _endpoint { 'http://www.ebi.ac.uk/Tools/services/rest/wublast' };

sub dispatch_job {
  my ($self, $ticket_type, $job_data) = @_;

  $DEBUG && warn "DISPATCH JOB DATA " . Dumper $job_data;

  my $species    = $job_data->{'config'}{'species'};
  my $input_file = join '/', $job_data->{'work_dir'}, $job_data->{'sequence'}{'input_file'};
  my $sequence   = join '', file_get_contents($input_file);

  my $args = {
    email    => $SiteDefs::ENSEMBL_SERVERADMIN,
    title    => $job_data->{ticket_name},
    program  => $job_data->{program},
    stype    => $job_data->{db_type},
    database => $job_data->{source_file},
    sequence => $sequence,
    %{ $job_data->{configs} }  
  };
  
  my $job_ref = $self->_post('run', $args)->content;  

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

      # fetch and store the text output
      my $output_file = $job_data->{work_dir} . '/blast';
      my $text        = $self->_get('result', [ $job_ref, 'out' ])->content;
      file_put_contents($output_file . '.out', $text);

      # fetch, store, and parse the XML
      my $xml = $self->_get('result', [ $job_ref, 'xml' ])->content;
      file_put_contents($output_file . '.xml', $xml);

      my $parser   = EnsEMBL::Web::Parsers::WuBlast->new($self->hub);
      my $hits     = $parser->parse_xml($xml, $job_data->{species}, $job_data->{source});
      my $orm_hits = [ map { {result_data => _to_ensorm_datastructure_string($_ || {})} } @$hits ];
      
      $job->result($orm_hits);
      $job->status('done');
      $job->dispatcher_status('done');      

    } elsif ($status =~ '^FAILED|NOT_FOUND$') {
      
      # fatal
      $job->status('awaiting_user_response');
      $job->dispatcher_status('failed');

      $job->job_message([{
        'display_message' => $self->default_error_message,
        'exception'       => {'exception' => $status},
        'fatal'           => 1
      }]);

    } elsif ($status eq 'ERROR') {
      
      # couldn't check status
      #$job->status('awaiting_dispatcher_response');
      #$job->dispatcher_status('running');

      $job->job_message([{
        'display_message' => 'Error while trying to check job status',
        'fatal'           => 0
      }]);

    }

    $job->save('changes_only' => 1);
  }
}

## Harpreet says ORM should do the stringification itself and we don't need this sub.
## Need to ask him how to do it when he gets back from holidays.
sub _to_ensorm_datastructure_string {
  ## @private
  ## @function
  ## Returns a string representation of an object as it should go in the db
  ## Follows the ORM::EnsEMBL's way to save objects in DataStructure column types (see ORM::EnsEMBL::Rose::CustomColumnValue::DataStructure::_recursive_unbless)
  my ($obj, $_flag) = @_;

  my $datastructure;

  if (ref $obj) {

    $datastructure = blessed $obj ? [ '_ensorm_blessed_object', ref $obj ] : [];

    if (UNIVERSAL::isa($obj, 'HASH')) {
      push @$datastructure, { map _to_ensorm_datastructure_string($_, 1), %$obj };
    } elsif (UNIVERSAL::isa($obj, 'ARRAY')) {
      push @$datastructure, [ map _to_ensorm_datastructure_string($_, 1), @$obj ];
    } else { # scalar ref
      push @$datastructure, $$obj;
    }

    $datastructure = $datastructure->[0] if @$datastructure == 1;

  } else {
    $datastructure = $obj;
  }

  return $_flag ? $datastructure : Data::Dumper->new([ $datastructure ])->Sortkeys(1)->Useqq(1)->Terse(1)->Indent(0)->Dump;
}

sub _post {
  my ($self, $method, $data) = @_;
  my $uri = $self->_uri($method);
  
  $DEBUG && warn "POST URI $uri";
  $DEBUG && warn "POST DATA " . Dumper($data);

  my $response = $self->_user_agent->post($uri, $data);

  #$DEBUG && warn "RESPONSE " . Dumper($response);

  unless ($response->is_success) {
    my ($error) = $response->content =~ m/<description>([^<]+)<\/description>/;   
    die sprintf 'BLAST REST error: %s (%s)', $response->status_line, $error;
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
  return join '/', $self->_endpoint, $method, @$args;
}

1;
