=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::GeneTree::TreeAlignment;

use strict;

use LWP;
use XML::Simple;
use URI::Escape qw(uri_escape);
use Bio::AlignIO;
use EnsEMBL::Web::Constants;
use Bio::EnsEMBL::Compara::GeneTree;
use Data::Dumper;
use EnsEMBL::Web::TmpFile::Text; ## FIXME: this is deprecated.

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {

  my $self         = shift;
  my $hub          = $self->hub;
  my $cdb          = shift || $self->param('cdb') || 'compara';
  my $node_id      = $self->param('node') || die 'No tree node specified in parameters';
  my $seq          = $self->param('seq');
  my $text_format  = $self->param('text_format');
  my $gene         = $self->param('g') || '';
  my $genetree     = $self->param('gt') || '';
  my $database     = $hub->database($cdb);
  my $node         = $database->get_GeneTreeNodeAdaptor->fetch_node_by_node_id($node_id);
  my $num_seq      = $node->num_leaves;
  my $url          = "http://www.ebi.ac.uk/Tools/services/rest/clustalo/";
  my $result       = 0;
  my $html;
  
  if(defined($self->param('precomputed'))) {
    my $output = $self->getSequence($node, 'clustalw');
    $html .= "$output";
    $result = 1;
  } elsif(defined($self->param('jobid'))) {
    # Request has a job ID, so we need to check the job status to determine what to display
    my $job_id = $self->param('jobid');
    my $status = $self->restStatus($url, $job_id);
    if($status =~ m/^FINISHED/i) {
      my $output = $self->restResult($url, $job_id, 'aln-clustal');
	  $html .= "$output";
      $result = 1;
    } elsif($status =~ m/^RUNNING/i || $status =~ m/^CREATED/i) {
      $html .= $self->pendingText($job_id, $node_id);
    } elsif($status =~ m/^NOT_FOUND/i) {
      $html .= "<p>Job $job_id not found.  Please check the job ID and try again.</p>";
    } elsif($status =~ m/^FAILURE/i) {
      $html .= "<p>Job $job_id failed.  Please correct settings and run again.</p>";
    } elsif($status =~ m/^ERROR/) {
      $html .= "<p>An error occured getting the status of job $job_id.</p>";
    } else {
      $html .= "<p>An error occured getting the status of job $job_id.</p>";
    }
  } elsif(defined($self->param('submit'))) {
    # User has submitted form, so submit the request to REST service
    my $seq = $self->getSequence($node, 'fasta');
    my %params = (
      'email' => 'eg-webteam@ebi.ac.uk',
      'stype' => 'protein',
      'sequence' => $seq,
      'mbed' => $self->param('mbed'),
      'mbediteration' => $self->param('mbediteration'),
      'iterations' => $self->param('iterations'),
      'gtiterations' => $self->param('gtiterations'),
      'hmmiterations' => $self->param('hmmiterations')
    );
    my $job_id = $self->restRequest("$url/run/", %params);
	$html .= $self->pendingText($job_id, $node_id);
  } else {
    # Present the user input form
    $html .= qq(<p>Align all $num_seq sequences in the selected sub-tree using Clustal Omega.  The alignment may take some time to generate for larger sub-trees.</p>);
    $html .= qq(<form name="msa" method="GET" action=""><table>);
    $html .= qq(<input type="hidden" name="gt" value="$genetree" />);
    $html .= qq(<input type="hidden" name="node" value="$node_id" /><input type="hidden" name="cdb" value="$cdb" />);
    $html .= qq(<tr><td>mBed-like Clustering Guide Tree</td><td><a class="popup constant help-header _ht" href="http://www.ebi.ac.uk/Tools/msa/clustalo/help/index.html#mbed"><span class="sprite info_icon"></span></a></td><td><select name="mbed" id="mbed"> <option value="true" selected="selected">yes</option> <option value="false">no</option> </select></td></tr>);
    $html .= qq(<tr><td>mBed-like Clustering Iteration</td><td><a class="popup constant help-header _ht" href="http://www.ebi.ac.uk/Tools/msa/clustalo/help/index.html#mbediteration"><span class="sprite info_icon"></span></a></td><td><select name="mbediteration" id="mbediteration"> <option value="true" selected="selected">yes</option> <option value="false">no</option> </select></td></tr>);
    $html .= qq(<tr><td>Number of Combined Iterations</td><td><a class="popup constant help-header _ht" href="http://www.ebi.ac.uk/Tools/msa/clustalo/help/index.html#iterations"><span class="sprite info_icon"></span></a></td><td><select name="iterations" id="iterations"> <option value="0" selected="selected">default(0)</option> <option value="1">1</option> <option value="2">2</option> <option value="3">3</option> <option value="4">4</option> <option value="5">5</option> </select></td></tr>);
    $html .= qq(<tr><td>Max Guide Tree Iterations</td><td><a class="popup constant help-header _ht" href="http://www.ebi.ac.uk/Tools/msa/clustalo/help/index.html#gtiterations"><span class="sprite info_icon"></span></a></td><td><select name="gtiterations" id="gtiterations"> <option value="-1" selected="selected">default</option> <option value="0">0</option> <option value="1">1</option> <option value="2">2</option> <option value="3">3</option> <option value="4">4</option> <option value="5">5</option> </select></td></tr>);
    $html .= qq(<tr><td>Max HMM Iterations</td><td><a class="popup constant help-header _ht" href="http://www.ebi.ac.uk/Tools/msa/clustalo/help/index.html#hmmiterations"><span class="sprite info_icon"></span></a></td><td><select name="hmmiterations" id="hmmiterations"> <option value="-1" selected="selected">default</option> <option value="0">0</option> <option value="1">1</option> <option value="2">2</option> <option value="3">3</option> <option value="4">4</option> <option value="5">5</option> </select></td></tr>);
    $html .= qq(<tr><td colspan=3><input type="submit" name="submit" value="Submit" /></td></tr>);
    $html .= qq(</table></form>);
  }

  if($result == 1) {
    my $var_output;
    my $file = EnsEMBL::Web::TmpFile::Text->new(extension => 'txt', prefix => 'gene_tree');
    print $file $html;
    $file->save;
    my $temp_url = $file->URL;
    my $html_prefix = $self->tool_buttons($temp_url);
    $html = qq($html_prefix<p><pre>$html</pre></p>);
  }

  return $html;
  
}

