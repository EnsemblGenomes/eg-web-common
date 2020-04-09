=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::ComparaHomoeologs;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Component::Gene);

use EnsEMBL::Web::Utils::FormatText qw(glossary_helptip);

our %button_set = ('download' => 1, 'view' => 0);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}



sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $cdb          = shift || $self->param('cdb') || 'compara';
  my $availability = $object->availability;

  my @homoeologues = (
    $object->get_homology_matches('ENSEMBL_HOMOEOLOGUES', 'homoeolog', undef, $cdb), 
  );
  
  my %homoeologue_list;
  my %skipped;
  
  foreach my $homology_type (@homoeologues) {
    foreach (keys %$homology_type) {
      (my $species = $_) =~ tr/ /_/;
      $homoeologue_list{$species} = {%{$homoeologue_list{$species}||{}}, %{$homology_type->{$_}}};
      $skipped{$species}        += keys %{$homology_type->{$_}} if $self->param('species_' . lc $species) eq 'off';
    }
  }
  
  return '<p>No homoeologues have been identified for this gene</p>' unless keys %homoeologue_list;
  
  my $alignview = 0;
 
  my ($html, $columns, @rows);
  
  $columns = [
    { key => 'Species',    align => 'left', width => '15%', sort => 'html'                                                },
    { key => 'Type',       align => 'left', width => '15%', sort => 'html'                                            },   
    { key => 'identifier', align => 'left', width => '40%', sort => 'none', title => 'Homoeologue'},      
    { key => 'Target %id', align => 'left', width => '10%',  sort => 'position_html', label => 'Target %id', help => "Percentage of the homoeologous sequence matching the source sequence" },
    { key => 'Query %id',  align => 'left', width => '10%',  sort => 'position_html', label => 'Query %id',  help => "Percentage of the source sequence matching the sequence of the homoeologoue" },
  ];
  
  push @$columns, { key => 'Gene name(Xref)',  align => 'left', width => '15%', sort => 'html', title => 'Gene name(Xref)'} if(!$self->html_format);
  
  @rows = ();
  
  foreach my $species (sort { ($a =~ /^<.*?>(.+)/ ? $1 : $a) cmp ($b =~ /^<.*?>(.+)/ ? $1 : $b) } keys %homoeologue_list) {
    next if $skipped{$species};
    
    foreach my $stable_id (sort keys %{$homoeologue_list{$species}}) {
      my $homoeologue = $homoeologue_list{$species}{$stable_id};
      my ($target, $query);
      
      # Add in homoeologue description
      my $homoeologue_desc = $homoeologue->{'homology_desc'};

      (my $spp = $homoeologue->{'spp'}) =~ tr/ /_/;
      $spp = $species_defs->production_name_mapping($spp);
      my $link_url = $hub->url({
        species => $spp,
        action  => 'Summary',
        g       => $stable_id,
        __clear => 1
      });

      my $seq_region = [split /:/, $homoeologue->{'location'}]->[0];
      my $region_link = sprintf('<a href="%s">Compare Regions</a> ('.$homoeologue->{'location'}.')',
        $hub->url({
          type   => 'Location',
          action => 'Multi',
          g1     => $stable_id,
          s1     => "$spp--$seq_region",
          r      => $hub->create_padded_region()->{'r'} || $self->param('r'),
          config => 'opt_join_genes_bottom=on',
        })
      );
      
      my ($alignment_link, $target_class, $query_class);
      if ($homoeologue_desc ne 'DWGA') {
        ($target, $query) = ($homoeologue->{'target_perc_id'}, $homoeologue->{'query_perc_id'});
         $target_class    = ($target && $target <= 10) ? "bold red" : "";
         $query_class     = ($query && $query <= 10) ? "bold red" : "";
       
        my $page_url = $hub->url({
          type    => 'Gene',
          action  => $hub->action,
          g       => $self->param('g'), 
        });
          
        my $zmenu_url = $hub->url({
          type    => 'ZMenu',
          action  => 'ComparaHomoeologs',
          g1      => $stable_id,
          dbID    => $homoeologue->{'dbID'},
          cdb     => $cdb,
        });

        $alignment_link = sprintf '<a href="%s" class="_zmenu">View Sequence Alignments</a><a class="hidden _zmenu_link" href="%s"></a>', $page_url ,$zmenu_url;          
        
        $alignview = 1;
      }       

      my $tree_url = $hub->url({
        type   => 'Gene',
        action => 'Compara_Tree' . ($cdb =~ /pan/ ? '/pan_compara' : ''),
        g1     => $stable_id,
        anc    => $homoeologue->{'gene_tree_node_id'},
        r      => undef
      });
      
      # External ref and description
      my $description = encode_entities($homoeologue->{'description'});
         $description = 'No description' if $description eq 'NULL';
         
      if ($description =~ s/\[\w+:([-\/\w]+)\;\w+:(\w+)\]//g) {
        my ($edb, $acc) = ($1, $2);
        $description   .= sprintf '[Source: %s; acc: %s]', $edb, $hub->get_ExtURL_link($acc, $edb, $acc) if $acc;
      }
      
      my $id_info;
      if (!$homoeologue->{'display_id'} || $homoeologue->{'display_id'} eq 'Novel Ensembl prediction') {
        $id_info = qq{<p class="space-below"><a href="$link_url">$stable_id</a></p>};
      } else {
        $id_info = qq{<p class="space-below">$homoeologue->{'display_id'}&nbsp;&nbsp;<a href="$link_url">($stable_id)</a></p>};
      }
      $id_info .= qq{<p class="space-below">$region_link</p><p class="space-below">$alignment_link</p>};

      ##Location - split into elements to reduce horizonal space
      my $location_link = $hub->url({
        species => $spp,
        type    => 'Location',
        action  => 'View',
        r       => $homoeologue->{'location'},
        g       => $stable_id,
        __clear => 1
      });

      my $table_details = {
        'Species'    => join('<br />(', split /\s*\(/, $species_defs->species_label($species_defs->production_name_mapping($species))),
        'Type'       => $self->html_format ? glossary_helptip($hub, ucfirst $homoeologue_desc, ucfirst "$homoeologue_desc homoeologues").qq{<p class="top-margin"><a href="$tree_url">View Gene Tree</a></p>} : glossary_helptip($hub, ucfirst $homoeologue_desc, ucfirst "$homoeologue_desc homoeologues") ,
        'identifier' => $self->html_format ? $id_info : $stable_id,
        'Target %id' => qq{<span class="$target_class">}.sprintf('%.2f&nbsp;%%', $target).qq{</span>},
        'Query %id'  => qq{<span class="$query_class">}.sprintf('%.2f&nbsp;%%', $query).qq{</span>},
      };      
      $table_details->{'Gene name(Xref)'}=$homoeologue->{'display_id'} if(!$self->html_format);
      
      push @rows, $table_details;
    }
  }
  
  my $table = $self->new_table($columns, \@rows, { data_table => 1, sorting => [ 'Species asc', 'Type asc' ], id => 'homoeologues' });
  
  if ($alignview && keys %homoeologue_list) {
    $button_set{'view'} = 1;
  }
  
  $html .= $table->render;
  
  if (scalar keys %skipped) {
    my $count;
    $count += $_ for values %skipped;
    
    $html .= '<br />' . $self->_info(
      'Homoeologues hidden by configuration',
      sprintf(
        '<p>%d homoeologues not shown in the table above from the following species. Use the "<strong>Configure this page</strong>" on the left to show them.<ul><li>%s</li></ul></p>',
        $count,
        join "</li>\n<li>", sort map {$species_defs->species_label($species_defs->production_name_mapping($_))." ($skipped{$_})"} keys %skipped
      )
    );
  }   

  return $html;
}

