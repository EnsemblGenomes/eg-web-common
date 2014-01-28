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

package EnsEMBL::Web::Component::UserData::SliceFeedback;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
    my $self = shift;
    $self->cacheable( 0 );
    $self->ajaxable(  0 );
}

sub caption {
    my $self = shift;
    return 'File generated';
}

sub content {
    my $self = shift;

    my $form = EnsEMBL::Web::Form->new('slicer_feedback', '', 'post');

#    my $url = $object->species_path($object->data_species).'/UserData/SelectSlice';

#    my $form = $self->modal_form('vcf_feedback', $url, {'method' => 'post', 'wizard' => 1, 'backtrack' => 1, 'label' => 'Download' });

    my $nm = $self->hub->param('newname');
    my $fsize = $self->hub->param('newsize');
    my $url = "/tmp/slicer/$nm";

    my $ftype = '';

    if ($nm =~ /\.(bam|vcf)(\.gz)?$/) {
	$ftype = uc($1);
    }

    my $region = $self->hub->param('region');
    my $fname = $SiteDefs::ENSEMBL_SERVERROOT.'/tmp/slicer/'.$nm;	  

    
    my ($head, $cnt);

    if ($ftype eq 'BAM') {
	my $header_command = "samtools view $fname -H ";
	warn "CMD 2: $header_command\n";

	my $body_command = "samtools view $fname $region | head -5 | egrep -v Fetch ";
	warn "CMD 3: $body_command\n";

	$head = `$header_command`;

	$cnt =  `$body_command`;
    } else {
	my $cmd1 = "tabix -f -p vcf $fname ";
	warn "CMD 1: $cmd1\n";
	`$cmd1`;

	my $header_command = "tabix -h $fname NonExistant";
	warn "CMD 2: $header_command\n";

	my $body_command = "tabix $fname $region | head -5";
	warn "CMD 3: $body_command\n";

	$head = `$header_command`;

	$cnt =  `$body_command`;
    }
    
   
    $form->add_element(
		       type  => 'Information',
		       value => qq(Thank you - your $ftype file [<a href="$url">$nm</a>] [Size: $fsize] has been generated.<br /> Right click  on the file name and choose "Save link as .." from the menu <br /> 
				   <BR />
				   <h3> Preview </h3>
				   <textarea cols="80" rows="10" wrap="off" readonly="yes">
$head
			   
$cnt
				   </textarea>
				   <br/><br/>

				   ),
		       );

    
    return $form->render;
}

1;
