=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::ComparaTree;

use strict;
use warnings;

use Bio::EnsEMBL::Compara::DBSQL::XrefAssociationAdaptor;

sub content {
  my $self        = shift;
  my $cdb         = shift || $self->param('cdb') || 'compara';
  my $hub         = $self->hub;
  my $sd          = $hub->species_defs;
  my $object      = $self->object || $self->hub->core_object('gene');
  my $is_genetree = $object && $object->isa('EnsEMBL::Web::Object::GeneTree') ? 1 : 0;
  my ($gene, $member, $tree, $node, $test_tree);

  my $type   = $self->param('data_type') || $hub->type;
  my $vc = $self->viewconfig($type);

## EG  
  my $url_function = $hub->function;
##

  if ($is_genetree) {
    $tree   = $object->Obj;
    $member = undef;
  } else {
    $gene = $object;
    ($member, $tree, $node, $test_tree) = $self->get_details($cdb);
  }

  return $tree . $self->genomic_alignment_links($cdb) if $self->param('g') && !$is_genetree && !defined $member;

  my $leaves               = $tree->get_all_leaves;
  my $tree_stable_id       = $tree->tree->stable_id;
  my $highlight_gene       = $hub->param('g1');
  my $highlight_status     = $hub->get_cookie_value('gene_tree_highlighting') || 'on'; # get the the highlight switch status from the cookie
  my $highlight_ancestor   = $self->param('anc');

  # Set $highlight_gene to undefined if the highlight status is off. This is due to the module relying heavily on $highlight_gene to do the rendering based on the highlight status.
  if ($highlight_status eq 'off') {
    $highlight_gene = undef;
  }

## EG 
  my $collapsed_nodes = $self->param('collapse');
  # buggy parameter: "collapse=;" was taken to mean "collapse=none;"
  $hub->input->delete('collapse') unless $collapsed_nodes;
##

# EG add ht param
  my $image_width          = $self->image_width       || 800;
  my $colouring            = $self->param('colouring') || 'background';
  my $collapsability       = $is_genetree ? '' : ($vc->get('collapsability') || $self->param('collapsability'));
  my $clusterset_id        = $vc->get('clusterset_id') || $self->param('clusterset_id');
  my $show_exons           = $self->param('exons') eq 'on' ? 1 : 0;
  my $image_config         = $hub->get_imageconfig('genetreeview');
  my @hidden_clades        = grep { $_ =~ /^group_/ && $self->param($_) eq 'hide'     } $self->param;
  my @collapsed_clades     = grep { $_ =~ /^group_/ && $self->param($_) eq 'collapse' } $self->param;
  my @highlights           = $gene && $member ? ($gene->stable_id, $member->genome_db->dbID) : (undef, undef);
  my $hidden_genes_counter = 0;
  my $link                 = $hub->type eq 'GeneTree' ? '' : sprintf ' <a href="%s">%s</a>', $hub->url({ species => 'Multi', type => 'GeneTree', action => 'Image', gt => $tree_stable_id, __clear => 1 }), $tree_stable_id;
  my $html                 = '<input type="hidden" class="panel_type" value="ComparaTree" />';

  my (%hidden_genome_db_ids, $highlight_species, $highlight_species_name, $highlight_genome_db_id);

  my $parent      = $tree->tree->{'_supertree'};
  if (defined $parent) {

    if ($vc->get('super_tree') eq 'on' || $self->param('super_tree') eq 'on') {
      my $super_url = $self->ajax_url('sub_supertree',{ cdb => $cdb, update_panel => undef });
      $html .= qq(<div class="ajax"><input type="hidden" class="ajax_load" value="$super_url" /></div>);
    } else {
      $html .= $self->_info(
        sprintf(
          'This tree is part of a super-tree of %d trees (%d genes in total)',
          scalar @{$parent->root->get_all_leaves},
          $parent->{'_total_num_leaves'},
        ),
        'The super-tree is currently not displayed. Use the "configure page" link in the left panel to change the options'
      );
    }
  }
  if ($hub->type eq 'Gene') {
    if ($tree->tree->clusterset_id ne $clusterset_id && !$self->is_strain) {
      $html .= $self->_info('Phylogenetic model selection',
        sprintf(
          'The phylogenetic model <I>%s</I> is not available for this tree. Showing the default (consensus) tree instead.', $clusterset_id
          )
      );
    } elsif ($tree->tree->ref_root_id) {

      my $text = sprintf(
          'The tree displayed here has been built with the phylogenetic model <I>%s</I>. It has then been merged with trees built with other models to give the final tree and homologies. Data shown here may be inconsistent with the rest of the comparative analyses, especially homologies.', $clusterset_id
      );
      my $rank = $tree->tree->get_tagvalue('k_score_rank');
      my $score = $tree->tree->get_tagvalue('k_score');
      $text .= sprintf('<br/>This tree is the <b>n&deg;%d</b> closest to the final tree, with a K-distance of <b>%f</b>, as computed by <a href="http://molevol.cmima.csic.es/castresana/Ktreedist.html">Ktreedist</a>.', $rank, $score) if $rank;
      $html .= $self->_info('Phylogenetic model selection', $text);
    }
  }

  # store g1 param in a different param as $highlight_gene can be undef if highlighting is disabled
  my $gene_to_highlight = $hub->param('g1');
  my $highlight_gene_display_label;
  my $lookup = $sd->prodnames_to_urls_lookup;
  
  foreach my $this_leaf (@$leaves) {
    if ($gene_to_highlight && $this_leaf->gene_member->stable_id eq $gene_to_highlight) {
      $highlight_gene_display_label = $this_leaf->gene_member->display_label || $gene_to_highlight;
      $highlight_species            = $lookup->{$this_leaf->gene_member->genome_db->name};
      $highlight_species_name       = $this_leaf->gene_member->genome_db->display_name;
      $highlight_genome_db_id       = $this_leaf->gene_member->genome_db_id;
      last;
    }
  }
  $highlight_gene = 0 unless $highlight_species;

  # check if highlight ancestor (anc param) is available or not
  # if it isn't then there is no need for a message as there will be no g1 (highlight gene) as well
  if ($highlight_ancestor) {
    # use $highlight_gene to check if highlight is enabled or not
    # $gene_to_highlight will be used for getting info necessary to display the highlighting message
    if ($highlight_gene) {
      if ($member && $gene && $highlight_species) {
        $html .= $self->_info('Highlighted genes',
          sprintf(
            '<p>The <i>%s</i> %s gene, its paralogues, its orthologue in <i>%s</i>, and paralogues of the <i>%s</i> gene, have all been highlighted. <a href="#" class="switch_highlighting on">Click here to disable highlighting</a>.</p>',
            $sd->get_config($lookup->{$member->genome_db->name}, 'SPECIES_DISPLAY_NAME'),
            $highlight_gene_display_label,
            $sd->get_config($highlight_species, 'SPECIES_DISPLAY_NAME') || $highlight_species_name,
            $sd->get_config($highlight_species, 'SPECIES_DISPLAY_NAME') || $highlight_species_name
          )
        );
      } else {
        my $hl_member   = $object->get_compara_Member({'cdb' => $cdb, 'stable_id' => $highlight_gene, 'species' => $highlight_species});
        my $dba         = $object->database($cdb); 
        my $hl_adaptor  = $dba->get_adaptor('GeneTree') || return;
        my $hl_tree     = $hl_adaptor->fetch_all_by_Member($hl_member, -clusterset_id => $clusterset_id)->[0];
        unless ($hl_tree) {
            $hl_tree = $hl_adaptor->fetch_default_for_Member($hl_member);
        }
        my $highlight_gene_tree_link = sprintf ' <a href="%s">%s</a>', $hub->url({ species => 'Multi', type => 'GeneTree', action => 'Image', gt => $hl_tree->stable_id, g1 => $highlight_gene, __clear => 1 }), $hl_tree->stable_id;
        my $doc_link = '<a target="_blank" href="/info/genome/compara/super_trees.html">more</a>';
        $html .= $self->_warning('The requested gene is in a different Gene Tree', "<p>$highlight_gene is part of a different Gene Tree,  $highlight_gene_tree_link, 
                    than the one displayed here. Both are part of the same Super tree (find out $doc_link about Super trees)</p>");
      }
    } else {
      $html .= $self->_info('Highlighted genes', 
        sprintf(
          '<p>The <i>%s</i> %s gene and its paralogues are highlighted. <a href="#" class="switch_highlighting off">Click here to enable highlighting of %s homologues</a>.</p>',
          $sd->get_config($lookup->{$member->genome_db->name}, 'SPECIES_DISPLAY_NAME'),
          $highlight_gene_display_label,
          $sd->get_config($highlight_species, 'SPECIES_DISPLAY_NAME') || $highlight_species_name
        )
      );
    }
  }
  
  # Get all the genome_db_ids in each clade
  # Ideally, this should be stored in $hub->species_defs->multi_hash->{'DATABASE_COMPARA'}
  # or any other centralized place, to avoid recomputing it many times
  my %genome_db_ids_by_clade = map {$_ => []} @{ $sd->TAXON_ORDER };
  foreach my $prod_name (keys %{$sd->multi_hash->{'DATABASE_COMPARA'}{'COMPARA_SPECIES'}||{}}) {  
    my $species_name = $lookup->{$prod_name};
    my $hierarchy     = $sd->get_config($species_name, 'SPECIES_GROUP_HIERARCHY') || [];
    next unless scalar @$hierarchy;
    foreach my $clade (@$hierarchy) {
      push @{$genome_db_ids_by_clade{$clade}}, $sd->multi_hash->{'DATABASE_COMPARA'}{'GENOME_DB'}{$prod_name};
    }
  }

  if (@hidden_clades) {
    %hidden_genome_db_ids = ();
    
    foreach my $clade (@hidden_clades) {
      my ($clade_name) = $clade =~ /group_([\w\-]+)_display/;
      $hidden_genome_db_ids{$_} = 1 for @{ $genome_db_ids_by_clade{$clade_name} };
    }
    
    foreach my $this_leaf (@$leaves) {
      my $genome_db_id = $this_leaf->genome_db_id;
      
      next if $highlight_genome_db_id && $genome_db_id eq $highlight_genome_db_id;
      next if $highlight_gene && $this_leaf->gene_member->stable_id eq $highlight_gene;
      next if $member && $genome_db_id == $member->genome_db_id;
      
      if ($hidden_genome_db_ids{$genome_db_id}) {
        $hidden_genes_counter++;
        $this_leaf->disavow_parent;
        $tree = $tree->minimize_tree;
      }
    }

    $html .= $self->_info('Hidden genes', "<p>There are $hidden_genes_counter hidden genes in the tree. Use the 'configure page' link in the left panel to change the options.</p>") if $hidden_genes_counter;
  }

  $image_config->set_parameters({
    container_width => $image_width,
    image_width     => $image_width,
    slice_number    => '1|1',
    cdb             => $cdb,
    highlight_gene  => $highlight_gene
  });
  
  # Keep track of collapsed nodes
  #my $collapsed_nodes = $self->param('collapse'); # already defined above
  my ($collapsed_to_gene, $collapsed_to_para);
  
  if (!$is_genetree) {
    $collapsed_to_gene = $self->collapsed_nodes($tree, $node, 'gene',     $highlight_genome_db_id, $highlight_gene);
    $collapsed_to_para = $self->collapsed_nodes($tree, $node, 'paralogs', $highlight_genome_db_id, $highlight_gene);
  }
  
  my $collapsed_to_dups = $self->collapsed_nodes($tree, undef, 'duplications', $highlight_genome_db_id, $highlight_gene);

  if (!defined $collapsed_nodes) { # Examine collapsabilty
    $collapsed_nodes = $collapsed_to_gene if $collapsability eq 'gene';
    $collapsed_nodes = $collapsed_to_para if $collapsability eq 'paralogs';
    $collapsed_nodes = $collapsed_to_dups if $collapsability eq 'duplications';
    $collapsed_nodes ||= '';
  }

  if (@collapsed_clades) {
    foreach my $clade (@collapsed_clades) {
      my ($clade_name) = $clade =~ /group_([\w\-]+)_display/;
      my $extra_collapsed_nodes = $self->find_nodes_by_genome_db_ids($tree, $genome_db_ids_by_clade{$clade_name}, 'internal');
      
      if (%$extra_collapsed_nodes) {
        $collapsed_nodes .= ',' if $collapsed_nodes;
        $collapsed_nodes .= join ',', keys %$extra_collapsed_nodes;
      }
    }
  }

  my $coloured_nodes;
  
  if ($colouring =~ /^(back|fore)ground$/) {
    my $mode   = $1 eq 'back' ? 'bg' : 'fg';

    # TAXON_ORDER is ordered by increasing phylogenetic size. Reverse it to
    # get the largest clades first, so that they can be overwritten later
    # (see ensembl-webcode/modules/EnsEMBL/Draw/GlyphSet/genetree.pm)
    foreach my $clade_name (reverse @{ $sd->TAXON_ORDER }) {
      next unless $self->param("group_${clade_name}_${mode}colour");
      my $genome_db_ids = $genome_db_ids_by_clade{$clade_name};
      my $colour        = $self->param("group_${clade_name}_${mode}colour");
      my $nodes         = $self->find_nodes_by_genome_db_ids($tree, $genome_db_ids, $mode eq 'fg' ? 'all' : undef);
      
      push @$coloured_nodes, { clade => $clade_name,  colour => $colour, mode => $mode, node_ids => [ keys %$nodes ] } if %$nodes;
    }
  }
 
  push @highlights, $collapsed_nodes        || undef;
  push @highlights, $coloured_nodes         || undef;
  push @highlights, $highlight_genome_db_id || undef;
  push @highlights, $highlight_gene         || undef;
  push @highlights, $highlight_ancestor     || undef;
  push @highlights, $show_exons;

    # EG
    my @highlight_tags             = split(',',$self->param('ht') || "");
    my $highlight_map = $self->get_highlight_map($cdb,$tree->tree);
    #my @compara_highlights; # not to be confused with COMPARA_HIGHLIGHTS list

    my @ontology_terms = ();
    foreach my $ot_map (@$highlight_map){
      my $xref = $ot_map->{'xref'};
      if ( grep /^$xref$/, @highlight_tags ){
        push (@ontology_terms, 
          sprintf("%s,%s,%s", $xref, $ot_map->{'colour'}, join(',', @{$ot_map->{'members'}})) 
        );
      }
    }
    push(@highlights, \@ontology_terms);
    #my $compara_highlights_str = join(';',@compara_highlights);

  my $image = $self->new_image($tree, $image_config, \@highlights);
  
  return if $self->_export_image($image, 'no_text');

  my $image_id = $gene ? $gene->stable_id : $tree_stable_id;
  my $li_tmpl  = '<li><a href="%s">%s</a></li>';
  my @view_links;


  $image->image_type        = 'genetree';
  $image->image_name        = ($self->param('image_width')||'0') . "-$image_id";
  $image->imagemap          = 'yes';
  $image->{'panel_number'}  = 'tree';

  ## Need to pass gene name to export form 
  my $gene_name;
  if ($gene) {
    my $dxr    = $gene->Obj->can('display_xref') ? $gene->Obj->display_xref : undef;
    $gene_name = $dxr ? $dxr->display_id : $gene->stable_id;
  }
  else {
    $gene_name = $tree_stable_id;
  }

  ## Parameters to pass into export form
## EG
  $image->{'export_params'} = [['gene_name', $gene_name],['align', 'tree'],['cdb', $cdb]];
##
  my @extra_params = qw(g1 anc collapse exons);
  foreach (@extra_params) {
    push @{$image->{'export_params'}}, [$_, $self->param($_)];
  }
  foreach ($self->param) {
    if (/^group/) {
      push @{$image->{'export_params'}}, [$_, $self->param($_)];
    }
  }
  $image->{'data_export'}   = 'GeneTree';
  $image->{'remove_reset'}  = 1;

  $image->set_button('drag', 'title' => 'Drag to select region');
# EG include the ht param
  my $default_view_url = $hub->url({ $self->param('ht') ? (ht => $self->param('ht')) : (), collapse => $collapsed_to_gene, g1 => $highlight_gene });

  if ($gene) {
    push @view_links, sprintf '<li><a href="%s">%s</a> (Default) </li>', $default_view_url, $highlight_gene ? 'View current genes only' : 'View current gene only';
    push @view_links, sprintf $li_tmpl, $hub->url({ $self->param('ht') ? (ht => $self->param('ht')) : (), collapse => $collapsed_to_para || undef, g1 => $highlight_gene }), $highlight_gene ? 'View paralogues of current genes' : 'View paralogues of current gene';
  }
  
  push @view_links, sprintf $li_tmpl, $hub->url({ $self->param('ht') ? (ht => $self->param('ht')) : (), collapse => $collapsed_to_dups, g1 => $highlight_gene }), 'View all duplication nodes';
  push @view_links, sprintf $li_tmpl, $hub->url({ $self->param('ht') ? (ht => $self->param('ht')) : (), collapse => 'none', g1 => $highlight_gene }), 'View fully expanded tree';
  push @view_links, sprintf $li_tmpl, '#', 'Switch off highlighting' if $highlight_gene;
# /EG

  {
    my @rank_options = ( q{<option value="#">-- Select a rank--</option>} );
    my $selected_rank = $self->param('gtr') || '';
    foreach my $rank (qw(species genus family order class phylum kingdom)) {
      my $collapsed_to_rank = $self->collapsed_nodes($tree, $node, "rank_$rank", $highlight_genome_db_id, $highlight_gene);
      push @rank_options, sprintf qq{<option value="%s" %s>%s</option>\n}, $hub->url({ collapse => $collapsed_to_rank, g1 => $highlight_gene, gtr => $rank }), $rank eq $selected_rank ? 'selected' : '', ucfirst $rank;
    }
    push @view_links, sprintf qq{<li>Collapse all the nodes at the taxonomic rank <select onchange="Ensembl.redirect(this.value)">%s</select></li>}, join("\n", @rank_options) if(!$self->is_strain);
  }

  $html .= $image->render;
  $html .= sprintf(qq{
    <div>
      <h4>View options:</h4>
      <ul>%s</ul>
      <p>Use the 'configure page' link in the left panel to set the default. Further options are available from menus on individual tree nodes.</p>
    </div>
  }, join '', @view_links);
  
  return $html;
}

sub get_highlight_map{
  my ($self, $cdb_name, $tree) = @_;
  my $hub         = $self->hub;
  my $object      = $self->object || $self->hub->core_object('gene');
  return [] if ($hub->species =~ /^multi$/i);
  if(exists $object->{'highlight_map'}){
    return $object->{'highlight_map'};
  }
  my @mapped_terms;
  my $colour = 'acef9b';
  my @compara_highlights = @{$hub->species_defs->COMPARA_HIGHLIGHTS || [] };
  return [] unless scalar @compara_highlights;
  my $adaptor = undef;
  eval{
    my $cdb = $object->database($cdb_name);
    $adaptor = Bio::EnsEMBL::Compara::DBSQL::XrefAssociationAdaptor->new($cdb);
  };
  return [] unless $adaptor;
  my $dbe = $hub->get_adaptor('get_DBEntryAdaptor');
  my $goadaptor = $hub->database('go');
  my $goa = $goadaptor->get_OntologyTermAdaptor;
  for my $db_name (@compara_highlights){
    for my $xref (@{$adaptor->get_associated_xrefs_for_tree($tree,$db_name)}) {
      my $entry = $dbe->fetch_by_db_accession($db_name,$xref);
      my $desc;
      $desc = $entry->description if($entry);
      if(!$desc && $db_name =~ /^GO$/i){
        if (my $term = $goa->fetch_by_accession($xref)) { 
          $desc = $term->name || $term->definition;
        }
      }
      my @members = map { $_->stable_id } @{$adaptor->get_members_for_xref($tree,$xref,$db_name)};
      push (@mapped_terms,{ xref=>$xref, db_name=>$db_name, members=>\@members, colour=>$colour, desc=>$desc});
    }
  }
  $object->{'highlight_map'} = \@mapped_terms;
  return \@mapped_terms;
}

1;
