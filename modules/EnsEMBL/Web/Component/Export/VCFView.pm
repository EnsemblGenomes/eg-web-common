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

package EnsEMBL::Web::Component::Export::VCFView;

use base 'EnsEMBL::Web::Component::Export';
use Data::Dumper;

sub _init {
    my $self = shift;
    $self->cacheable(0);
    $self->ajaxable(1);
}

sub content {
  my $self  = shift;
  my $hub   = $self->hub;
  my $pos   = $hub->param('pos');  
  my $vcf   = $hub->param('vcf');
  my $object = $self->object;
  my $species  = $object->{data}->{'_referer'}->{ENSEMBL_SPECIES};

  return qq{ <div class="ajax genotype_panel">
             <input type="hidden"  class="ajax_load" name="genotype$pos" value="/genotype?pos=$pos;vcf=$vcf;sp=$species;" />
             </div>};

}

1;
