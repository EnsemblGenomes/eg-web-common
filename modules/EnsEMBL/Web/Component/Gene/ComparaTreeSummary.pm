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

package EnsEMBL::Web::Component::Gene::ComparaTreeSummary;

use strict;
use warnings;
use base qw(EnsEMBL::Web::Component::Gene::ComparaTree);

sub content {
    my $self        = shift;
    my $cdb         = shift || 'compara';
    my $hub         = $self->hub;
    my $object      = $self->object;
    my $is_genetree = $object->isa('EnsEMBL::Web::Object::GeneTree') ? 1 : 0;
    my ($gene, $member, $tree, $node);

    if ($is_genetree) {
  $tree   = $object->Obj;
  $member = undef;
    } else {
  $gene = $object;
  ($member, $tree, $node) = $self->get_details($cdb);
    }

    return $tree . $self->genomic_alignment_links($cdb) if $hub->param('g') && !$is_genetree && !defined $member;

    my $leaves               = $tree->get_all_leaves;
    my $tree_stable_id       = $tree->tree->stable_id;
    my $highlight_gene       = $hub->param('g1');
    my $highlight_ancestor   = $hub->param('anc');
    my $unhighlight          = $highlight_gene ? $hub->url({ g1 => undef, collapse => $hub->param('collapse') || undef }) : '';
    my $image_width          = $self->image_width       || 800;
    my $colouring            = $hub->param('colouring') || 'background';
    my $collapsability       = $is_genetree ? '' : $hub->param('collapsability');
    my $show_exons           = $hub->param('exons') || 0;
    $show_exons = $show_exons eq 'on' ? 1 : 0;
    my $image_config         = $hub->get_imageconfig('genetreeview');
    my @hidden_clades        = grep { $_ =~ /^group_/ && $hub->param($_) eq 'hide'     } $hub->param;
    my @collapsed_clades     = grep { $_ =~ /^group_/ && $hub->param($_) eq 'collapse' } $hub->param;
    my @highlights           = $gene && $member ? ($gene->stable_id, $member->genome_db->dbID) : (undef, undef);
    my $hidden_genes_counter = 0;
    my $link                 = $hub->type eq 'GeneTree' ? '' : sprintf(' %s <a title="stable link to the tree" href="%s" >link</a>', $tree_stable_id, $hub->url({ species => 'Multi', type => 'GeneTree', action => undef, gt => $tree_stable_id,  __clear => 1 }));

    my ($hidden_genome_db_ids, $highlight_species, $highlight_genome_db_id);


    #EG: warning message is added to the top of the page to let the user know if an old GeneTree stable_ids is mapped to new GeneTree stable_ids
    # EG highlight tree nodes by annotation
    my $hide = $hub->get_cookie_value('toggle_ht_table') eq 'closed';
    my @ontology_terms             = split(',',$hub->param('ht') || '');
    my @highlight_map = @{$self->get_highlight_map($cdb,$tree->tree) || []};
    my ($highlight_filter, $highlight_tags_table) = ("","");
    my ($hitags,$hitags_types);
    if(@highlight_map){
      $hitags_types = $self->highlight_types_selector(\@highlight_map);
      $highlight_tags_table = $self->highlight_tags_table(\@highlight_map);
     #my $hitags_text = '<img alt="*New Feature" style="vertical-align:middle;width:32px" src="/i/new_star.gif"/>Highlight annotations'; # EG 17 removed NEW! star
      my $hitags_text = 'Highlight annotations';
      $hitags = $self->dom->create_element('div',{});
      $hitags->append_child('a',{href=>'#',rel=>'ht_table',class=>sprintf('toggle set_cookie %s',$hide ? 'closed':'open'),title=>'highlight tags',inner_HTML=>$hitags_text});
      $hitags->append_child('span',{style=>"display:block;text-align:center;"})->append_child('small',{inner_HTML=>'click to show/hide table'});
    }
    #
    my $html = $tree->history_warn ? $self->_warning('Warning', $tree->history_warn) : '';
    $html .= sprintf '<h3>GeneTree%s</h3>%s', $link, $self->new_twocol(
      ['Number of genes',             scalar(@$leaves)                                                  ],
      ['Number of speciation nodes',  $self->get_num_nodes_with_tag($tree, 'node_type', 'speciation')   ],
      ['Number of duplication',       $self->get_num_nodes_with_tag($tree, 'node_type', 'duplication')  ],
      ['Number of ambiguous',         $self->get_num_nodes_with_tag($tree, 'node_type', 'dubious')      ],
      ['Number of gene split events', $self->get_num_nodes_with_tag($tree, 'node_type', 'gene_split')   ],
      @highlight_map ? [ $hitags->render, $hitags_types ] : undef
    )->render;
    $html .= $highlight_tags_table;
    #/EG


    return $html;
}


