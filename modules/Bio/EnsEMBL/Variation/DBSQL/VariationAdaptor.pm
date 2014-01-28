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

package Bio::EnsEMBL::Variation::DBSQL::VariationAdaptor;

#
# Returns all the studies for variation.
# INPUT PARAMS: var_id
# RETURNS: Arrayref of study ids for the current variation id
#

sub get_study_ids_by_var_id {
    my ($self, $var_id) = @_;

    my $study_id;
    my $sth = $self->prepare(qq{
      SELECT study_id 
        FROM study_variation 
        WHERE variation_id = $var_id
    });
    $sth->execute();
    $sth->bind_columns(\$study_id);

    my @sources;
    while ($sth->fetch()){
      push @sources, $study_id
    }
    $sth->finish();
    return \@sources;
}

1;
