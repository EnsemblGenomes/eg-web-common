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

package EnsEMBL::Web::Command::UserData::SliceFile;

use strict;
use warnings;

use EnsEMBL::Web::Tools::Misc qw(get_url_filesize);
use base qw(EnsEMBL::Web::Command);

sub _slice_bam {
    my ($self, $url, $region) = @_;
    my $hub = $self->hub;

    my @path = split('/', $hub->param('url'));
    (my $newname = $region . '.' . $path[-1]) =~ s/\:/\./g;
    my $fname = $SiteDefs::ENSEMBL_SERVERROOT.'/tmp/slicer/'.$newname;	  
    
    my $cmd = "samtools view $url $region -h -b -o $fname";
#    my $cmd = "export TMPDIR=/tmp; samtools view $url $region -h -b > /tmp/$newname";

    warn "CMD: $cmd \n";
    
    my $rc = `$cmd`;

    warn "RC : $rc\n";

    my $cmi = "samtools index $fname";
    warn "CMi: $cmi \n";
    
    $rc = `$cmi`;
    warn "RC : $rc\n";
    
    return $newname;
}

sub _slice_vcf {
    my ($self, $url, $region) = @_;
    my $hub = $self->hub;

    my @path = split('/', $hub->param('url'));
    (my $newname = $region . '.' . $path[-1]) =~ s/\:/\./g;
    
    my $fname = $SiteDefs::ENSEMBL_SERVERROOT.'/tmp/slicer/'.$newname;	  
    my $vcf_command = "tabix $url $region -h | bgzip > $fname";
	
    warn "CMD: $vcf_command \n";
    system($vcf_command);
    return $newname;
}

sub process {
  my $self     = shift;
  my $hub      = $self->hub;
  my $session  = $hub->session;
  my $redirect = $hub->species_path($hub->data_species) . '/UserData/';
  my $name     = $hub->param('name');
  my $param    = {};
  my $ftype = '';
  my $region = $hub->param('region');

  if (!$name) {
    my @path = split('/', $hub->param('url'));
    $name = $path[-1];
  }

  if (my $url = $hub->param('url')) {
      if ($url =~ /\.(bam|vcf)(\.gz)?$/) {
	  $ftype = $1;
      }
      warn "Attach :$url : $ftype : $region\n";

      my $newname;

      if ($ftype eq 'bam') {
	  $newname = $self->_slice_bam($url, $region);
      } elsif ($ftype eq 'vcf') {
	  $newname = $self->_slice_vcf($url, $region);
      }
      
      if ($newname) {
	  $param->{region} = $region;
	  my $fname = $SiteDefs::ENSEMBL_SERVERROOT.'/tmp/slicer/'.$newname;	  
	  $param->{newsize} = -s $fname;
	  
	  $param->{'newname'} = $newname;
	  $redirect .= 'SliceFeedback';
	  
      } else {
         ## Set message in session
	  $session->add_data(
			     'type'  => 'message',
			     'code'  => 'SliceFile',
			     'message' => "Unable to open/index remote file: $url<br>Ensembl can only display sorted, indexed  files<br>Ensure you have sorted and indexed your file and that your web server is accessible to the Ensembl site",
			     function => '_error'
			     );
	  $redirect .= 'ManageData';
      }
  } else {
    $redirect .= 'SelectSlice';
    $param->{'filter_module'} = 'Data';
    $param->{'filter_code'} = 'no_vcf';
  }

  $self->ajax_redirect($redirect, $param); 
}

1;
