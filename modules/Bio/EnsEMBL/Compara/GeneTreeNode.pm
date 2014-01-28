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

package Bio::EnsEMBL::Compara::GeneTreeNode;

#EG: history_warn method
=head2 history_warn

  Arg[1]     : [optional] string
  Example    : $tree->history_warn("The former Gene Tree EBGT00070000031985 has been replaced by Gene Tree EBGT00650000039016 (below).");
  Description: getter/setter for the warning msg; warning message is added to the top of the page to let the user know if an old GeneTree stable_ids is mapped to new GeneTree stable_ids
  Returntype : string

=cut

sub history_warn {
    my ($self, $history_warn) = @_;

    if (defined($history_warn)) {
	$self->{history_warn} = $history_warn;
    }
    return $self->{history_warn};
}


1;

