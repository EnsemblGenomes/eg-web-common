package EnsEMBL::Web::Component::Gene::TreeSummary;

use strict;

use Bio::AlignIO;
use IO::Scalar;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
  $self->has_image(0);
}

sub get_details {
  my $self   = shift;
  my $cdb    = shift;
  my $object = $self->object;
  my $member = $object->get_compara_Member($cdb);

  return (undef, '<strong>Gene is not in the compara database</strong>') unless $member;

  my $test_tree = $object->get_SpeciesTree($cdb);
  
  my $tree = $object->get_GeneTree($cdb);
  return (undef, '<strong>Gene is not in a compara tree</strong>') unless $tree;

  my $node = $tree->get_leaf_by_Member($member);
  return (undef, '<strong>Gene is not in the compara tree</strong>') unless $node;

  return ($member, $tree, $node, $test_tree);
}

sub content {
  my $self        = shift;
  my $cdb         = shift || 'compara';
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $is_genetree = $object->isa('EnsEMBL::Web::Object::GeneTree') ? 1 : 0;
  my ($gene, $member, $tree, $node, $test_tree);

  if ($is_genetree) {
    $tree   = $object->Obj;
    $member = undef;
  } else {
    $gene = $object;
    ($member, $tree, $node, $test_tree) = $self->get_details($cdb);
  }

  return $tree . $self->genomic_alignment_links($cdb) if $hub->param('g') && !$is_genetree && !defined $member;

  my $leaves               = $tree->get_all_leaves;
  my $tree_stable_id       = $tree->tree->stable_id;
  my $highlight_gene       = $hub->param('g1');
  my $highlight_ancestor   = $hub->param('anc');
  my $unhighlight          = $highlight_gene ? $hub->url({ g1 => undef, collapse => $hub->param('collapse') }) : '';
  my $image_width          = $self->image_width       || 800;
  my $colouring            = $hub->param('colouring') || 'background';
  my $collapsability       = $is_genetree ? '' : $hub->param('collapsability');
  my $show_exons           = $hub->param('exons') eq 'on' ? 1 : 0;
  my $image_config         = $hub->get_imageconfig('genetreeview');
  my @hidden_clades        = grep { $_ =~ /^group_/ && $hub->param($_) eq 'hide'     } $hub->param;
  my @collapsed_clades     = grep { $_ =~ /^group_/ && $hub->param($_) eq 'collapse' } $hub->param;
  my @highlights           = $gene && $member ? ($gene->stable_id, $member->genome_db->dbID) : (undef, undef);
  my $hidden_genes_counter = 0;
  my $link                 = $hub->type eq 'GeneTree' ? '' : sprintf ' <a href="%s">%s</a>', $hub->url({ species => 'Multi', type => 'GeneTree', action => undef, gt => $tree_stable_id, __clear => 1 }), $tree_stable_id;
  my ($hidden_genome_db_ids, $highlight_species, $highlight_genome_db_id);

  my $html                 = sprintf '<h3>GeneTree%s</h3>%s', $link, $self->new_twocol(
    ['Number of genes',             scalar(@$leaves)                                                  ],
    ['Number of speciation nodes',  $self->get_num_nodes_with_tag($tree, 'node_type', 'speciation')   ],
    ['Number of duplication',       $self->get_num_nodes_with_tag($tree, 'node_type', 'duplication')  ],
    ['Number of ambiguous',         $self->get_num_nodes_with_tag($tree, 'node_type', 'dubious')      ],
    ['Number of gene split events', $self->get_num_nodes_with_tag($tree, 'node_type', 'gene_split')   ]
  )->render;

  
  return $html;
}

sub get_num_nodes_with_tag {
  my ($self, $tree, $tag, $test_value, $exclusion_tag_array) = @_;
  my $count = 0;

  OUTER: foreach my $tnode(@{$tree->get_all_nodes}) {
    my $tag_value = $tnode->get_tagvalue($tag);
    #Accept if the test value was not defined but got a value from the node
    #or if we had a tag value and it was equal to the test
    if( (! $test_value && $tag_value) || ($test_value && $tag_value eq $test_value) ) {
      
      #If we had an exclusion array then check & skip if it found anything
      if($exclusion_tag_array) {
        foreach my $exclusion (@{$exclusion_tag_array}) {
          my $exclusion_value = $tnode->get_tagvalue($exclusion);
          if($exclusion_value) {
            next OUTER;
          }
        }
      }
      $count++;
    }
  }

  return $count;
}


1;
