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
  my $cdb          = shift || $hub->param('cdb') || 'compara';
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
      $skipped{$species}        += keys %{$homology_type->{$_}} if $hub->param('species_' . lc $species) eq 'off';
    }
  }
  
  return '<p>No homoeologues have been identified for this gene</p>' unless keys %homoeologue_list;
  
  my %homoeologue_map = qw(SEED BRH PIP RHS);
  my $alignview      = 0;
 
  my ($html, $columns, @rows);
 
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
  
  foreach my $species (sort { ($a =~ /^<.*?>(.+)/ ? $1 : $a) cmp ($b =~ /^<.*?>(.+)/ ? $1 : $b) } keys %homoeologue_list) {
    next if $skipped{$species};
    
    foreach my $stable_id (sort keys %{$homoeologue_list{$species}}) {
      my $homoeologue = $homoeologue_list{$species}{$stable_id};
      my ($target, $query);
      
      # (Column 2) Add in homoeologue description
      my $homoeologue_desc = $homoeologue_map{$homoeologue->{'homology_desc'}} || $homoeologue->{'homology_desc'};
      
      # (Column 3) Add in the dN/dS ratio
      my $homoeologue_dnds_ratio = $homoeologue->{'homology_dnds_ratio'} || 'n/a';
         
      # (Column 4) Sort out 
      # (1) the link to the other species
      # (2) information about %ids
      # (3) links to multi-contigview and align view
      (my $spp = $homoeologue->{'spp'}) =~ tr/ /_/;
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
      
      if ($homoeologue_desc ne 'DWGA') {
        ($target, $query) = ($homoeologue->{'target_perc_id'}, $homoeologue->{'query_perc_id'});
       
        my $align_url = $hub->url({
            action   => 'Compara_Homoeolog',
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
          anc    => $homoeologue->{'gene_tree_node_id'},
          r      => undef
        })
      );
      
      # (Column 5) External ref and description
      my $description = encode_entities($homoeologue->{'description'});
         $description = 'No description' if $description eq 'NULL';
         
      if ($description =~ s/\[\w+:([-\/\w]+)\;\w+:(\w+)\]//g) {
        my ($edb, $acc) = ($1, $2);
        $description   .= sprintf '[Source: %s; acc: %s]', $edb, $hub->get_ExtURL_link($acc, $edb, $acc) if $acc;
      }
      
      my @external = (qq{<span class="small">$description</span>});
      
      if ($homoeologue->{'display_id'}) {
        if ($homoeologue->{'display_id'} eq 'Novel Ensembl prediction' && $description eq 'No description') {
          @external = ('<span class="small">-</span>');
        } else {
          unshift @external, $homoeologue->{'display_id'};
        }
      }

      my $id_info = qq{<p class="space-below"><a href="$link_url">$stable_id</a></p>} . join '<br />', @external;

      ## (Column 6) Location - split into elements to reduce horizonal space
      my $location_link = $hub->url({
        species => $spp,
        type    => 'Location',
        action  => 'View',
        r       => $homoeologue->{'location'},
        g       => $stable_id,
        __clear => 1
      });
      
      my $table_details = {
        'Species'    => join('<br />(', split /\s*\(/, $species_defs->species_label($species)),
        'Type'       => ucfirst $homoeologue_desc,
        'dN/dS'      => $homoeologue_dnds_ratio,
        'identifier' => $self->html_format ? $id_info : $stable_id,
        'Location'   => qq{<a href="$location_link">$homoeologue->{'location'}</a>},
        $column_name => $self->html_format ? qq{<span class="small">$target_links</span>} : $description,
        'Target %id' => $target,
        'Query %id'  => $query
      };      
      $table_details->{'Gene name(Xref)'}=$homoeologue->{'display_id'} if(!$self->html_format);
      
      push @rows, $table_details;
    }
  }
  
  my $table = $self->new_table($columns, \@rows, { data_table => 1, sorting => [ 'Species asc', 'Type asc' ], id => 'homoeologues' });
  
  if ($alignview && keys %homoeologue_list) {
    # PREpend
    $html = sprintf(q{
      <p>
        <a href="%s">View protein alignments of all homoeologues</a> &nbsp;|&nbsp;
        <a href="%s">View genomic alignments of all homoeologues</a>
      </p>}, 
      $hub->url({ action => 'Compara_Homoeolog', function => 'Alignment' . ($cdb =~ /pan/ ? '_pan_compara' : ''), }),
      $hub->url({'type' => 'Location', 'action' => 'MultiPolyploid'})
    ).$html;
    
  }
  
  $html .= $table->render;
  
  if (scalar keys %skipped) {
    my $count;
    $count += $_ for values %skipped;
    
    $html .= '<br />' . $self->_info(
      'homoeologues hidden by configuration',
      sprintf(
        '<p>%d homoeologues not shown in the table above from the following species. Use the "<strong>Configure this page</strong>" on the left to show them.<ul><li>%s</li></ul></p>',
        $count,
        join "</li>\n<li>", map "$_ ($skipped{$_})", sort keys %skipped
      )
    );
  }  
  return $html;
}

1;
