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

package EnsEMBL::Web::Component::Gene::FamilyProteins;

### Displays information about all peptides belonging to a protein family

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Gene);
use EnsEMBL::Web::Constants;
use EnsEMBL::Web::Document::Table;

# Take care of oryzas
sub content_ensembl {
  my $self = shift;
  my $cdb = shift || $self->object->param('cdb') || 'compara';
  
  my $object = $self->object;
  my $species = $object->species;
  my $family = $object->create_family($object->param('family'), $cdb);
  return '' unless $family;
  my $html;
  
  ## Ensembl proteins
  my %data = ();
  my $count = 0;

  my $member_skipped_count   = 0;
  my @member_skipped_species = ();

  my @genomedbs = grep { defined $_ }  @{ $family->get_all_GenomeDBs_by_member_source_name('ENSEMBLPEP') };
  foreach my $genome (@genomedbs) {
    my @peptides = map { $_->[0]->stable_id } @{ $family->get_Member_Attribute_by_source_GenomeDB('ENSEMBLPEP', $genome) || [] };
    $data{$genome->name} = \@peptides;
    $count += scalar(@peptides);
  }

  my $sitename = $object->species_defs->ENSEMBL_SITETYPE;
  $html .= "<h3>$sitename proteins in this family</h3>";
  if( $count > 0 ) {
    my $ens_table = new EnsEMBL::Web::Document::Table( [], [], {'margin' => '1em 0px'} );
    $ens_table->add_columns(
      {'key' => 'species',   'title' => 'Species',  'width' => '20%', 'align' => 'left'},
      {'key' => 'peptides', 'title' => 'Proteins', 'width' => '80%', 'align' => 'left'},
    );

    foreach my $genome (sort {$a->name cmp $b->name} @genomedbs ){

      my $species_key = $genome->name;
      my $display_species = $object->species_defs->species_label($genome->name);      

      $species_key = 'Oryza_indica' if ($display_species =~ /Indica/i);
      $species_key = 'Oryza_sativa' if ($display_species =~ /Japonica/i);

      unless( $object->param( "species_".lc($species_key) ) eq 'yes' ) {
        push @member_skipped_species, $display_species;
        $member_skipped_count += @{$data{$species_key}};
        next;
      }

      my $row = {};
      $row->{'species'} = $display_species;
      $row->{'peptides'} = '<dl class="long_id_list">';
      next unless $data{$species_key};
      foreach ( sort @{$data{$species_key}} ) {
        $row->{'peptides'} .= sprintf (qq(<dt><a href="%s/Transcript/ProteinSummary?peptide=%s">%s</a> [<a href="%s/Location/View?peptide=%s">location</a>]</dt>), $object->species_defs->species_path($species_key), $_, $_, $object->species_defs->species_path($species_key), $_);
      }
      $row->{'peptides'} .= '</dl>';
      $ens_table->add_row( $row );
    }
    $html .= $ens_table->render;
  }
  else {
    $html .= "<p>No proteins from this family were found in any other $sitename species</p>";
  }

  if( $member_skipped_count ) {
    $html .= $self->_warning( 'Members hidden by configuration', sprintf '
  <p>
    %d members not shown in the table above from the following species: %s. Use the "<strong>Configure this page</strong>" on the left to show them.
  </p>%s', $member_skipped_count, join (', ',map { "<i>$_</i>" } sort @member_skipped_species )
    )
  }

  return $html;
}

1;
