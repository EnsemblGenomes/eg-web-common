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
  my $self = shift;
  my $hub = $self->hub;
  my $species = $hub->species;
  my $species_defs = $hub->species_defs;
  my $object = $self->object;
  my $summary = $self->get_node('Summary');

#  if ($species_defs->POLYPLOIDY) {
#    $summary->set('components', [qw(
#      gene_summary  EnsEMBL::Web::Component::Gene::GeneSummary
#      navbar        EnsEMBL::Web::Component::ViewNav
#      navbar        EnsEMBL::Web::Component::PolyploidNav
#      transcripts   EnsEMBL::Web::Component::Gene::TranscriptsImage
#    )]);
#  }

#  my $splice = $self->get_node('Splice');
#  $splice->set('components', [qw( image EnsEMBL::Web::Component::Gene::GeneSpliceImageNew )]);

  return unless ($self->object || $hub->param('g'));

  my $gene_adaptor = $hub->get_adaptor('get_GeneAdaptor', 'core', $species);
  my $gene   = $self->object ? $self->object->gene : $gene_adaptor->fetch_by_stable_id($hub->param('g'));  

  return if ref $gene eq 'Bio::EnsEMBL::ArchiveStableId';

  my @transcripts  = sort { $a->start <=> $b->start } @{ $gene->get_all_Transcripts || [] };
  my $transcript   = @transcripts > 0 ? $transcripts[0] : undef;

  my $region = $hub->param('r');
  my ($reg_name, $start, $end) = $region =~ /(.+?):(\d+)-(\d+)/ ? $region =~ /(.+?):(\d+)-(\d+)/ : (undef, undef, undef);

  if ($transcript) {
    my @exons        = sort {$a->start <=> $b->start} @{ $transcript->get_all_Exons || [] };
    if (@exons > 0) {
      if (defined( $transcript->coding_region_start ) && defined( $transcript->coding_region_end) ) {
        my $cover_next_e = 0;
        foreach my $e (@exons) {
	  next if $e->start <= $transcript->coding_region_start && $e->end <= $transcript->coding_region_start;
          if (!$cover_next_e) {
            $start = $e->start <= $transcript->coding_region_start ? $transcript->coding_region_start : $e->start;
            $end   = $e->end   >= $transcript->coding_region_end   ? $transcript->coding_region_end   : $e->end;
            if (($end > $start) && ($end - $start + 1 < 200)) {
	      $cover_next_e = 1;
            } 
 	  } else {
            $end   = $e->end   >= $transcript->coding_region_end   ? $transcript->coding_region_end   : $e->end;
            $cover_next_e = 0 unless ($end - $start + 1 < 200);
          }  
          last unless $cover_next_e;
        }
      } else {
        my $exon = $exons[0];
        ($start, $end) = ($exon->start, $exon->end); 
      }
    }
  }

  my $evidence_node = $self->get_node('Evidence');
  $evidence_node->set('caption', 'Supporting evidence ([[counts::gene_supporting_evidence]])');
  $evidence_node->set('availability', 'gene has_gene_supporting_evidence');

  my $compara_menu  = $self->get_node('Compara');
  my $genetree = $self->get_node('Compara_Tree');
 
  $genetree->set('components', [qw(
    tree_summary  EnsEMBL::Web::Component::Gene::ComparaTreeSummary
    image EnsEMBL::Web::Component::Gene::ComparaTree
		   )
		]);


  # Graphical gene alignment:
  my $compara_align = $self->get_node('Compara_Alignments');
  $compara_align->set('caption', 'Genomic alignments (text)');
  my $compara_align_image = $self->create_node('Compara_Alignments/Image', 'Genomic alignments (image)',
    [qw(
      selector EnsEMBL::Web::Component::Compara_AlignSliceSelector
      bottom   EnsEMBL::Web::Component::Gene::Compara_AlignSliceBottom
    )],
    { 'availability' => 'gene database:compara core has_alignments' }
  );
  $compara_menu->append($compara_align_image);
  $compara_align->before($compara_align_image);
  #


  my $var_menu     = $self->get_node('Variation');

  my $r   = ($reg_name && $start && $end) ? $reg_name.':'.$start.'-'.$end : $gene->seq_region_name.':'.$gene->start.'-'.$gene->end;
  my $url = $hub->url({
                  type   => 'Gene',
                  action => 'Variation_Gene/Image',
                  g      => $hub->param('g') || $gene->stable_id,
                  r      => $r
  });

  my $variation_image = $self->get_node('Variation_Gene/Image');
  $variation_image->set('components', [qw( 
    imagetop EnsEMBL::Web::Component::Gene::VariationImageTop
    imagenav EnsEMBL::Web::Component::Gene::VariationImageNav
    image EnsEMBL::Web::Component::Gene::VariationImage )
				     ]);
  $variation_image->set('availability', 'gene database:variation not_patch');
  $variation_image->set('url' =>  $url);

  $var_menu->append($variation_image);

  my $cdb_name = $self->hub->species_defs->COMPARA_DB_NAME || 'Comparative Genomics';

  $compara_menu->set('caption', $cdb_name);
  
  
  # homoeologues for polyploids
  
  if ($species_defs->POLYPLOIDY) {
    $self->get_node('Compara_Paralog')->after( 
      $self->create_node('Compara_Homoeolog', 'Homoeologues ([[counts::homoeologs]])',
        [qw(
          paralogues EnsEMBL::Web::Component::Gene::ComparaHomoeologs
        )],
        { 'availability' => 'gene database:compara core has_homoeologs', 'concise' => 'Homoeologues' }
      ),
      $self->create_node('Compara_Homoeolog/Alignment', 'Homoeologue alignment',
        [qw( 
          alignment EnsEMBL::Web::Component::Gene::HomologAlignment 
        )],
        { 'availability'  => 'gene database:compara core has_homoeologs', 'no_menu_entry' => 1 }
      )
    );
  }
  
  