sub getSequence {
  my ($self, $node, $out_type) = @_;
  my $align = $node->get_SimpleAlign(-APPEND_SP_SHORT_NAME => 1);
  my $seq;
  my $maio = Bio::AlignIO->new(-format => $out_type, -fh => IO::String->new($seq));
  $maio->write_aln($align);
  return $seq;
}

sub restRequest {
  my ($self, $url, %params) = @_;
  my $ua = LWP::UserAgent->new();
  $ua->agent("EBI-EnsemblGenomes (TreeAlignment) " . $ua->agent());
  $ua->env_proxy;
  my $response = $ua->post($url, Content => \%params);
  my $contentdata = $response->content();
  if ($response->is_error) {
    my $error_message = '';
	if($contentdata =~ m/<h1>([^<]+)<\/h1>/ ) { # HTML Response
	  $error_message = $1;
	} elsif($contentdata =~ m/<description>([^<]+)<\/description>/) { # XML Response
	  $error_message = $1;
	}
	die 'Submission of job failed with HTTP status: ' . $response->code . ' ' . $response->message . '  ' . $error_message;
  }
  return $response->content();
}

sub restStatus {
  my ($self, $url, $job_id) = @_;
  my $status = 'UNKNOWN';
  my $ua = LWP::UserAgent->new();
  $ua->agent("EBI-EnsemblGenomes (TreeAlignment) " . $ua->agent());
  $ua->env_proxy;
  my $response = $ua->get("$url/status/$job_id");
  return $response->content();
}

sub restResult {
  my ($self, $url, $job_id, $type) = @_;
  my $status = 'UNKNOWN';
  my $ua = LWP::UserAgent->new();
  $ua->agent("EBI-EnsemblGenomes (TreeAlignment) " . $ua->agent());
  $ua->env_proxy;
  my $response = $ua->get("$url/result/$job_id/$type");
  my $output = $response->content();
  return $output;
}

sub pendingText {
  my ($self, $job_id, $node_id) = @_;
  my $hub = $self->hub;
  my $html;
  my $target_url = $hub->url ({
    action   => 'Compara_Tree/Tree_Alignment',
    type     => 'GeneTree',
    cdb      => $self->param('cdb'),
    node     => uri_escape($node_id),
    jobid    => uri_escape($job_id)
  });
  $html .= qq(<p>Submitted as job number $job_id</p>);
  $html .= qq(<p>Status: Running<br /><a id="RefreshAlign" href="$target_url">Status will update automatically every 30 seconds, click to check now</a></p>);
  $html .= qq(<p>To access the alignment results at a later time (up to one week from job submission), use the following address: <input type="text" value="$SiteDefs::ENSEMBL_BASE_URL$target_url" style="width:350px" /></p>);
  $html .= qq(<p class="spinner"></p>);
  $html .= "<script>window.setTimeout(function(){ document.getElementById(\"RefreshAlign\").click(); }, 30000);</script>";
  return $html;
}

sub tool_buttons {
  my ($self, $url) = @_;
  my $hub  = $self->hub;
  my $html = sprintf('<div class="other_tool"><p><a class="seq_export export" href="%s">Download alignment</a></p></div>', $url);
}

1;
