=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Draw::GlyphSet::genetree;

### Draws Gene/Compara_Tree (tree + alignments) and 
### Gene/SpeciesTree (tree only) images

use strict;

my $CURRENT_ROW;
my $CURRENT_Y;
my $MIN_ROW_HEIGHT = 20;
my $EXON_TICK_SIZE = 4;
my $EXON_TICK_COLOUR = "#333333";

sub _init {
  # Populate the canvas with feaures represented as glyphs
  my ($self) = @_;

  my $current_gene          = $self->{highlights}->[0];
  my $current_genome_db_id  = $self->{highlights}->[1] || ' ';
  my $collapsed_nodes_str   = $self->{highlights}->[2] || '';
  my $coloured_nodes        = $self->{highlights}->[3] || [];
  my $other_genome_db_id    = $self->{highlights}->[4];
  my $other_gene            = $self->{highlights}->[5];
  my $highlight_ancestor    = $self->{highlights}->[6];
  my $show_exons            = $self->{highlights}->[7];
  my $slice_cigar_lines     = $self->{highlights}->[8] || [];
  my $low_coverage_species  = $self->{highlights}->[9] || {};
## EG
  my $highlight_annotations   = $self->{highlights}->[8]; # EG
##
  my $tree          = $self->{'container'};
  my $Config        = $self->{'config'};
  my $bitmap_width = $Config->image_width(); 

  my $cdb = $Config->get_parameter('cdb');
  my $skey = $cdb =~ /pan/ ? "_pan_compara" : '';

# EG  manage GO highlighting
  my %highlight_map;
  my @hiterms;         
  my $highlight_param = undef;
  foreach (split(';',$highlight_annotations)){
    my ($acc,$colour,@genes_to_highlight) = split(',',$_);
    push(@hiterms,$acc);
    foreach my $gth (@genes_to_highlight){
      $highlight_map{$gth}=$colour;
    }
  }
  $highlight_param = join(',',@hiterms) if @hiterms;
# /EG

  $CURRENT_ROW = 1;
  $CURRENT_Y   = 1;
#  warn ("A-0:".localtime());

  # Handle collapsed/removed nodes
  my %collapsed_nodes = ( map{$_=>1} split( ',', $collapsed_nodes_str ) );  
  $self->{_collapsed_nodes} = \%collapsed_nodes;

  # $coloured_nodes is an array. It is sorted such as the largest clades
  # are used first. In case or a tie (i.e. all the genes are mammals and
  # vertebrates), the smallest clade overwrites the colour.
  foreach my $hash (@$coloured_nodes) {
    my $node_ids = $hash->{'node_ids'};
    my $mode = $hash->{'mode'};
    my $colour = $hash->{'colour'};
    my $clade = $hash->{'clade'};
    foreach my $node_id (@$node_ids) {
      $self->{"_${mode}_coloured_nodes"}->{$node_id} =
          {'clade' => $clade, 'colour' => $colour};
    }
  }
  
  # Create a sorted list of tree nodes sorted by rank then id
  my @nodes = ( sort { ($a->{_rank} <=> $b->{_rank}) * 10  
                           + ( $a->{_id} <=> $b->{_id}) } 
                @{$self->features($tree, 0, 0, 0, $show_exons, $slice_cigar_lines, $low_coverage_species) || [] } );

#  warn ("B-0:".localtime());

  #----------
  # Calculate pixel widths for the components of the image; 
  # +----------------------------------------------------+
  # | bitmap_width                                       |
  # | tree_width (60%)           | alignment_width (40%) |
  # | nodes_width | labels_width |                       |
  # +----------------------------------------------------+
  # Set 60% to the tree, and 40% to the alignments
  
  my $tree_bitmap_width  = $tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') ? int( $bitmap_width * 0.95 )  : int( $bitmap_width * 0.6 );
      
  my $align_bitmap_width = $bitmap_width - $tree_bitmap_width;
  # Calculate space to reserve for the labels
  my( $fontname, $fontsize ) = $self->get_font_details( 'small' );
  $fontsize = 7; # make default font size 7 instead of the 'small' font size of 6.4 which takes the floor value
  $fontsize = 8 if($tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode'));
  my( $longest_label ) = ( sort{ length($b) <=> length($a) } 
                           map{$_->{label}} @nodes );
  my @res = $self->get_text_width( 0, $longest_label, '', 
                                   'font'=>$fontname, 'ptsize' => $fontsize );
  my $font_height = $res[3];
  my $font_width  = $res[2];
  # And assign the rest to the nodes 
  my $labels_bitmap_width = $font_width;

  my $nodes_bitmap_width;
  #Need to decrease the node_width region by the number of nodes (width 5) to ensure the
  #labels don't extend into the alignment_width. Only noticable on Alignments (text) pages
  if ($tree->isa('Bio::EnsEMBL::Compara::GenomicAlignTree')) {
    #find the max_rank ie the highest number of nodes in a branch
    my $max_rank = (sort { $b->{_rank} <=> $a->{_rank} } @nodes)[0]->{_rank};
    $nodes_bitmap_width = $tree_bitmap_width-$labels_bitmap_width-($max_rank*5);
  } else {
    $nodes_bitmap_width = $tree_bitmap_width-$labels_bitmap_width;
  }

  #----------
  # Calculate phylogenetic distance to px scaling
  #my $max_distance = $tree->max_distance;
  # warn Data::Dumper::Dumper( @nodes );
  my( $max_x_offset ) = ( sort{ $b <=> $a }
                          map{$_->{_x_offset} + ($_->{_collapsed_distance}||0)}
                          @nodes );
                          
  my $nodes_scale = ($nodes_bitmap_width) / ($max_x_offset||1);
  #----------
  
  # Draw each node
  my %Nodes;
  map { $Nodes{$_->{_id}} = $_} @nodes;
  my @alignments;
  my @node_glyphs;
  my @bg_glyphs;
  my @labels;
  my $node_href;
  my $border_colour;
#use Data::Dumper; warn Dumper(@nodes);
  foreach my $f (@nodes) {
     # Ensure connector enters at base of node glyph
    my $parent_node = $Nodes{$f->{_parent}} || {x=>0};
    my $min_x = $parent_node->{x} + 4;

    $f->{_x_offset} = $max_x_offset if ($tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') && $f->{label});  #Align all the ending nodes with labels in the cafe tree
    ($f->{x}) = sort{$b<=>$a} int($f->{_x_offset} * $nodes_scale), $min_x;
    
    if ($f->{_cigar_line}){
      push @alignments, [ $f->{y} , $f->{_cigar_line}, $f->{_collapsed}, $f->{_aligned_exon_coords}] ;
    }

    # Node glyph, coloured for for duplication/speciation
    my ($node_colour, $label_colour, $collapsed_colour, $bold);
    
    if ($f->{_node_type} eq 'duplication') {
      $node_colour = 'red3';
    } elsif ($f->{_node_type} eq 'dubious') {
      $node_colour = 'turquoise';
    } elsif ($f->{_node_type} eq 'gene_split') {
      $node_colour = 'SandyBrown';
    } 
    #node colour categorisation for cafetree/speciestree/gainloss tree
    if($tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode')) {      
      $border_colour = 'black';
      $node_colour = 'grey' if($f->{_n_members} == 0 );      
      $node_colour = '#FEE391' if($f->{_n_members} >= 1 && $f->{_n_members} <= 5);
      $node_colour = '#FEC44F' if($f->{_n_members} >= 6 && $f->{_n_members} <= 10);
      $node_colour = '#FE9929' if($f->{_n_members} >= 11 && $f->{_n_members} <= 15);
      $node_colour = '#EC7014' if($f->{_n_members} >= 16 && $f->{_n_members} <= 20);
      $node_colour = '#CC4C02' if($f->{_n_members} >= 21 && $f->{_n_members} <= 25);
      $node_colour = '#8C2D04' if($f->{_n_members} >= 25);     
      
    }

    if ($f->{label}) {
      if( $f->{_genes}->{$other_gene} ){
        $bold = 1;
        $label_colour = "ff6666";
      } elsif( $f->{_genome_dbs}->{$other_genome_db_id} ){
        $bold = 1;
      } elsif( $f->{_genes}->{$current_gene} ){
        $label_colour     = 'red';
        $collapsed_colour = 'red';
        $node_colour = 'navyblue';
        $bold = defined($other_genome_db_id);
      } elsif( $f->{_genome_dbs}->{$current_genome_db_id} ){
        $label_colour     = 'blue';
        $collapsed_colour = 'navyblue';
        $bold = defined($other_genome_db_id);
      }
    }
    if ($f->{_fg_colour}) {
      # Use this foreground colour for this node if not already set
      $node_colour = $f->{_fg_colour} if (!$node_colour);
      $label_colour = $f->{_fg_colour} if (!$label_colour);
      $collapsed_colour = $f->{_fg_colour} if (!$collapsed_colour);
    }
    if ($highlight_ancestor and $highlight_ancestor == $f->{'_id'}) {
      $bold = 1;
    }
    $label_colour = 'red' if exists $f->{_subtree_ref};
    $label_colour = "red" if($tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') && $f->{label} =~ /$current_gene/ );
    $node_colour = "navyblue" if (!$node_colour); # Default colour
    $label_colour = "black" if (!$label_colour); # Default colour
    $collapsed_colour = 'grey' if (!$collapsed_colour); # Default colour

    #cafetree zmenu else comparatree zmenu
    if ($tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode')){
      $node_href = $self->_url({ 
        action      => "SpeciesTree",
        node        => $f->{'_id'},
        genetree_id => $Config->get_parameter('genetree_id'),
        ht          => $highlight_param,
        collapse    => $collapsed_nodes_str
      });
    } elsif (!$tree->isa('Bio::EnsEMBL::Compara::GenomicAlignTree')) {
      $node_href = $self->_url({ 
        action      => "ComparaTreeNode$skey",
        node        => $f->{'_id'},
        genetree_id => $Config->get_parameter('genetree_id'),
        ht          => $highlight_param,
        collapse    => $collapsed_nodes_str
      });
    }

    my $collapsed_xoffset = 0;
    if ($f->{_bg_colour}) {
      my $y = $f->{y_from} + 2;
      my $height = $f->{y_to} - $f->{y_from} - 1;
      my $x = $f->{x};
      my $width = $bitmap_width - $x - 5;
      push @bg_glyphs, $self->Rect({
            'x'      => $x,
            'y'      => $y,
            'width'  => $width,
            'height' => $height,
            'colour' => $f->{_bg_colour},
          });
    }
    if( $f->{_collapsed} ){ # Collapsed
      my $height = $f->{_height};
      my $width  = $f->{_collapsed_distance} * $nodes_scale + 10; 
      my $y = $f->{y} + 2;
      my $x = $f->{x} + 2;
      $collapsed_xoffset = $width;

      push @node_glyphs, $self->Poly({
            'points' => [ $x, $y,
                          $x + $width, $y - ($height / 2 ),
                          $x + $width, $y + ($height / 2 ) ],
            $f->{_collapsed_cut} ? ('patterncolour' => $collapsed_colour, 'pattern' => ($f->{_collapsed_cut} == 1 ? 'hatch_vert' : 'pin_vert'))
                                 : ('colour' => $collapsed_colour),
            'href'   => $node_href,
          });

      my $node_glyph = $self->Rect({
            'x'      => $f->{x},
            'y'      => $f->{y},
            'width'  => 5,
            'height' => 5,
            'colour' => $node_colour,
            'href'   => $node_href,
          });
      push @node_glyphs, $node_glyph;
      if ($f->{_node_type} eq 'gene_split') {
        push @node_glyphs, $self->Rect({
              'x'         => $f->{x},
              'y'         => $f->{y},
              'width'     => 5,
              'height'    => 5,
              'bordercolour' => 'navyblue',
              'href'      => $node_href,
            });
      }

    }
    elsif( $f->{_child_count} ){ # Expanded internal node   
# Draw n_members label on top of the node
      $f->{_n_members} = ($tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') && !$f->{_n_members}) ? '0 ' : $f->{_n_members}; #adding a space hack to get it display 0 as label
      my $nodes_label = $self->Text
          ({
            'text'       => $f->{_n_members},
            'height'     => $font_height,
            'width'      => $labels_bitmap_width,
            'font'       => $fontname,
            'ptsize'     => $fontsize,
            'halign'     => 'left',
            'colour'     => $label_colour,            
            'y' => $f->{y}-10,
            'x' => $f->{x}-10,
            'zindex' => 40,
  	  });
      push(@labels, $nodes_label);
      
      # Add a 'collapse' href
      my $node_glyph = $self->Rect({
            'x'         => $f->{x} - $bold,
            'y'         => $f->{y} - $bold,
            'width'     => 5 + 2 * $bold,
            'height'    => 5 + 2 * $bold,
            'colour'    => $node_colour,
            'bordercolour' => $tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') ? 'black' : $node_colour,            
            'zindex'    => ($f->{_node_type} ne 'speciation' ? 40 : -20),
            'href'      => $node_href
          });
      push @node_glyphs, $node_glyph;
      if ($bold) {
        my $node_glyph = $self->Rect({
              'x'         => $f->{x},
              'y'         => $f->{y},
              'width'     => 5,
              'height'    => 5,
              'bordercolour' => "white",
              'zindex'    => ($f->{_node_type} ne 'speciation' ? 40 : -20),
              'href'      => $node_href
            });
        push @node_glyphs, $node_glyph;
      }
      if ($f->{_node_type} eq 'gene_split') {
        push @node_glyphs, $self->Rect({
              'x'         => $f->{x},
              'y'         => $f->{y},
              'width'     => 5,
              'height'    => 5,
              'bordercolour' => 'navyblue',
              'zindex'    => -20,
              'href'      => $node_href,
            });
      }

    }
    else{ # Leaf node  
    my $type = $f->{_node_type};
    
    my $colour = $tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') ? $node_colour : '';
    my $bordercolour = $tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') ? "black" : $node_colour;
    
      push @node_glyphs, $self->Rect({
            'x'         => $f->{x},
            'y'         => $f->{y},
            'width'     => 5,
            'height'    => 5,
            'colour'    => $tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') ? $node_colour : 'white',
            'bordercolour' => $tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') ? "black" : $bordercolour,
            'zindex'    => -20,
            'href'      => $node_href,
          });
    }
    
    # Leaf label or collapsed node label, coloured for focus gene/species
    if ($f->{label}) {
      $label_colour = ($tree->isa('Bio::EnsEMBL::Compara::CAFEGeneFamilyNode') && !$f->{_n_members}) ? 'Grey' : $label_colour;      
      # Draw the label      
      my $txt = $self->Text
          ({
            'text'       => $f->{label},
            'height'     => $font_height,
            'width'      => $labels_bitmap_width,
            'font'       => $fontname,
            'ptsize'     => $fontsize,
            'halign'     => 'left',
            'colour'     => $label_colour,            
            'y' => $f->{y} - int($font_height/2),
            'x' => $f->{x} + 10 + $collapsed_xoffset,
            'zindex' => 40,
	    });
## EG
      my @highlight_matches = ();
      map { push (@highlight_matches,$highlight_map{$_}) if exists $highlight_map{$_}} keys %{$f->{'_genes'}};
      if( @highlight_matches ){
        my $label_highlight = EnsEMBL::Draw::Glyph::Rect->new
            ({
              'height'     => $font_height + 2,
              'width'      => $labels_bitmap_width,
              'colour'     => $highlight_matches[0],
              'y' => $f->{y} - int($font_height/2) - 1,
              'x' => $f->{x} + 10 + $collapsed_xoffset,
              'zindex' => -100,
            });
        push(@labels, $label_highlight);
      }
      else{
      } 
## /EG

      # use a higher font size is bold 
      $txt->{'ptsize'} = 8 if $bold == 1;

      # use even a higher font size if label colour is either red or light red
      $txt->{'ptsize'} = 9 if $label_colour eq 'red';
      $txt->{'ptsize'} = 9 if $label_colour eq 'ff6666';
      
      if ($f->{'_gene'}) {
        $txt->{'href'} = $self->_url({
          species  => $f->{'_species'},
          type     => 'Gene',
          action   => 'ComparaTree',
          __clear  => 1,
          g        => $f->{'_gene'}
        });
      } elsif (exists $f->{_subtree}) {
        $txt->{'href'} = $node_href;
      } elsif ($f->{'_gat'}) {
          $txt->{'colour'} = $f->{'_gat'}{'colour'};
      }
      
      push(@labels, $txt);


    }
  }
  
  $self->push( @bg_glyphs );

  my $max_x = (sort {$a->{x} <=> $b->{x}} @nodes)[-1]->{x};
  my $min_y = (sort {$a->{y} <=> $b->{y}} @nodes)[0]->{y};

#  warn ("MAX X: $max_x" );
#  warn ("C-0:".localtime());

  #----------
  # DRAW THE TREE CONNECTORS
  $self->_draw_tree_connectors(%Nodes);


  # Push the nodes afterwards, so they show above the connectors
  $self->push( @node_glyphs );
  $self->push(@labels);

  #----------
  # DRAW THE ALIGNMENTS
  # Display only those gaps that amount to more than 1 pixel on screen, 
  # otherwise screen gets white when you zoom out too much .. 

  # Global alignment settings
  my $fy = $min_y;  
  #my $alignment_start  = $max_x + $labels_bitmap_width + 20;
  #my $alignment_width  = $bitmap_width - $alignment_start;
  my $alignment_start  = $tree_bitmap_width;
  my $alignment_width  = $align_bitmap_width - 20;
  my $alignment_length = 0;

  #Find the alignment length from the first alignment
  my @cigar = grep {$_} split(/(\d*[GDMmXI])/, $alignments[0]->[1]);
  for my $cigElem ( @cigar ) {
    my $cigType = substr( $cigElem, -1, 1 );
    my $cigCount = substr( $cigElem, 0 ,-1 );
    $cigCount = 1 unless ($cigCount =~ /^\d+$/);
    #Do not include I in the alignment length
    if ($cigType =~ /[GDMmX]/) {
      $alignment_length += $cigCount;
    }
  }
  $alignment_length ||= $alignment_width; # All nodes collapsed
  my $min_length      = int($alignment_length / $alignment_width);   
  my $alignment_scale = $alignment_width / $alignment_length;   
  #warn("==> AL: START: $alignment_start, LENGTH: $alignment_length, ",
  #      "WIDTH: $alignment_width, MIN: $min_length");    
  foreach my $a (@alignments) {
    if(@$a) {        
      my ($yc, $al, $collapsed, $exon_coords) = @$a;
  
      # Draw the exon splits under the boxes
      foreach my $exon_end (@$exon_coords) {
        my $e = $self->Line({
          'x'         => $alignment_start + $exon_end * $alignment_scale,
          'y'         => $yc - 3 - $EXON_TICK_SIZE,
          'width'     => 0,
          'height'    => $font_height + (2 * $EXON_TICK_SIZE),
          'colour'    => $EXON_TICK_COLOUR,
          'zindex' => 0,
        });
  
        $self->push( $e );
      }
      #Use a different colour for DNA (GenomicAlignTree) and proteins
      my $box_colour;
      if ($tree->isa('Bio::EnsEMBL::Compara::GenomicAlignTree')) {
        $box_colour = '#3366FF'; #blue
      } else {
         $box_colour = $collapsed ? 'darkgreen' : 'yellowgreen';
      }

      my $t = $self->Rect({
        'x'         => $alignment_start,
        'y'         => $yc - 3,
        'width'     => $alignment_width,
        'height'    => $font_height,
        'colour'    => $box_colour,
        'zindex' => 0,
      });
  
      $self->push( $t );
  
  
      my @inters = split (/([MmDGXI])/, $al);
      my $ms = 0;
      my $ds = 0;
      my $box_start = 0;
      my $box_end = 0;
      my $colour = 'white';
      my $zc = 10;
      
      while (@inters) {
        $ms = (shift (@inters) || 1);
        my $mtype = shift (@inters);

        #Skip I elements
        next if ($mtype eq "I");
        
        $box_end = $box_start + $ms -1;
        
        if ($mtype =~ /G|M/) {
  # Skip normal alignment and gaps in alignments
          $box_start = $box_end + 1;
          next;
        }
        
        if ($ms >= $min_length ) { 
          my $t = $self->Rect({
            'x'         => $alignment_start + ($box_start * $alignment_scale),
            'y'         => $yc - 2,
            'z'         => $zc,
            'width'     => abs( $box_end - $box_start + 1 ) * $alignment_scale,
            'height'    => $font_height - 2,
            'colour' => ($mtype eq "m"?"yellowgreen":$colour), 
            'absolutey' => 1,
          });
          
          $self->push($t);
        }
        $box_start = $box_end + 1;
      }
    }
  }

#  warn ("E-0:".localtime());
  return 1;
}

1;