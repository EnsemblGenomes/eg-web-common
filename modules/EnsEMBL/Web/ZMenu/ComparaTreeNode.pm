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

package EnsEMBL::Web::ZMenu::ComparaTreeNode;

use strict;

use URI::Escape qw(uri_escape);
use IO::String;
use Bio::AlignIO;
use EnsEMBL::Web::TmpFile::Text;
use Data::Dumper;

use base qw(EnsEMBL::Web::ZMenu);

use previous qw(content);

sub content {
    my $self    = shift;
    $self->{'cdb'} = $_[0];
    $self->PREV::content(@_);
    
    my $comparison_view_link = $self->object->availability->{has_pairwise_alignments};
    $comparison_view_link = 0 if ($self->{'cdb'} =~ /pan/);
    @{$self->{'feature'}{'entries'}} = grep {$_->{'type'} ne 'Comparison'} @{$self->{'feature'}{'entries'}} unless $comparison_view_link;
    
}


sub build_link{
  my ($self, $component, $type, $action, $collapse) = @_;
  
  $self->{"ht"} ||= $self->hub->param('ht') || undef;
  my $action = 'Web/ComparaTree' . ($self->{'cdb'} =~ /pan/ ? '/pan_compara' : '');

  return $self->hub->url($component, {
        type     => $type,
        action   => $action,
        ht       => $self->{"ht"},
        collapse => $collapse 
  });
}





1;