##----------------------------------------------------------------------
## Compara menu: alignments/orthologs/paralogs/trees
  my $pancompara_menu = $self->create_node( 'PanCompara', 'Pan-taxonomic Compara',
    [qw(button_panel EnsEMBL::Web::Component::Gene::PanCompara_Portal)],
      {'availability' => 'gene database:compara_pan_ensembl core'}
  );


## Compara tree

  my $tree_node = $self->create_node(
    'Compara_Tree/pan_compara', "Gene Tree (image)",
   #[qw(image        EnsEMBL::Web::Component::Gene::ComparaTree
    [qw(
      tree_summary EnsEMBL::Web::Component::Gene::ComparaTreeSummary
      image EnsEMBL::Web::Component::Gene::ComparaTree
    )],
    { 'availability' => 'gene database:compara_pan_ensembl core has_gene_tree_pan' }
  );
  $tree_node->append( $self->create_subnode(
    'Compara_Tree/Text_pan_compara', "Gene Tree (text)",
    [qw(treetext        EnsEMBL::Web::Component::Gene::ComparaTree/text_pan_compara)],
    { 'availability' => 'gene database:compara_pan_ensembl core has_gene_tree_pan' }
  ));

  $tree_node->append( $self->create_subnode(
    'Compara_Tree/Align_pan_compara',       "Gene Tree (alignment)",
    [qw(treealign      EnsEMBL::Web::Component::Gene::ComparaTree/align_pan_compara)],
    { 'availability' => 'gene database:compara_pan_ensembl core has_gene_tree_pan' }
  ));
  $pancompara_menu->append( $tree_node );


  my $ol_node = $self->create_node(
    'Compara_Ortholog/pan_compara',   "Orthologues ([[counts::orthologs_pan]])",
    [qw(orthologues EnsEMBL::Web::Component::Gene::ComparaOrthologs)],
    { 'availability' => 'gene database:compara_pan_ensembl core has_orthologs_pan',
      'concise'      => 'Orthologues' }
  );
  
  $ol_node->append( $self->create_subnode(
    'Compara_Ortholog/Alignment_pan_compara', 'Orthologue Alignment',
    [qw(alignment EnsEMBL::Web::Component::Gene::HomologAlignment)],
    { 'availability'  => 'gene database:compara_pan_ensembl core',
      'no_menu_entry' => 1 }
  ));

  $ol_node->append($self->create_subnode('Compara_Ortholog/PepSequence', 'Orthologue Sequences',
    [qw( alignment EnsEMBL::Web::Component::Gene::HomologSeq )],
					 { 'availability'  => 'gene database:compara core has_orthologs', 'no_menu_entry' => 1 }
					 ));

  $pancompara_menu->append($ol_node);

