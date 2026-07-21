=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2025] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Utils::Compara;

use strict;


sub _query_compara_alignments {
  my ($dbh) = @_;

  my $rows = $dbh->selectall_arrayref("
    SELECT ml.type,
           gd1.name AS gd1_name,
           gd2.name AS gd2_name,
           mlss.method_link_species_set_id,
           mlsst_blocks.value AS num_blocks
    FROM method_link ml
         JOIN method_link_species_set mlss
           USING (method_link_id)
         JOIN species_set_header ssh
           USING (species_set_id)
         JOIN species_set ss1
           ON ss1.species_set_id = ssh.species_set_id
         JOIN genome_db gd1
           ON gd1.genome_db_id = ss1.genome_db_id
         JOIN species_set ss2
           ON ss2.species_set_id = ssh.species_set_id
         JOIN genome_db gd2
           ON gd2.genome_db_id = ss2.genome_db_id
         LEFT JOIN method_link_species_set_tag mlsst_blocks
           ON mlsst_blocks.method_link_species_set_id = mlss.method_link_species_set_id
           AND mlsst_blocks.tag = 'num_blocks'
         WHERE
           ml.type IN ('SYNTENY', 'TRANSLATED_BLAT_NET', 'BLASTZ_NET', 'LASTZ_NET', 'POLYPLOID', 'CACTUS_HAL_PW', 'ATAC')
           AND (ssh.size = 1 OR gd1.genome_db_id < gd2.genome_db_id)
           ORDER BY gd1.name, gd2.name
  ", { Slice => {} });

  my $data = {};

  if(scalar(@$rows)){
    foreach my $row (@$rows){
      $data->{$row->{'gd1_name'}}->{align}->{$row->{'gd2_name'}}->{$row->{'type'}} = [$row->{'method_link_species_set_id'},  $row->{'num_blocks'} ? 1 : 0];
      if($row->{'gd2_name'} ne $row->{'gd1_name'}){
        $data->{$row->{'gd2_name'}}->{align}->{$row->{'gd1_name'}}->{$row->{'type'}} = [$row->{'method_link_species_set_id'},  $row->{'num_blocks'} ? 1 : 0];
      }
    }
  }

  return $data;
}


1;