sub export_options { return {'action' => 'Homoeologs'}; }

sub get_export_data {
## Get data for export
  my ($self, $flag) = @_;
  my $hub          = $self->hub;
  my $object       = $self->object || $hub->core_object('gene');

  if ($flag eq 'sequence') {
    return $object->get_homologue_alignments('compara', 'ENSEMBL_HOMOEOLOGUES');
  }
  else {
    my $cdb = $flag || $self->param('cdb') || 'compara';
    my ($homologies) = $object->get_homologies('ENSEMBL_HOMOEOLOGUES', 'homoeolog', undef, $cdb);
    return $homologies;
  }
}

sub buttons {
  my $self    = shift;
  my $hub     = $self->hub;
  my @buttons;

  if ($button_set{'download'}) {

    my $gene    =  $self->object->Obj;

    my $dxr  = $gene->can('display_xref') ? $gene->display_xref : undef;
    my $name = $dxr ? $dxr->display_id : $gene->stable_id;

    my $params  = {
                  'type'        => 'DataExport',
                  'action'      => 'Homoeologs',
                  'data_type'   => 'Gene',
                  'component'   => 'ComparaHomoeologs',
                  'data_action' => $hub->action,
                  'gene_name'   => $name,
                };

    ## Add any species settings
    foreach (grep { /^species_/ } $self->param) {
      $params->{$_} = $self->param($_);
    }

    push @buttons, {
                    'url'     => $hub->url($params),
                    'caption' => 'Download homoeologues',
                    'class'   => 'export',
                    'modal'   => 1
                    };
  }

  return @buttons;
}

1;
