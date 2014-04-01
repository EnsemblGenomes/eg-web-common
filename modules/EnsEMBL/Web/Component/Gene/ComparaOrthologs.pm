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

package EnsEMBL::Web::Component::Gene::ComparaOrthologs;

use strict;

sub is_archaea {
  my ($self,$species) = @_;
  unless(exists($self->{'_archaea'})){
    # munge archaea in pan-compara
    my $dbc = $self->hub->database('compara_pan_ensembl');
    my $archaea = {};
    my $results = $dbc->db_handle->selectall_arrayref(qq{select g.name from ncbi_taxa_node a join ncbi_taxa_name an using (taxon_id) join ncbi_taxa_node c on (c.left_index>a.left_index and c.right_index<a.right_index) join genome_db g on (g.taxon_id=c.taxon_id) where an.name='Archaea' and an.name_class='scientific name';});
    $self->{'_archaea'}->{$_->[0]} = 1 for @$results;
  }
  return exists($self->{'_archaea'}->{$species});
}

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $skipped) = @_;

  my $species_defs  = $self->hub->species_defs;

  my $set_order;
  my $is_pan = $self->hub->function eq 'pan_compara';
  if($is_pan){
    $set_order = [qw(all ensembl metazoa plants fungi protists bacteria archaea)];
  }
  

  my $categories = {};
  my $species_sets = {
    'ensembl'     => {'title' => 'Vertebrates', 'desc' => '', 'species' =>[]},
    'metazoa'     => {'title' => 'Metazoa', 'desc'=>'', 'species'=>[]},
    'plants'      => {'title' => 'Plants', 'desc' => '', 'species' => []},
    'fungi'       => {'title' => 'Fungi', 'desc' => '', 'species' => []},
    'protists'    => {'title' => 'Protists', 'desc' => '', 'species' => []},
    'bacteria'    => {'title' => 'Bacteria', 'desc' => '', 'species' => []},
    'archaea'     => {'title' => 'Archaea', 'desc' => '', 'species' => []},
    'all'       =>   {'title' => 'All', 'desc' => '', 'species' => []},
  };

  my $sets_by_species = {};

  my $spsites =  $species_defs->ENSEMBL_SPECIES_SITE();
  foreach my $species (keys %$orthologue_list) {
    next if $skipped->{$species};
    my $group = $spsites->{lc($species)};
    if($group eq 'bacteria'){
      if($self->is_archaea(lc $species)){
        $group='archaea';
      }
    }
    elsif (!$is_pan){ # not the pan compara page - generate groups
      $group = $species_defs->get_config($species, 'SPECIES_GROUP') || $spsites->{lc($species)} || 'Undefined';
      if(!exists $species_sets->{$group}){
        $species_sets->{$group} = {'title'=>ucfirst $group,'species'=>[]};
        push(@$set_order,$group);
      }
    }

    push (@{$species_sets->{'all'}{'species'}}, $species);
    my $sets = [];

    my $orthologues = $orthologue_list->{$species} || {};
    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species}{$stable_id};
      my $orth_desc = $orth_info->{'homology_desc'};
      $species_sets->{'all'}{$orth_desc}++;
      $species_sets->{$group}{$orth_desc}++;
      $categories->{$orth_desc} = {key=>$orth_desc, title=>$orth_desc} unless exists $categories->{$orth_desc};
    }
    push(@{$species_sets->{$group}{'species'}},$species);
    push (@$sets, $group) if(exists $species_sets->{$group});
    $sets_by_species->{$species} = $sets;
  }

  if(!$is_pan) {
    my @unorder = @$set_order;
    @$set_order = sort(@unorder);
    unshift(@$set_order, 'all');
  }

  return ($species_sets, $sets_by_species, $set_order, $categories);
}