#  my $pl_node = $self->create_node(
#    'Compara_Paralog/pan_compara',    "Paralogues ([[counts::paralogs_pan]])",
#    [qw(paralogues  EnsEMBL::Web::Component::Gene::ComparaParalogs)],
#    { 'availability' => 'gene database:compara_pan_ensembl core has_paralogs_pan',
#           'concise' => 'Paralogues' }
#  );
#  $pancompara_menu->append($pl_node);

#  $pl_node->append( $self->create_subnode(
#    'Compara_Paralog/Alignment_pan_compara', 'Paralog Alignment',
#    [qw(alignment EnsEMBL::Web::Component::Gene::HomologAlignment)],
#    { 'availability'  => 'gene database:compara core',
#      'no_menu_entry' => 1 }
#  ));

  my $family = $self->get_node('Family');
  $family->set('no_menu_entry', 1);
#ENSEMBL-2402 removes List of Species
# $pancompara_menu->append($self->create_node('PanComparaSpecies', 'List of species',
#   [qw(pancompara_spec  EnsEMBL::Web::Component::Info::PanComparaSpecies)],
# 				      { 'availability' => 'gene database:compara_pan_ensembl core' }
# 				      ));

### EG

  $compara_menu->after($pancompara_menu);
  
  # S4 DAS
  foreach my $logic_name (qw(S4_EXPRESSION S4_LITERATURE S4_PUBMED)) {
    if (my $source = $hub->get_das_by_logic_name($logic_name)) {
      $compara_menu->before($self->create_node("das/$logic_name", $logic_name,
        [$source->renderer, "EnsEMBL::Web::Component::Gene::" . $source->renderer], {
          availability => 'gene', 
          concise      => $source->caption, 
          caption      => $source->caption, 
          full_caption => $source->label
        }
      ));
    }
  }


  # get all ontologies mapped to this species
  my $go_menu = $self->create_submenu('GO', 'Ontology');
  my %olist = map {$_ => 1} @{$species_defs->DISPLAY_ONTOLOGIES ||[]};

  if (%olist) {
     # get all ontologies available in the ontology db
     my %clusters = $species_defs->multiX('ONTOLOGIES');

     # get all the clusters that can generate a graph
     my @clist =  grep { $olist{ $clusters{$_}->{db} }} sort {$clusters{$a}->{db} cmp $clusters{$b}->{db}} keys %clusters; # Find if this ontology has been loaded into ontology db

     foreach my $oid (@clist) {
	 my $cluster = $clusters{$oid};
	 my $dbname = $cluster->{db};

# special case: there are many ontologies loaded into PBO - we only want to display gene_ex
	 if ($dbname eq 'PBO') {
	     next unless $oid eq 'gene_ex';
	 }

	 if ($dbname eq 'GO') {
	     $dbname = 'GO|GO_to_gene';
	 }
	 my $go_hash  = $self->object ? $object->get_ontology_chart($dbname, $cluster->{root}) : {};
	 next unless (%$go_hash);
	 my @c = grep { $go_hash->{$_}->{selected} } keys %$go_hash;
	 my $num = scalar(@c);
	 
	 my $url2 = $hub->url({
	     type    => 'Gene',
	     action  => 'Ontology/'.$oid,
	     oid     => $oid
			      });

	 (my $desc2 = "$cluster->{db}: $cluster->{description}") =~ s/_/ /g;
	 $go_menu->append($self->create_node('Ontology/'.$oid, "$desc2 ($num)",
					     [qw( go EnsEMBL::Web::Component::Gene::Ontology )],
					     { 'availability' => 'gene', 'concise' => $desc2, 'url' =>  $url2 }
			  ));
	 
     }
  }
  $compara_menu->before( $go_menu );
}

1;
