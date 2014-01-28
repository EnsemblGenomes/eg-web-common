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

package EnsEMBL::Web::Component::Gene::FamilyGenes;

### Displays information about all genes belonging to a protein family

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Gene);
use Data::Dumper;
use EnsEMBL::Web::Document::Table;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  1 );
}

# Check why compara_pan_ensembl is not passed
sub content {
  my $self = shift;
  my $hub          = $self->hub;
  my $cdb = shift || $hub->param('cdb') || 'compara_pan_ensembl';
  my $object = $self->object;
  my $species = $object->species;
  my $family_id = $object->param('family');
  my $spath = $object->species_defs->species_path($species);
  my $html = undef;


  if ($family_id) {

    $html .= "<h4>Ensembl genes containing proteins in family $family_id</h4>\n";
    my $families = $object->get_all_families($cdb);


    my $genes = $families->{$family_id}{'info'}{'genes'} || [];

    ## Karyotype (optional)
    if (@{$object->species_defs->ENSEMBL_CHROMOSOMES}) {

      $object->param('aggregate_colour', 'red'); ## Fake CGI param - easiest way to pass this parameter
      my $karyotype = undef;
      my $current_gene = $object->param('g') || '';

      my $image    = $self->new_karyotype_image();

      $image->image_type = "family";
      $image->image_name = "$species-".$family_id;
      $image->imagemap = 'yes';
      $image->set_button('drag', 'title' => 'Click or drag to jump to a region' );
##      unless( $image->exists ) {
        my %high = ( 'style' => 'arrow' );
        foreach my $g (grep {$_} @$genes){
          my $stable_id = $g->stable_id;
          my $chr       = $g->slice->seq_region_name;
          my $start     = $g->start;
          my $end       = $g->end;
          my $colour = $stable_id eq $current_gene ? 'red' : 'blue';
          my $point = {
            'start' => $start,
            'end'   => $end,
            'col'   => $colour,
            'zmenu' => {
            'caption'               => 'Genes',
            "00:$stable_id"         => "$spath/Gene/Summary?g=$stable_id",
            '01:Jump to contigview' => "$spath/Location/View?r=$chr:$start-$end;g=$stable_id"
            }
          };
          if(exists $high{$chr}) {
            push @{$high{$chr}}, $point;
          } 
          else {
            $high{$chr} = [ $point ];
          }
        }
      $image->karyotype($self->hub, $object, [ \%high ]);

##      }
      $html .= $image->render if $image;
    }

    if (grep {$_} @$genes) {
      ## Table of gene info
      my $table = new EnsEMBL::Web::Document::Table( [], [], {'margin' => '1em 0px'} );
      $table->add_columns( 
        {'key' => 'id',   'title' => 'Gene ID and Location', 'width' => '30%', 'align' => 'center'},
        {'key' => 'name', 'title' => 'Gene Name',            'width' => '20%', 'align' => 'center'},
        {'key' => 'desc', 'title' => 'Description(if known)','width' => '50%', 'align' => 'left'}
      );
      foreach my $gene ( sort { $object->seq_region_sort( $a->seq_region_name, $b->seq_region_name ) ||
                            $a->seq_region_start <=> $b->seq_region_start } grep {$_} @$genes ) {
      
        my $row = {};
        $row->{'id'} = sprintf '<a href="%s/Gene/Summary?g=%s" title="More about this gene">%s</a><br /><a href="%s/Location/View?r=%s:%s-%s" title="View this location on the genome" class="small" style="text-decoration:none">%s: %s</a>',
                $spath, $gene->stable_id, $gene->stable_id,
                $spath, $gene->slice->seq_region_name, $gene->start, $gene->end,
                $self->neat_sr_name($gene->slice->coord_system->name, $gene->slice->seq_region_name), 
                $object->round_bp( $gene->start );
        my $xref = $gene->display_xref;
        if( $xref ) {
          $row->{'name'} = $hub->get_ExtURL_link( $xref->display_id, $xref->dbname, $xref->primary_id);
        } 
        else {
          $row->{'name'} = '-novel-';
        }
        $row->{'desc'} = $object->gene_description($gene);
        $table->add_row($row);
      }
      $html .= $table->render;
    }
  }

  return $html;
}

1;
