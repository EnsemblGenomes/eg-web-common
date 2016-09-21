
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

package EnsEMBL::Web::Configuration::Gene;
use Data::Dumper;

sub modify_tree {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species      = $hub->species;
  my $species_defs = $hub->species_defs;
  my $object       = $self->object;
  my $summary      = $self->get_node('Summary');


  $self->delete_node('Family'); # delete protein family page

  my $sequence = $self->get_node('Sequence');
  my $gene_families = $self->create_node('Gene_families', 'Gene families',
    [qw( 
      selector     EnsEMBL::Web::Component::Gene::GeneFamilySelector
      genefamilies EnsEMBL::Web::Component::Gene::GeneFamilies 
      )],
    { 'availability' => 'gene database:compara family', 'concise' => 'Gene families' }
  );
  $self->create_node( 'Gene_families/SaveFilter', '',
    [], { 'availability' => 'gene database:compara', 'no_menu_entry' => 1,
    'command' => 'EnsEMBL::Web::Command::GeneFamily::SaveFilter'}
  );
  $self->create_node( 'Gene_families/Sequence', '',
    [qw( alignment EnsEMBL::Web::Component::Gene::GeneFamilySeq )],
    { 'availability' => 'gene database:compara', 'no_menu_entry' => 1 }
  );

  $sequence->after($gene_families);


  return unless ($self->object || $hub->param('g'));

  my $gene_adaptor = $hub->get_adaptor('get_GeneAdaptor', 'core', $species);
  my $gene = $self->object ? $self->object->gene : $gene_adaptor->fetch_by_stable_id($hub->param('g'));

  return if ref $gene eq 'Bio::EnsEMBL::ArchiveStableId';

  my $cdb_name = $self->hub->species_defs->COMPARA_DB_NAME || 'Comparative Genomics';

  my $compara_menu = $self->get_node('Compara');
  $compara_menu->set('caption', $cdb_name);

  my $genetree = $self->get_node('Compara_Tree');
  $genetree->set(
    'components',
    [
      qw(
        tree_summary  EnsEMBL::Web::Component::Gene::ComparaTreeSummary
        image EnsEMBL::Web::Component::Gene::ComparaTree
        )
    ]
  );

  # homoeologues for polyploids

  if ($species_defs->POLYPLOIDY) {
    $self->get_node('Compara_Paralog')->after(
      $self->create_node(
        'Compara_Homoeolog',
        'Homoeologues',
        [
          qw(
            paralogues EnsEMBL::Web::Component::Gene::ComparaHomoeologs
            )
        ],
        {'availability' => 'gene database:compara core has_homoeologs', 'concise' => 'Homoeologues'}
      ),
      $self->create_node(
        'Compara_Homoeolog/Alignment',
        'Homoeologue alignment',
        [
          qw(
            alignment EnsEMBL::Web::Component::Gene::HomologAlignment
            )
        ],
        {'availability' => 'gene database:compara core has_homoeologs', 'no_menu_entry' => 1}
      )
    );
  }

##----------------------------------------------------------------------
## Pan Compara menu:
  my $pancompara_menu = $self->create_node('PanCompara', 'Pan-taxonomic Compara', [qw(button_panel EnsEMBL::Web::Component::Gene::PanCompara_Portal)], {'availability' => 'gene database:compara_pan_ensembl core'});

  my $tree_node = $self->create_node(
    'Compara_Tree/pan_compara',
    "Gene Tree",
    [
      qw(
        tree_summary EnsEMBL::Web::Component::Gene::ComparaTreeSummary
        image EnsEMBL::Web::Component::Gene::ComparaTree
        )
    ],
    {'availability' => 'gene database:compara_pan_ensembl core has_gene_tree_pan'}
  );
  $pancompara_menu->append($tree_node);

  my $ol_node = $self->create_node(
    'Compara_Ortholog/pan_compara',
    "Orthologues",
    [qw(orthologues EnsEMBL::Web::Component::Gene::ComparaOrthologs)],
    {
      'availability' => 'gene database:compara_pan_ensembl core has_orthologs_pan',
      'concise'      => 'Orthologues'
    }
  );

  $ol_node->append(
    $self->create_subnode(
      'Compara_Ortholog/Alignment_pan_compara',
      'Orthologue Alignment',
      [qw(alignment EnsEMBL::Web::Component::Gene::HomologAlignment)],
      {
        'availability'  => 'gene database:compara_pan_ensembl core',
        'no_menu_entry' => 1
      }
    )
  );

  for (qw(Ortholog Paralog Homoeolog)) {
    $ol_node->append($self->create_subnode("Compara_$_/PepSequence", "${_}ue Sequences", [qw( alignment EnsEMBL::Web::Component::Gene::HomologSeq )], {'availability' => 'gene database:compara core has_' . lc($_) . 's', 'no_menu_entry' => 1}));
  }

  $pancompara_menu->append($ol_node);

  $compara_menu->after($pancompara_menu);

  $compara_menu->before( $self->create_node( 'Literature', 'Literature',
    [qw(literature EnsEMBL::Web::Component::Gene::Literature)],
    { 'availability' => 'gene' }
  ));
  
}

1;
