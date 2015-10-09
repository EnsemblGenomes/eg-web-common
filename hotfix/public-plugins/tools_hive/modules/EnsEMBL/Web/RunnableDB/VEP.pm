=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::RunnableDB::VEP;

### Hive Process RunnableDB for VEP

use strict;
use warnings;

use parent qw(EnsEMBL::Web::RunnableDB);

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);

sub fetch_input {
  my $self = shift;

  my $code_root = $self->param_required('code_root');
  my $script_path;

  # set up absolute locations for the scripts
  for (qw(script vep_to_web_script)) {
    my $abs_location = sprintf '%s/%s', $code_root, $self->param_required($_);
    throw exception('HiveException', "Script $abs_location doesn't exist, or is not executable.") unless -x $abs_location;
    $self->param($_, $abs_location);
    $script_path = $abs_location =~ s/(\/[^\/]+$)//r if $_ eq 'script'; # script path also needs to go into perl_bin 
  }

  # set up perl bin with the required library locations
  try {
## EG - ignore eg-web folders (need to find a better way to do this...)
    my @modules   = map { -d "$code_root/$_/modules" ? "-I $code_root/$_/modules" : () } grep {$_ !~ /eg-web/}  @{list_dir_contents($code_root)};
##    
    my $perl_bin  = join ' ', $self->param_required('perl_bin'), '-I', $self->param_required('bioperl_dir'), '-I', $script_path, @modules;
    $self->param('perl_bin', $perl_bin);
  } catch {
    throw exception('HiveException', $_->message(1));
  };

  # other required params
  $self->param_required($_) for qw(work_dir config job_id cache_dir);
}

sub run {
  my $self = shift;

  my $perl_bin        = $self->param('perl_bin');
  my $script          = $self->param('script');
  my $work_dir        = $self->param('work_dir');
  my $config          = $self->param('config');
  my $options         = $self->param('script_options') || {};
  my $log_file        = "$work_dir/lsf_log.txt";
  my $plugins_path    = $self->param('plugins_path');
     $plugins_path    = $plugins_path ? $plugins_path =~ /^\// ? "-I $plugins_path" : sprintf('-I %s/%s', $self->param('code_root'), $plugins_path) : '';

  $options->{"--$_"}  = '' for qw(force quiet safe vcf tabix stats_text cache); # we need these options set on always!
  $options->{"--$_"}  = sprintf '"%s/%s"', $work_dir, delete $config->{$_} for qw(input_file output_file stats_file);
  $options->{"--$_"}  = $config->{$_} eq 'yes' ? '' : $config->{$_} for grep { defined $config->{$_} && $config->{$_} ne 'no' } keys %$config;
  $options->{"--dir"} = $self->param('cache_dir');

  # send warnings to STDERR
  $options->{"--warning_file"} = "STDERR";

  # save the result file name for later use
  $self->param('result_file', $options->{'--output_file'} =~ s/(^\")|(\"$)//rg);

  my $command   = EnsEMBL::Web::SystemCommand->new($self, "$perl_bin $plugins_path $script", $options)->execute({'log_file' => $log_file});
  my $m_type    = 'ERROR';
  my $messages  = {};
  my $max_msgs  = 10;
  my $w_count   = 0;

  for (split /(?=\n(WARNING|ERROR)\s*\:)/, "Unknown error\n".file_get_contents($log_file)) {
    if (/^(WARNING|ERROR)$/) {
      $m_type = $1;
    } else {
      $messages->{$m_type} ||= [];
      s/^\R+|\R+$//g;
      s/\R+/\n/g;
      if ($m_type eq 'WARNING') {
        if ($messages->{$m_type} && @{$messages->{$m_type}} >= $max_msgs) {
          $w_count++;
          next;
        }
        ($_) = split "\n", $_; # keep only first line for warning
      }
      push @{$messages->{$m_type}}, $_;
    }
  }

  push @{$messages->{'WARNING'}}, $w_count.' more warnings not shown' if $w_count;

  # save any warnings to the log table
  $self->tools_warning({ 'message' => $_, 'type' => 'VEPWarning' }) for @{$messages->{'WARNING'}};

  throw exception('HiveException', $messages->{'ERROR'}[-1]) if $command->error_code; # consider last error only

  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $perl_bin    = $self->param('perl_bin');
  my $script      = $self->param('vep_to_web_script');
  my $result_file = $self->param('result_file');
  my $result_web  = "$result_file.web";

  throw exception('HiveException', "Result file doesn't exist.") unless -r $result_file;

  my $command = EnsEMBL::Web::SystemCommand->new($self, "$perl_bin $script $result_file")->execute({'output_file' => $result_web, 'log_file' => "$result_web.log"});

  throw exception('HiveException', "Error reading the web results file:\n".file_get_contents("$result_web.log")) unless -r $result_web;

  my @result_keys = qw(chr start end allele_string strand variation_name consequence_type);
  my @rows        = file_get_contents($result_web, sub { chomp; my @cols = split /\t/, $_; return { map { $result_keys[$_] => $cols[$_] } 0..$#result_keys } });

  $self->save_results($job_id, {}, \@rows);

  return 1;
}

1;