sub in_archaea {
  my ($self, $species)=@_;
  
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $cdb          = shift || $hub->param('cdb') || 'compara';
  my $availability = $object->availability;
  
  my @orthologues = (
    $object->get_homology_matches('ENSEMBL_ORTHOLOGUES', undef, undef, $cdb), 
    $object->get_homology_matches('ENSEMBL_PARALOGUES', 'possible_ortholog', undef, $cdb)
  );
  
  my %orthologue_list;
  my %skipped;
  
  foreach my $homology_type (@orthologues) {
    foreach (keys %$homology_type) {
      (my $species = $_) =~ tr/ /_/;
      foreach my $foo (keys %{$homology_type->{$_}}){
      }
      $orthologue_list{$species} = {%{$orthologue_list{$species}||{}}, %{$homology_type->{$_}}};
      $skipped{$species}        += keys %{$homology_type->{$_}} if $hub->param('species_' . lc $species) eq 'off';
    }
  }
  
  return '<p>No orthologues have been identified for this gene</p>' unless keys %orthologue_list;
  
  my %orthologue_map;
  my $alignview      = 0;
 
  my ($html, $columns, @rows);

  ##--------------------------- SUMMARY TABLE ----------------------------------------

  my ($species_sets, $sets_by_species, $set_order, $categories) = $self->_species_sets(\%orthologue_list, \%skipped, \%orthologue_map);

  if ($species_sets) {
    $html .= qq{
      <h3>Summary of orthologues of this gene</h3>
      <p class="space-below">Click on 'Show' to display the orthologues for one or more groups, or click on 'Configure this page' to choose a custom list of species</p>
    };
 
    $columns = [
      { key => 'set',       title => 'Species set',    align => 'left',     },
      { key => 'show',      title => 'Show details',   align => 'center',   },
    ];
    foreach my $orth_desc (sort keys %$categories){
      push( @$columns, $categories->{$orth_desc} );
    }
    my $width = sprintf("%d%", 100/@$columns);
    $_->{'width'}=$width for @$columns;

    foreach my $set (@$set_order) {
      my $set_info = $species_sets->{$set};
      
      my $row_data = {};
      $row_data->{'set'} = "<strong>$set_info->{'title'}</strong><br />$set_info->{'desc'}";
      if(@{$set_info->{'species'}} && $set_info->{'title'} ne 'All'){
        $row_data->{'show'} =  qq{<input type="checkbox" class="table_filter" title="Check to show these species in table below" name="orthologues" value="$set" />};
      }
      foreach my $orth_desc (%$categories){
        $row_data->{$orth_desc} = $set_info->{$orth_desc} || 0;
      }
      push @rows, $row_data;
    }
    
    $html .= $self->new_table($columns, \@rows)->render;
  }

  ##----------------------------- FULL TABLE -----------------------------------------

  $html .= '<h3>Selected orthologues</h3>' if $species_sets;
 
  my $column_name = $self->html_format ? 'Compare' : 'Description';
  
  my $columns = [
    { key => 'Species',    align => 'left', width => '10%', sort => 'html'                                                },
    { key => 'Type',       align => 'left', width => '5%',  sort => 'string'                                              },
    { key => 'dN/dS',      align => 'left', width => '5%',  sort => 'numeric'                                             },
    { key => 'identifier', align => 'left', width => '15%', sort => 'html', title => $self->html_format ? 'Ensembl identifier &amp; gene name' : 'Ensembl identifier'},    
    { key => $column_name, align => 'left', width => '10%', sort => 'none'                                                },
    { key => 'Location',   align => 'left', width => '20%', sort => 'position_html'                                       },
    { key => 'Target %id', align => 'left', width => '5%',  sort => 'numeric'                                             },
    { key => 'Query %id',  align => 'left', width => '5%',  sort => 'numeric'                                             },
  ];
  
  push @$columns, { key => 'Gene name(Xref)',  align => 'left', width => '15%', sort => 'html', title => 'Gene name(Xref)'} if(!$self->html_format);
  
  @rows = ();
  
  my $spsites =  $species_defs->ENSEMBL_SPECIES_SITE();
  foreach my $species (sort { ($a =~ /^<.*?>(.+)/ ? $1 : $a) cmp ($b =~ /^<.*?>(.+)/ ? $1 : $b) } keys %orthologue_list) {
    next if $skipped{$species};
    my $domain  = $spsites->{lc($species)};
    my $splink  = $hub->get_ExtURL_link($species_defs->species_label($species), uc $domain, {'SPECIES'=>$species});
    
    foreach my $stable_id (sort keys %{$orthologue_list{$species}}) {
      my $orthologue = $orthologue_list{$species}{$stable_id};
      my ($target, $query);
      
      # (Column 2) Add in Orthologue description
     #my $orthologue_desc = $orthologue_map{$orthologue->{'homology_desc'}} || $orthologue->{'homology_desc'};
      my $orthologue_desc =  $orthologue->{'homology_desc'};
      
      # (Column 3) Add in the dN/dS ratio
      my $orthologue_dnds_ratio = $orthologue->{'homology_dnds_ratio'} || 'n/a';
         
      # (Column 4) Sort out 
      # (1) the link to the other species
      # (2) information about %ids
      # (3) links to multi-contigview and align view
      (my $spp = $orthologue->{'spp'}) =~ tr/ /_/;
      my $link_url = $hub->url({
        species => $spp,
        action  => 'Summary',
        g       => $stable_id,
        __clear => 1
      });

      # Check the target species are on the same portal - otherwise the multispecies link does not make sense
      my $target_links = ($link_url =~ /^\// 
        && $cdb eq 'compara'
        && $availability->{'has_pairwise_alignments'}
      ) ? sprintf(
        '<ul class="compact"><li class="first"><a href="%s" class="notext">Region Comparison</a></li>',
        $hub->url({
          type   => 'Location',
          action => 'Multi',
          g1     => $stable_id,
          s1     => $spp,
          r      => undef,
          config => 'opt_join_genes_bottom=on',
        })
      ) : '';
      
      if ($orthologue_desc ne 'DWGA') {
        ($target, $query) = ($orthologue->{'target_perc_id'}, $orthologue->{'query_perc_id'});
       
        my $align_url = $hub->url({
            action   => 'Compara_Ortholog',
            function => 'Alignment' . ($cdb =~ /pan/ ? '_pan_compara' : ''),
            g1       => $stable_id,
          });
        
        unless ($object->Obj->biotype =~ /RNA/) {
          $target_links .= sprintf '<li><a href="%s" class="notext">Alignment (protein)</a></li>', $align_url;
        }
        $align_url    .= ';seq=cDNA';
        $target_links .= sprintf '<li><a href="%s" class="notext">Alignment (cDNA)</a></li>', $align_url;
        
        $alignview = 1;
      }
      
      $target_links .= sprintf(
        '<li><a href="%s" class="notext">Gene Tree (image)</a></li></ul>',
        $hub->url({
          type   => 'Gene',
          action => 'Compara_Tree' . ($cdb =~ /pan/ ? '/pan_compara' : ''),
          g1     => $stable_id,
          anc    => $orthologue->{'ancestor_node_id'},
          r      => undef
        })
      );
      
      # (Column 5) External ref and description
      my $description = encode_entities($orthologue->{'description'});
         $description = 'No description' if $description eq 'NULL';
         
      if ($description =~ s/\[\w+:([-\/\w]+)\;\w+:(\w+)\]//g) {
        my ($edb, $acc) = ($1, $2);
        $description   .= sprintf '[Source: %s; acc: %s]', $edb, $hub->get_ExtURL_link($acc, $edb, $acc) if $acc;
      }
      
      my @external = (qq{<span class="small">$description</span>});
      
      if ($orthologue->{'display_id'}) {
        if ($orthologue->{'display_id'} eq 'Novel Ensembl prediction' && $description eq 'No description') {
          @external = ('<span class="small">-</span>');
        } else {
          unshift @external, $orthologue->{'display_id'};
        }
      }

      my $id_info = qq{<p class="space-below"><a href="$link_url">$stable_id</a></p>} . join '<br />', @external;

      ## (Column 6) Location - split into elements to reduce horizonal space
      my $location_link = $hub->url({
        species => $spp,
        type    => 'Location',
        action  => 'View',
        r       => $orthologue->{'location'},
        g       => $stable_id,
        __clear => 1
      });
      
      my $table_details = {
        'Species'   => $splink,
        'Type'       => ucfirst $orthologue_desc,
        'dN/dS'      => $orthologue_dnds_ratio,
        'identifier' => $self->html_format ? $id_info : $stable_id,
        'Location'   => qq{<a href="$location_link">$orthologue->{'location'}</a>},
        $column_name => $self->html_format ? qq{<span class="small">$target_links</span>} : $description,
        'Target %id' => $target,
        'Query %id'  => $query,
        'options'    => { class => join(' ', 'all', @{$sets_by_species->{$species} || []}) }
      };      
      $table_details->{'Gene name(Xref)'}=$orthologue->{'display_id'} if(!$self->html_format);
      
      push @rows, $table_details;
    }
  }
  
  my $table = $self->new_table($columns, \@rows, { data_table => 1, sorting => [ 'Species asc', 'Type asc' ], id => 'orthologues' });
  
## EG  
  if ($alignview and keys %orthologue_list) {
    $html .= '<p>';
    $html .= sprintf(
      '<a href="%s">View protein sequence alignments of all orthologues</a>', 
      $hub->url({ action => 'Compara_Ortholog', function => 'Alignment' . ($cdb =~ /pan/ ? '_pan_compara' : ''), })   
    );
    $html .= sprintf(
      ' &nbsp;|&nbsp; <a href="%s" target="_blank">Download protein sequences</a>', 
      $hub->url({ action => 'Compara_Ortholog', function => 'PepSequence', '_format'=>'Text' }) 
    ) if $cdb !~ /pan/;
    $html .= '</p>';
   }
##  
  
  $html .= $table->render;
  
  if (scalar keys %skipped) {
    my $count;
    $count += $_ for values %skipped;
    
    $html .= '<br />' . $self->_info(
      'Orthologues hidden by configuration',
      sprintf(
        '<p>%d orthologues not shown in the table above from the following species. Use the "<strong>Configure this page</strong>" on the left to show them.<ul><li>%s</li></ul></p>',
        $count,
        join "</li>\n<li>", map "$_ ($skipped{$_})", sort keys %skipped
      )
    );
  }  
  return $html;
}


1;