sub highlight_tags_table {
  my ($self,$highlight_map) = @_;
  my $hub = $self->hub;
  my $hide = $hub->get_cookie_value('toggle_ht_table') eq 'closed';
  my @rows;
  my $selected = $hub->param('ht') || undef;
  for my $tag (@$highlight_map){
    my $xref = $tag->{'xref'};
    my $count = scalar @{$tag->{'members'}};
    my $db_name = $tag->{'db_name'};
    my $desc = $tag->{'desc'};
    my $update_url = $hub->url({type=>'Component/Gene',action=>'Web',function=>'ComparaTree', ht => $xref, g1 => $hub->param('g1') || undef });
    my $text   = $count ? $count > 1 ? "$count members" : "$count member" : "$count members";
    my $checked =  $selected && $selected eq $xref ? 'checked="checked"' : '';
    push(@rows, {
      ht => $hub->get_ExtURL_link($xref,$db_name,$xref),
      highlight => sprintf(qq{<input class="%04d_members update_genetree" %s type="radio" name="highlight_tag_selector" value="%s"/>%s},$count,$checked,$update_url,$text),
      description=> $desc,
      options => {class => "type_any type_$db_name"},
    });
  }
  my $table = $self->new_table(
    [
      {key=>'highlight',title=>'highlight'},
      {key=>'ht',title=>'Accession'},
      {key=>'description',title=>'Description'}
    ],
    \@rows,
    {
      code=>1,data_table=>1,id=>'ht_table',toggleable=>1,
      class=>sprintf('no_col_toggle %s',$hide ? 'hide':''),
      data_table_config=>{iDisplayLength=>10,},
      header=> $self->highlight_types_selector($highlight_map),
    },
  );
  return $table->render;
}

=head2 highlight_types_selector

  Arg[1] : ptr to highlight map array
  Return : string, HTML for a set of checkboxes for filtering the Highlight Annotations table 

=cut

sub highlight_types_selector {
  my ($self,$highlight_map) = @_;
  my $hub = $self->hub;
  my $hide = $hub->get_cookie_value('toggle_ht_table') eq 'closed';
  my $selected_id = $hub->param('ht') || undef;
  my $selected_db_name = $hub->param('db_name') || undef;
  my %types = (); 
  map { push( @{ $types{ $_->{'db_name'} } }, $_ ) } @$highlight_map;
  my @options = ();
  for my $db_name (keys %types){
    push(@options,{
      value=>$db_name,
      caption=>sprintf("%s (%d members)",$db_name, scalar @{$types{$db_name}}),
    });
  }
  if(scalar keys %types  < 2){ return "";}#only one type, no filters needed
  my $meta = $self->dom->create_element('div', {class=>'ht_table'});
  my $form = $meta->append_child('div',{class=>sprintf('toggleable toggleTable_wrapper %s', $hide ? 'hide':'')});
  $form->append_child('span',{inner_HTML=>'Shown terms: '});
  for my $db_name (keys %types){
    $form->append_child('input',{name=>'ht_table',class=>'table_filter',type=>'checkbox', checked=>1, value=>"type_$db_name"});
    $form->append_child('label',{inner_HTML=>sprintf("%s ",$db_name)});
  }
  return $meta->render;
}

1;
