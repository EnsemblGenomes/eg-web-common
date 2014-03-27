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

package Bio::EnsEMBL::GlyphSet_transcript;

use strict;

use List::Util qw(min max);
use Clone qw(clone);

sub get_gene_joins {
    my ($self, $gene, $species, $join_types, $source) = @_;

    my $config     = $self->{'config'};
    my $compara_db = $config->hub->database('compara');
    return unless $compara_db;

    my $ma = $compara_db->get_MemberAdaptor;
    return unless $ma;

    my $qy_member = $ma->fetch_by_source_stable_id($source, $gene->stable_id);
    return unless defined $qy_member;

    my $method = $config->get_parameter('force_homologue') || $species eq $config->{'species'} ? $config->get_parameter('homologue') : undef;
    my $func   = $source ? 'get_homologous_peptide_ids_from_gene' : 'get_homologous_gene_ids';

    return $self->$func($species, $join_types, $compara_db->get_HomologyAdaptor, $qy_member, $method ? [ $method ] : undef);
}

sub render_collapsed {
  my ($self, $labels) = @_;

  return $self->render_text('transcript', 'collapsed') if $self->{'text_export'};
  
  my $config           = $self->{'config'};
  my $container        = $self->{'container'}{'ref'} || $self->{'container'};
  my $length           = $container->length;
  my $is_circular      = $container->is_circular;
  my $pix_per_bp       = $self->scalex;
  my $strand           = $self->strand;
  my $selected_db      = $self->core('db');
  my $selected_gene    = $self->my_config('g') || $self->core('g');
  my $strand_flag      = $self->my_config('strand');
  my $db               = $self->my_config('db');
  my $show_labels      = $self->my_config('show_labels');
  my $previous_species = $self->my_config('previous_species');
  my $next_species     = $self->my_config('next_species');
  my $previous_target  = $self->my_config('previous_target');
  my $next_target      = $self->my_config('next_target');
  my $join_types       = $self->get_parameter('join_types');
  my $link             = $self->get_parameter('compara') ? $self->my_config('join') : 0;
  my $alt_alleles_col  = $self->my_colour('alt_alleles_join');
  my $y                = 0;
  my $h                = 8;
  my $join_z           = 1000;
  my $transcript_drawn = 0;
  my %used_colours;

  my $start_point = $container->start;
  my $end_point = $container->end;
  my $reg_end = $container->seq_region_length;
  my $addition = 0;

  
  my ($fontname, $fontsize) = $self->get_font_details('outertext');
  
  $self->_init_bump;
  
  my $th = ($self->get_text_width(0, 'Xg', 'Xg', 'ptsize' => $fontsize, 'font' => $fontname))[3];
  
  my ($genes, $highlights, $transcripts, $exons) = $self->features;

## EG
  # copy genes that cross the origin so that they are drawn on both sides
  # HACK: set a flag on the copied object so we know that we should draw it's exons 
  # in the translated position
  if ($is_circular) {
    foreach my $gene (grep {$_->start < 0} @$genes) {
      my $copy = clone($gene);
      $copy->{_draw_translated} = 1;
      push @$genes, $copy;
    }
  }
##  
  
  foreach my $gene (@$genes) {
    my $gene_stable_id = $gene->stable_id;
    my $gene_strand    = $gene->strand;
    
    next if $gene_strand != $strand && $strand_flag eq 'b';
    
    $transcript_drawn = 1;
    
    my @exons      = map { $_->start > $length || $_->end < 1 ? () : $_ } @{$exons->{$gene_stable_id}}; # Get all the exons which overlap the region for this gene
    my $colour_key = $self->colour_key($gene);
    my $colour     = $self->my_colour($colour_key);
# EG
#   my $label      = $self->my_colour($colour_key, 'text');
    my $label = $self->colour_label($gene);
## 

    $used_colours{$label} = $colour;
    
    my $composite = $self->Composite({
      y      => $y,
      height => $h,
      title  => $self->gene_title($gene),
      href   => $self->href($gene)
    });
    
    my $composite2 = $self->Composite({ y => $y, height => $h });
    
    foreach my $exon (@exons) {

      if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)) {
        $addition = $reg_end - $start_point + 1;
      } elsif ($gene->{_draw_translated}) {
        $addition = $reg_end + $start_point + 1;
      } else { 
        $addition = 0;
      }
      
      my $s = $exon->start;
      $s = 1 if $exon->start < 1 and !$gene->{_draw_translated};
      my $e = min($exon->end, $length);
      
      $composite2->push($self->Rect({
        x         => $s + $addition - 1,
        y         => $y,
        width     => $e - $s + 1,
        height    => $h,
        colour    => $colour,
        absolutey => 1
      }));
    }
    
    my $start = max($gene->start, 1);
    my $end   = $gene->end > $length ? $length : $gene->end;
    
    $composite2->push($self->Rect({
      x         => $start + $addition - 1, 
      y         => int($y + $h/2), 
      width     => $end - $start + 1,
      height    => 0.4, 
      colour    => $colour, 
      absolutey => 1
    }));

    if ($link) {
      if ($gene_stable_id) {
        my $alt_alleles     = $gene->get_all_alt_alleles;
        my $seq_region_name = $gene->slice->seq_region_name;
        my ($target, @gene_tags);
        
        if ($previous_species) {
          for ($self->get_gene_joins($gene, $previous_species, $join_types)) {
            $target = $previous_target ? ":$seq_region_name:$previous_target" : '';
            
            $self->join_tag($composite2, "$gene_stable_id:$_->[0]$target", 0.5, 0.5, $_->[1], 'line', $join_z);
            
            $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
            $config->{'legend_features'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
          }
          
          push @gene_tags, map { join '=', $_->stable_id, $gene_stable_id } @{$self->filter_by_target($alt_alleles, $previous_target)};
        }

        if ($next_species) {
          for ($self->get_gene_joins($gene, $next_species, $join_types)) {
            $target = $next_target ? ":$next_target:$seq_region_name" : '';
            
            $self->join_tag($composite2, "$_->[0]:$gene_stable_id$target", 0.5, 0.5, $_->[1], 'line', $join_z);
            
            $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
            $config->{'legend_features'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
          }
          
          push @gene_tags, map { join '=', $gene_stable_id, $_->stable_id } @{$self->filter_by_target($alt_alleles, $next_target)};
        }
        
        $self->join_tag($composite2, $_, 0.5, 0.5, $alt_alleles_col, 'line', $join_z) for @gene_tags; # join alt_alleles
        
        if (@gene_tags) {
          $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
          $config->{'legend_features'}{'joins'}{'legend'}{'Alternative alleles'} = $alt_alleles_col;
        }
      }
    }
    
    $composite->push($composite2);
    
    my $bump_height = $h + 2;
    
    if ($show_labels ne 'off' && $labels) {
      if (my $label = $self->feature_label($gene)) {
        my @lines = split "\n", $label;
        
        for (my $i = 0; $i < @lines; $i++){
          my $line = "$lines[$i] ";
          my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
          
          $composite->push($self->Text({
            x         => $composite->x,
            y         => $y + $h + $i * ($th + 1),
            height    => $th,
            width     => $w / $pix_per_bp,
            font      => $fontname,
            ptsize    => $fontsize,
            halign    => 'left',
            colour    => $colour,
            text      => $line,
            absolutey => 1
          }));
          
          $bump_height += $th + 1;
        }
      }
    }
    
    # bump
    my $bump_start = int($composite->x * $pix_per_bp);
    my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
    
    my $row = $self->bump_row($bump_start, $bump_end);
    
    # shift the composite container by however much we're bumped
    $composite->y($composite->y - $strand * $bump_height * $row);
    $composite->colour($highlights->{$gene_stable_id}) if $highlights->{$gene_stable_id};
    $self->push($composite);
  }

  if ($transcript_drawn) {
    my $type = $self->my_config('name');
    my %legend_old = @{$config->{'legend_features'}{$type}{'legend'}||[]};
    
    $used_colours{$_} = $legend_old{$_} for keys %legend_old;
    
    my @legend = %used_colours;
    
    $config->{'legend_features'}{$type} = {
      priority => $self->_pos,
      legend   => \@legend
    };
  } elsif ($config->get_option('opt_empty_tracks') != 0) {
    $self->errorTrack(sprintf 'No %s in this region', $self->error_track_name);
  }
}

sub render_transcripts {
  my ($self, $labels) = @_;

  return $self->render_text('transcript') if $self->{'text_export'};
  
  my $config            = $self->{'config'};
  my $container         = $self->{'container'}{'ref'} || $self->{'container'};
  my $length            = $container->length;
  my $is_circular       = $container->is_circular;

  my $start_point = $container->start;
  my $end_point = $container->end;
  my $reg_end = $container->seq_region_length;
  my $addition = 0;

  my $pix_per_bp        = $self->scalex;
  my $strand            = $self->strand;
  my $selected_db       = $self->core('db');
  my $selected_trans    = $self->core('t') || $self->core('pt') ;
  my $selected_gene     = $self->my_config('g') || $self->core('g');
  my $strand_flag       = $self->my_config('strand');
  my $db                = $self->my_config('db');
  my $show_labels       = $self->my_config('show_labels');
  my $previous_species  = $self->my_config('previous_species');
  my $next_species      = $self->my_config('next_species');
  my $previous_target   = $self->my_config('previous_target');
  my $next_target       = $self->my_config('next_target');
  my $join_types        = $self->get_parameter('join_types');
  my $link              = $self->get_parameter('compara') ? $self->my_config('join') : 0;
  my $target            = $self->get_parameter('single_Transcript');
  my $target_gene       = $self->get_parameter('single_Gene');
  my $alt_alleles_col   = $self->my_colour('alt_alleles_join');
  my $y                 = 0;
  my $h                 = $self->my_config('height') || ($target ? 30 : 8); # Single transcript mode - set height to 30 - width to 8
  my $join_z            = 1000;
  my $transcript_drawn  = 0;
  my $non_coding_height = ($self->my_config('non_coding_scale')||0.75) * $h;
  my $non_coding_start  = ($h - $non_coding_height) / 2;
  my %used_colours;
  my $label_operon_genes = $self->my_config('label_operon_genes');
  my $no_operons         = $self->my_config('no_operons')||$target;
  
  my ($fontname, $fontsize) = $self->get_font_details('outertext');
  my $th = ($self->get_text_width(0, 'Xg', 'Xg', 'ptsize' => $fontsize, 'font' => $fontname))[3];
  
  $self->_init_bump;
  
  my ($genes_to_filter, $highlights, $transcripts, $exons) = $self->features;
  my %operons;
  my $genes = [];
  my %singleton_genes;
  my @operons_to_draw;

  if($no_operons || !$container->can('get_all_Operons')){
    @$genes = @$genes_to_filter;
    $genes_to_filter = [];
  }
  else{
    foreach my $gene (@$genes_to_filter) {
      my @ops = @{$gene->feature_Slice->get_all_Operons};
      unless(0<@ops){
        $singleton_genes{$gene->dbID}=$gene;
      }
    }
    # Don't restrict by logic name as we don't know the logic names for the operons
    # this may need revisiting in future if we have operons from multiple sources
    #foreach my $_logic_name(@{$self->my_config('logic_names')||[]}){
      #my @ops = @{$container->get_all_Operons($_logic_name,undef,1)};
      my @ops = @{$container->get_all_Operons};
      foreach my $opn (@ops){
        next if ($operons{$opn->dbID});
        $opn = $opn->transfer($container);
        $operons{$opn->dbID}=1;
        push(@operons_to_draw,$opn);
        foreach my $ots(@{$opn->get_all_OperonTranscripts}){
          foreach my $gene(@{$ots->get_all_Genes}){
            delete $singleton_genes{$gene->dbID};
          }
        }
      }
    #}
    @$genes = map {$singleton_genes{$_}} keys %singleton_genes;
  }

## EG
  # copy genes that cross the origin so that they are drawn on both sides
  # HACK: set a flag on the copied object so we know that we should draw it's exons 
  # in the translated position
  if ($is_circular) {
    foreach my $gene (grep {$_->start < 0} @$genes) {
      my $copy = clone($gene);
      $copy->{_draw_translated} = 1;
      push @$genes, $copy;
    }
  }
##    
  
  foreach my $gene (@$genes) {
    my $gene_strand    = $gene->strand;
    my $gene_stable_id = $gene->can('stable_id') ? $gene->stable_id : undef;
    
    next if $gene_strand != $strand && $strand_flag eq 'b'; # skip features on wrong strand
    next if $target_gene && $gene_stable_id ne $target_gene;
    
    my (%tags, @gene_tags, $tsid);
    
    if ($link && $gene_stable_id) {
      my $alt_alleles = $gene->get_all_alt_alleles;
      my $alltrans    = $gene->get_all_Transcripts; # vega stuff to link alt-alleles on longest transcript
      my @s_alltrans  = sort { $a->length <=> $b->length } @$alltrans;
      my $long_trans  = pop @s_alltrans;
      my @transcripts;
      
      $tsid = $long_trans->stable_id;
      
      foreach my $gene (@$alt_alleles) {
        my $vtranscripts = $gene->get_all_Transcripts;
        my @sorted_trans = sort { $a->length <=> $b->length } @$vtranscripts;
        push @transcripts, (pop @sorted_trans);
      }
      

      if ($previous_species) {
    my ($peptide_id, $homologues, $homologue_genes) = $self->get_gene_joins($gene, $previous_species, $join_types, 'ENSEMBLGENE');

    if ($peptide_id) {
        push @{$tags{$peptide_id}}, map {[ "$_->[0]:$peptide_id",     $_->[1] ]} @$homologues;
        push @{$tags{$peptide_id}}, map {[ "$gene_stable_id:$_->[0]", $_->[1] ]} @$homologue_genes;
    }

    push @gene_tags, map { join '=', $_->stable_id, $tsid } @{$self->filter_by_target(\@transcripts, $previous_target)};

    for (@$homologues) {
        $self->{'legend'}{'gene_legend'}{'joins'}{'priority'} ||= 1000;
        $self->{'legend'}{'gene_legend'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
    }
      }

      if ($next_species) {
    my ($peptide_id, $homologues, $homologue_genes) = $self->get_gene_joins($gene, $next_species, $join_types, 'ENSEMBLGENE');

    if ($peptide_id) {
        push @{$tags{$peptide_id}}, map {[ "$peptide_id:$_->[0]",     $_->[1] ]} @$homologues;
        push @{$tags{$peptide_id}}, map {[ "$_->[0]:$gene_stable_id", $_->[1] ]} @$homologue_genes;
    }

    push @gene_tags, map { join '=', $tsid, $_->stable_id } @{$self->filter_by_target(\@transcripts, $next_target)};

    for (@$homologues) {
        $self->{'legend'}{'gene_legend'}{'joins'}{'priority'} ||= 1000;
        $self->{'legend'}{'gene_legend'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
    }
      }


    }
    
# EG     
#   my $thash;
##

    my @sorted_transcripts = map $_->[1], sort { $b->[0] <=> $a->[0] } map [ $_->start * $gene_strand, $_ ], @{$transcripts->{$gene_stable_id}};
    
    foreach my $transcript (@sorted_transcripts) {
      my $transcript_stable_id = $transcript->stable_id;
      
      next if $transcript->start > $length || $transcript->end < 1;
      next if $target && $transcript_stable_id ne $target; # For exon_structure diagram only given transcript
      next unless $exons->{$transcript_stable_id};          # Skip if no exons for this transcript
      
      my @exons = @{$exons->{$transcript_stable_id}};
# EG     
     if($gene->adaptor){ # don't try this if there is no adaptor...
        # we need this - sometimes the transcript object doesn't have all the translations
        my $_tsa = $gene->adaptor->db->get_adaptor('transcript');
        $transcript = $_tsa->fetch_by_stable_id($transcript_stable_id);
        $transcript = $transcript->transfer($gene->slice);
     }
      #next if $transcript->start > $length || $transcript->end < 1;
      my @alt_translations = sort { $a->genomic_start <=> $b->genomic_start }  @{$transcript->get_all_alternative_translations};
      my $numTranslations=1+scalar @alt_translations;
      
      next if $exons[0][0]->strand != $gene_strand && $self->{'do_not_strand'} != 1; # If stranded diagram skip if on wrong strand
      next if $target && $transcript->stable_id ne $target; # For exon_structure diagram only given transcript
# /EG     
      $transcript_drawn = 1;        

      my $composite = $self->Composite({
        y      => $y,
        height => $h,
        title  => $self->title($transcript, $gene),
        href   => $self->href($gene, $transcript),
        class  => 'group',
      });

      my $colour_key = $self->colour_key($gene, $transcript);
      my $colour     = $self->my_colour($colour_key);
# EG #my $label      = $self->my_colour($colour_key, 'text');
      my $label = $self->colour_label($gene, $transcript);
# /EG 
      ($colour, $label) = ('orange', 'Other') unless $colour;
      $used_colours{$label} = $colour;
# EG
      my $coding_start = defined $transcript->coding_region_start ? $transcript->coding_region_start : -1e6;
      my $coding_end   = defined $transcript->coding_region_end   ? $transcript->coding_region_end   : -1e6;
# /EG 
      my $composite2 = $self->Composite({ y => $y, height => $h });
            
      if ($transcript->translation) {
        $self->join_tag($composite2, $_->[0], 0.5, 0.5, $_->[1], 'line', $join_z) for @{$tags{$transcript->translation->stable_id}||[]};
      }
      
      if ($transcript->stable_id eq $tsid) {
        $self->join_tag($composite2, $_, 0.5, 0.5, $alt_alleles_col, 'line', $join_z) for @gene_tags;
        
        if (@gene_tags) {
          $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
          $config->{'legend_features'}{'joins'}{'legend'}{'Alternative alleles'} = $alt_alleles_col;
        }
      }
# EG: render multiple translations
      my %composites;#one for each translation
      
      for (my $i = 0; $i < @exons; $i++) {
        my $exon = $exons[$i][0];
        
        next unless defined $exon; # Skip this exon if it is not defined (can happen w/ genscans) 
        
        my $next_exon = ($i < $#exons) ? $exons[$i+1][0] : undef; # First draw the exon
        
        last if $exon->start > $length; # We are finished if this exon starts outside the slice
        
        my ($box_start, $box_end);
        
        # only draw this exon if is inside the slice
        if ($exon->end > -$addition) {
          # calculate exon region within boundaries of slice
          if(($start_point>$end_point) && ($gene->slice->end == $end_point)  && ($gene->slice->start != $start_point)) {
             $addition = $reg_end - $start_point + 1;
          } elsif ($gene->{_draw_translated}) {
             $addition = $reg_end + $start_point + 1;
          } else {           
             $addition = 0;
          }
          
          my $min_start = -$addition + 1;
          
          $box_start = $exon->start;
          $box_start = $min_start if $box_start < $min_start;
          $box_end = $exon->end;
          $box_end = $length if $box_end > $length;
          # The start of the transcript is before the start of the coding
          # region OR the end of the transcript is after the end of the
          # coding regions.  Non coding portions of exons, are drawn as
          # non-filled rectangles
          # Draw a non-filled rectangle around the entire exon
    
          if ($box_start < $coding_start || $box_end > $coding_end) {
            $composite2->push($self->Rect({
              x            => $box_start + $addition - 1,
              y            => $y + $non_coding_start,
              width        => $box_end - $box_start  + 1,
              height       => $non_coding_height,
              bordercolour => $colour,
              absolutey    => 1
             }));
           }
           
           # Calculate and draw the coding region of the exon
           my $filled_start = $box_start < $coding_start ? $coding_start : $box_start;
           my $filled_end   = $box_end > $coding_end ? $coding_end : $box_end;
                      
           # only draw the coding region if there is such a region
           if ($filled_start <= $filled_end ) {
              # Draw a filled rectangle in the coding region of the exon
              $composite2->push($self->Rect({
                x         => $filled_start + $addition - 1,
                y         => $y,
                width     => $filled_end - $filled_start + 1,
                height    => $h/$numTranslations,
                colour    => $colour,
                absolutey => 1
              }));
          }
          my $translationIndex=1;
          foreach my $alt_translation (@alt_translations){
            my $t_coding_start=$alt_translation->genomic_start;
            my $t_coding_end=$alt_translation->genomic_end;
            # Calculate and draw the coding region of the exon
            my $t_filled_start = $box_start < $t_coding_start ? $t_coding_start : $box_start;
            my $t_filled_end   = $box_end > $t_coding_end     ? $t_coding_end   : $box_end;
            # only draw the coding region if there is such a region
            # Draw a filled rectangle in the coding region of the exon
            if ($t_filled_start <= $t_filled_end) {
              $composites{$alt_translation->stable_id} = $self->Composite({ y => $y, height => $h }) unless defined $composites{$alt_translation->stable_id};
              my $_y= (int(10 * ($y + $translationIndex * $h/$numTranslations)))/10;
              my $_h= (int(10 * ($h/$numTranslations)))/10;
              $composites{$alt_translation->stable_id}->push(
                $self->Rect({
                 x         => abs($t_filled_start + $addition - 1),
                 width     => abs($t_filled_end - $t_filled_start + 1),
                 y         => $_y,
                 height    => $_h,
                 colour => $colour,
                 bordercolour => 'black',
                 absolutey => 1,
                 absolutex => 0
                 }
                )
              );
            }
            $translationIndex++;
          }
        }
        
        # we are finished if there is no other exon defined
        last unless defined $next_exon;
        
        next if $next_exon->dbID eq $exon->dbID;
        
        my $intron_start = $exon->end + 1; # calculate the start and end of this intron
        my $intron_end   = $next_exon->start - 1;
        
        next if $intron_end < 0;         # grab the next exon if this intron is before the slice
        last if $intron_start > $length; # we are done if this intron is after the slice

        if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)) {
            $addition = $reg_end - $start_point + 1;
          #if ($exon->slice->is_circular) {
          # $addition = 0;
          #}
        } else {
            $addition = 0;
        }
        
        # calculate intron region within slice boundaries
        $box_start = $intron_start < 1 ? 1 : $intron_start;
        $box_end   = $intron_end > $length ? $length : $intron_end;
        
        my $intron;
        
        if ($box_start == $intron_start && $box_end == $intron_end) {
          # draw an wholly in slice intron
          $composite2->push($self->Intron({
            x         => $box_start + $addition - 1,
            y         => $y,
            width     => $box_end - $box_start + 1,
            height    => $h,
            colour    => $colour,
            absolutey => 1,
            strand    => $strand
          }));
        } else { 
          # else draw a "not in slice" intron
          $composite2->push($self->Line({
            x         => $box_start + $addition - 1 ,
            y         => $y + int($h/2),
            width     => $box_end - $box_start + 1,
            height    => 0,
            absolutey => 1,
            colour    => $colour,
            dotted    => 1
          }));
        }
      }
      foreach my $alt_translation (@alt_translations) {
        $composite2->push($composites{$alt_translation->stable_id});
      }
      $composite->push($composite2);
# /EG: render multiple translations
      
      my $bump_height = 1.5 * $h;
      
      if ($show_labels ne 'off' && $labels) {
        if (my $label = $self->feature_label($gene, $transcript)) {
          my @lines = split "\n", $label;
          
          for (my $i = 0; $i < @lines; $i++) {
            my $line = "$lines[$i] ";
            my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            
            $composite->push($self->Text({
              x         => $composite->x,
              y         => $y + $h + $i*($th+1),
              height    => $th,
              width     => $w / $pix_per_bp,
              font      => $fontname,
              ptsize    => $fontsize,
              halign    => 'left', 
              colour    => $colour,
              text      => $line,
              absolutey => 1
            }));
            
            $bump_height += $th + 1;
          }
        }
      }

      # bump
      my $bump_start = int($composite->x * $pix_per_bp);
      my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
      my $row = $self->bump_row($bump_start, $bump_end);
      
      # shift the composite container by however much we're bumped
      $composite->y($composite->y - $strand * $bump_height * $row);
      $composite->colour($highlights->{$transcript_stable_id}) if $config->get_option('opt_highlight_feature') != 0 && $highlights->{$transcript_stable_id} && !defined $target;
      $self->push($composite);
    }
  }
  foreach my $operon (@operons_to_draw) {
    my $operon_strand = $operon->strand;
    my $operon_stable_id = $operon->can('stable_id') ? $operon->stable_id : undef;
    next if $operon_strand != $strand && $strand_flag eq 'b'; # skip features on wrong strand
    next if $target_gene && $operon_stable_id ne $target_gene;
    my @sorted_transcripts = map $_->[1], sort { $b->[0] <=> $a->[0] } map [ $_->start * $operon_strand, $_ ],
      @{$operon->get_all_OperonTranscripts};

    foreach my $transcript (@sorted_transcripts) {
      my $colour_key = 'protein_coding';#$self->transcript_key($transcript, $gene);
      my $colour     = $self->my_colour($colour_key);
      my $transcript_stable_id = $transcript->stable_id;

      $transcript = $transcript->transfer($container) unless ($start_point > $end_point);
      if(($start_point>$end_point)) {
              $addition = $reg_end - $start_point + 1;
      } else {
              $addition = 0;
      }

      next if $transcript->start > $length || $transcript->end < 1;
      
      $used_colours{'operon transcript'} = $colour;
      my $composite = $self->Composite({
        y      => $y,
        height => $h,
       #title  => $self->title($transcript, $operon),
        href => $self->operon_href($operon,$transcript),
      });
      
      my @opgenes = sort {$a->start<=>$b->start} 
        map { $start_point < $end_point ? $_->transfer($container) : $_ }
        @{$transcript->get_all_Genes};
      if(0<@opgenes){
          $composite->push($self->_render_operon_genes(\@opgenes,0,{
            no_bump => 1,
            no_colour => 0,
            used_colours => \%used_colours
          }));
         #$composite->push($self->_render_operon_gene_labels(\@opgenes));
      }

      ###<<< draw the operon transcription empty box
      my ($fill_start, $fill_end);
      $fill_start = $transcript->start + $addition;
      $fill_start = 1 if $fill_start < 1 ;
      $fill_end = $transcript->end + $addition - 1;
      $fill_end = $length if $fill_end > $length;
      $composite->push($self->Rect({ # draw non-coding box
        x            => $fill_start ,
        y            => $y + $non_coding_start,
        width        => $fill_end - $fill_start + 1,
        height       => $non_coding_height,
        bordercolour => $colour,
        absolutey    => 1
      }));
      ###>>>
      $transcript_drawn = 1;        
      
      my $bump_height = 1.5 * $h;
 ##########################<operon labels>
      if ($show_labels ne 'off' && $labels) {
  ############################<gene labels>
        my $numrows=0;
        if($label_operon_genes && (0<scalar @opgenes)){
          $numrows=1;
          my $labels_in_row = {0=>{}};
          foreach my $gene (@opgenes){
           #$labels_in_row->{0}->{$gene->stable_id}=$gene;
           #next if($prev == $gene);
            my $gene_name = $gene->external_name;
            $gene->{op_label} = $gene_name;
            my $w = ($self->get_text_width(0, "$gene_name ", '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            $gene->{op_label_end}=$gene->start + $w/$pix_per_bp;
            $gene->{ww}=$w;
            $labels_in_row->{0}->{$gene->stable_id}=$gene;
          }
          for(my $r=0;$r<$numrows;$r++){
            my $overlaps_found=0;
            my @row_of_genes = sort {$a->start <=> $b->start} values %{$labels_in_row->{$r}};
            my $prev;
            foreach my $gene (@row_of_genes){
              if($prev && ($gene->start <= $prev->{op_label_end})){
                $overlaps_found+=1;
                $labels_in_row->{$r+1}->{$gene->stable_id}=$gene;
                delete $labels_in_row->{$r}->{$gene->stable_id};
                ##do not increment $prev
              }
              else{
                if($gene->stable_id eq $selected_gene){
                  $composite->push($self->Rect({
                    x         => $gene->start,
                    y         => $y + $h + $r*($th+1)+1,
                    height    => $th,
                    width     => $gene->length,
                    colour    => 'highlight2',
                    absolutey => 1
                  }));
                }
                $composite->push($self->Text({
                  x         => $gene->start,
                  y         => $y + $h + $r*($th+1),
                  height    => $th,
                  width     => $gene->{ww} / $pix_per_bp,
                  font      => $fontname,
                  ptsize    => $fontsize,
                  halign    => 'left', 
                  colour    => $colour,
                  text      => $gene->{op_label},
                  absolutey => 1
                }));
                $prev=$gene;
              }
            }
            if(0<$overlaps_found){$numrows+=1;}
            else{last;}
          }
        }
       $bump_height+= $numrows * ($th + 1);
  ############################</gene labels>
        if (my $text_label = $self->operon_text_label($operon, $transcript)) {
          my @lines = split "\n", $text_label; 
          $lines[0] = "< $lines[0]" if $strand < 1;
          $lines[0] = "$lines[0] >" if $strand >= 1;
          my $__Y=$numrows * ($th+1) + $y;
          
          for (my $i = 0; $i < @lines; $i++) {
            my $line = "$lines[$i] ";
            my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            $composite->push($self->Text({
              x         => $composite->x,                          #$addition
              y         => $__Y + $h + ($i)*($th+1),
              height    => $th,
              width     => $w / $pix_per_bp,
              font      => $fontname,
              ptsize    => $fontsize,
              halign    => 'left', 
              colour    => $colour,
              text      => $line,
              absolutey => 1
            }));
            
            $bump_height += $th + 1;
          }
        }
      }
      
      if(1 < scalar @opgenes){
        my $prev;
        foreach my $gene (@opgenes){
          $gene = $gene->transfer($container);
          if($prev && ($gene->start - 1) <= $prev->end){
            $composite->push($self->Rect({
              x => $gene->start,
              y => $non_coding_start + 1,
              height => $non_coding_height - 2,
              width => $pix_per_bp,
              colour => 'beige',
              absolutey =>1
            })); 
          }
          $prev = $gene;
        }
      }
 ##########################</operon labels>    

      # bump
      my $bump_start = int($composite->x * $pix_per_bp);
      my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
      my $row = $self->bump_row($bump_start, $bump_end);
      
      # shift the composite container by however much we're bumped
      $composite->y($composite->y - $strand * $bump_height * $row);
#     $composite->colour($highlight) if defined $highlight && !defined $target;
      $composite->colour('highlight1') if $selected_gene && grep(/^$selected_gene$/, map {$_->stable_id} @opgenes);
      $self->push($composite);
    }
  }
  

  if ($transcript_drawn) {
      my $type = $self->type;
      my %legend_old = @{$self->{'legend'}{'gene_legend'}{$type}{'legend'}||[]};
      $used_colours{$_} = $legend_old{$_} for keys %legend_old;
      my @legend = %used_colours;
      $self->{'legend'}{'gene_legend'}->{$type} = {
      priority => $self->_pos,
      legend   => \@legend
      };
  } elsif ($config->get_option('opt_empty_tracks') != 0) {
      $self->errorTrack(sprintf 'No %s in this region', $self->error_track_name);
  }

}

sub render_alignslice_transcript {
  my ($self, $labels) = @_;

  return $self->render_text('transcript') if $self->{'text_export'};

  my $config            = $self->{'config'};
  my $container         = $self->{'container'}{'ref'} || $self->{'container'};
  my $start_point = $container->start;
  my $end_point = $container->end;
  my $reg_end = $container->seq_region_length;
  my $addition = 0;


  my $length            = $container->length;
  my $selected_db       = $self->core('db');
  my $selected_gene     = $self->core('g');
  my $selected_trans    = $self->core('t');
  my $pix_per_bp        = $self->scalex;
  my $strand            = $self->strand;
  my $strand_flag       = $self->my_config('strand');
  my $db                = $self->my_config('db');
  my $show_labels       = $self->my_config('show_labels');
  my $target            = $self->get_parameter('single_Transcript');
  my $target_gene       = $self->get_parameter('single_Gene');
  my $y                 = 0;
  my $h                 = $self->my_config('height') || ($target ? 30 : 8); # Single transcript mode - set height to 30 - width to 8
  my $mcolour           = 'green'; # Colour to use to display missing exons
  my $transcript_drawn  = 0;
  my %used_colours;

  my ($fontname, $fontsize) = $self->get_font_details('outertext');
  my $th = ($self->get_text_width(0, 'Xg', 'Xg', 'ptsize' => $fontsize, 'font' => $fontname))[3];
  
  $self->_init_bump;
  
  my ($genes, $highlights, $transcripts) = $self->features;
  
  foreach my $gene (@$genes) {
    my $gene_strand    = $gene->strand;
    my $gene_stable_id = $gene->can('stable_id') ? $gene->stable_id : undef;
    
    next if $gene_strand != $strand && $strand_flag eq 'b'; # skip features on wrong strand
    next if $target_gene && $gene_stable_id ne $target_gene;
    
    my @sorted_transcripts = map $_->[1], sort { $b->[0] <=> $a->[0] } map [ $_->start * $gene_strand, $_ ], @{$transcripts->{$gene_stable_id}};
    
    foreach my $transcript (@sorted_transcripts) {
      next if $transcript->start > $length || $transcript->end < 1;
      
      my @exons = $self->map_AlignSlice_Exons($transcript, $length);
      
      next if scalar @exons == 0;
      
      # For exon_structure diagram only given transcript
      next if $target && $transcript->stable_id ne $target;
      
      $transcript_drawn = 1;
      
      my $composite = $self->Composite({ 
        y      => $y, 
        height => $h,
        title  => $self->title($transcript, $gene),
        href   => $self->href($gene, $transcript)
      });
      
      my $transcript_stable_id = $transcript->stable_id;
      
      my $colour_key = $self->colour_key($gene, $transcript);    
      my $colour     = $self->my_colour($colour_key);
# EG  my $label      = $self->my_colour($colour_key, 'text');
      my $label = $self->colour_label($gene, $transcript);
#
      
      ($colour, $label) = ('orange', 'Other') unless $colour;
      $used_colours{$label} = $colour; 
      
      my $coding_start = defined $transcript->coding_region_start ? $transcript->coding_region_start :  -1e6;
      my $coding_end   = defined $transcript->coding_region_end   ? $transcript->coding_region_end   :  -1e6;

      my $composite2 = $self->Composite({ y => $y, height => $h });
      
      # now draw exons
      for (my $i = 0; $i < scalar @exons; $i++) {
        my $exon = @exons[$i];
        
        next unless defined $exon; # Skip this exon if it is not defined (can happen w/ genscans) 
        last if $exon->start > $length; # We are finished if this exon starts outside the slice
        
        my ($box_start, $box_end);
        
        # only draw this exon if is inside the slice
        if ($exon->end > 0) { # calculate exon region within boundaries of slice
          $box_start = $exon->start;
          $box_start = 1 if $box_start < 1 ;
          $box_end = $exon->end;
          $box_end = $length if $box_end > $length;
          
          # The start of the transcript is before the start of the coding
          # region OR the end of the transcript is after the end of the
          # coding regions.  Non coding portions of exons, are drawn as
          # non-filled rectangles
          # Draw a non-filled rectangle around the entire exon

          if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)) {
              $addition = $reg_end - $start_point + 1;
            #if ($exon->slice->is_circular) {
            #   $addition = 0;
            #}
          } else {
              $addition = 0;
          }

          if ($box_start < $coding_start || $box_end > $coding_end) {
            $composite2->push($self->Rect({
              x            => $box_start + $addition - 1,
              y            => $y + $h/8,
              width        => $box_end - $box_start + 1,
              height       => 3 * $h/4,
              bordercolour => $colour,
              absolutey    => 1
            }));
          }
          
          # Calculate and draw the coding region of the exon
          my $filled_start = $box_start < $coding_start ? $coding_start : $box_start;
          my $filled_end   = $box_end > $coding_end     ? $coding_end   : $box_end;
          # only draw the coding region if there is such a region
          
          # Draw a filled rectangle in the coding region of the exon
          if ($filled_start <= $filled_end) {
            $composite2->push($self->Rect({
              x         => $filled_start + $addition - 1,
              y         => $y,
              width     => $filled_end - $filled_start + 1,
              height    => $h,
              colour    => $colour,
              absolutey => 1
            }));
          }
        } 
        
        my $next_exon = $i < $#exons ? @exons[$i+1] : undef;
        
        last unless defined $next_exon; # we are finished if there is no other exon defined

        my $intron_start = $exon->end + 1; # calculate the start and end of this intron
        my $intron_end = $next_exon->start - 1;
        
        next if $intron_end < 0;         # grab the next exon if this intron is before the slice
        last if $intron_start > $length; # we are done if this intron is after the slice
          
        # calculate intron region within slice boundaries
        $box_start = $intron_start < 1 ? 1 : $intron_start;
        $box_end   = $intron_end > $length ? $length : $intron_end;
        
        my $intron;
        if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)) {
            $addition = $reg_end - $start_point + 1;
          #if ($exon->slice->is_circular) {
          #   $addition = 0;
          #}

        } else {
            $addition = 0;
        }
        
        # Usual stuff if it is not missing exon
        if ($exon->{'exon'}->{'etype'} ne 'M') {
          if ($box_start == $intron_start && $box_end == $intron_end) {
            # draw an wholly in slice intron
            $composite2->push($self->Intron({
              x         => $box_start + $addition - 1,
              y         => $y,
              width     => $box_end - $box_start + 1,
              height    => $h,
              colour    => $colour,
              absolutey => 1,
              strand    => $strand
            }));
          } else {
            # else draw a "not in slice" intron
            $composite2->push($self->Line({
              x         => $box_start + $addition - 1,
              y         => $y + int($h/2),
              width     => $box_end-$box_start + 1,
              height    => 0,
              absolutey => 1,
              colour    => $colour,
              dotted    => 1
            }));
          }
        } else {
          # Missing exon - draw a dotted line
          $composite2->push($self->Line({
            x         => $box_start  + $addition - 1,
            y         => $y + int($h/2),
            width     => $box_end-$box_start + 1,
            height    => 0,
            absolutey => 1,
            colour    => $mcolour,
            dotted    => 1
          }));
        }
      }
      
      $composite->push($composite2);
      
      my $bump_height = 1.5 * $h;
      
      if ($show_labels ne 'off' && $labels) {
        if (my $label = $self->feature_label($gene, $transcript)) {
          my @lines = split "\n", $label;
          
          for (my $i = 0; $i < scalar @lines; $i++) {
            my $line = $lines[$i];
            my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            
            $composite->push($self->Text({
              x         => $composite->x,
              y         => $y + $h + $i * ($th + 1),
              height    => $th,
              width     => $w / $pix_per_bp,
              font      => $fontname,
              ptsize    => $fontsize,
              halign    => 'left',
              colour    => $colour,
              text      => $line,
              absolutey => 1
            }));
            
            $bump_height += $th + 1;
          }
        }
      }
      
      # bump
      my $bump_start = int($composite->x * $pix_per_bp);
      my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
      
      my $row = $self->bump_row($bump_start, $bump_end);
      
      # shift the composite container by however much we've bumped
      $composite->y($composite->y - $strand * $bump_height * $row);
      $composite->colour($highlights->{$transcript_stable_id}) if $config->get_option('opt_highlight_feature') != 0 && $highlights->{$transcript_stable_id} && !defined $target;
      $self->push($composite);
      
      if ($target) {
        # check the strand of one of the transcript's exons
        my ($trans_exon) = @{$transcript->get_all_Exons};
        
        if ($trans_exon->strand == 1) {
          $self->push($self->Line({
            x         => 0,
            y         => -4,
            width     => $length,
            height    => 0,
            absolutey => 1,
            colour    => $colour
          }));
          
          $self->push($self->Poly({
            absolutey => 1,
            colour    => $colour,
            points    => [
             $length - 4/$pix_per_bp, -2,
             $length, -4,
             $length - 4/$pix_per_bp, -6
            ]
          }));
        } else {
          $self->push($self->Line({
            x         => 0,
            y         => $h + 4,
            width     => $length,
            height    => 0,
            absolutey => 1,
            colour    => $colour
          }));
            
          $self->push($self->Poly({
            absolutey => 1,
            colour    => $colour,
            points    => [ 
              4/$pix_per_bp, $h + 6,
              0, $h + 4,
              4/$pix_per_bp, $h + 2
            ]
          }));
        }
      }  
    }
  }

  if ($transcript_drawn) {
    my $type = $self->my_config('name');
    my %legend_old = @{$config->{'legend_features'}{$type}{'legend'}||[]};
    
    $used_colours{$_} = $legend_old{$_} for keys %legend_old;
    
    my @legend = %used_colours;
    
    $config->{'legend_features'}{$type} = {
      priority => $self->_pos,
      legend   => \@legend
    };
  } elsif ($config->get_option('opt_empty_tracks') != 0) {
    $self->errorTrack(sprintf 'No %s in this region', $self->error_track_name);
  }
}

sub render_alignslice_collapsed {
  my ($self, $labels) = @_;
  
  return $self->render_text('transcript') if $self->{'text_export'};

  my $config            = $self->{'config'};
  my $container         = $self->{'container'}{'ref'} || $self->{'container'};
  my $length            = $container->length;
  my $selected_db       = $self->core('db');
  my $selected_gene     = $self->core('g');
  my $pix_per_bp        = $self->scalex;
  my $strand            = $self->strand;
  my $strand_flag       = $self->my_config('strand');
  my $db                = $self->my_config('db');
  my $show_labels       = $self->my_config('show_labels');
  my $y                 = 0;
  my $h                 = 8;
  my $transcript_drawn  = 0;
  my %used_colours;

  my $start_point = $container->start;
  my $end_point = $container->end;
  my $reg_end = $container->seq_region_length;
  my $addition = 0;

  
  my ($fontname, $fontsize) = $self->get_font_details('outertext');
  my $th = ($self->get_text_width(0, 'Xg', 'Xg', 'ptsize' => $fontsize, 'font' => $fontname))[3];
  
  $self->_init_bump;
  
  my ($genes, $highlights) = $self->features;
  
  foreach my $gene (@$genes) {
    my $gene_strand    = $gene->strand;
    my $gene_stable_id = $gene->stable_id;
    
    next if $gene_strand != $strand && $strand_flag eq 'b';
    
    my $composite = $self->Composite({ 
      y      => $y, 
      height => $h,
      title  => $self->gene_title($gene),
      href   => $self->href($gene)
    });
    
    my $colour_key = $self->colour_key($gene);    
# EG    
    my $colour     = $self->my_colour($colour_key);
    my $label      = $self->colour_label($gene);
## 
    
    ($colour, $label) = ('orange', 'Other') unless $colour;
    
    $used_colours{$label} = $colour;
    
    my @exons;
    
    # In compact mode we 'collapse' exons showing just the gene structure, i.e overlapping exons/transcripts will be merged
    foreach my $transcript (@{$gene->get_all_Transcripts}) {
      next if $transcript->start > $length || $transcript->end < 1;
      push @exons, $self->map_AlignSlice_Exons($transcript, $length);
    }
    
    next unless @exons;
    
    my $composite2 = $self->Composite({ y => $y, height => $h });
    
    # All exons in the gene will be connected by a simple line which starts from a first exon if it within the viewed region, otherwise from the first pixel. 
    # The line ends with last exon of the gene or the end of the image
    my $start = $exons[0]->{'exon'}->{'etype'} eq 'B' ? 1 : 0;       # Start line from 1 if there are preceeding exons    
    my $end  = $exons[-1]->{'exon'}->{'etype'} eq 'A' ? $length : 0; # End line at the end of the image if there are further exons beyond the region end
    
    # Get only exons in view
    my @exons_in_view = sort { $a->start <=> $b->start } grep { $_->{'exon'}->{'etype'} =~ /[NM]/} @exons;
    
    # Set start and end of the connecting line if they are not set yet
    $start ||= $exons_in_view[0]->start;
    $end   ||= $exons_in_view[-1]->end;
    
    # Draw exons
    foreach my $exon (@exons_in_view) {
      my $s = $exon->start;
      my $e = $exon->end;
      
      $s = 1 if $s < 0;
      $e = $length if $e > $length;
      
      $transcript_drawn = 1;

      if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)) {
        $addition = $reg_end - $start_point + 1;
      } else {
    $addition = 0;
      }

      
      $composite2->push($self->Rect({
        x         => $s + $addition - 1, 
        y         => $y, 
        height    => $h,
        width     => $e - $s + 1,
        colour    => $colour, 
        absolutey => 1
      }));
    }
    
    # Draw connecting line
    $composite2->push($self->Rect({
      x         => $start + $addition, 
      y         => int($y + $h/2), 
      height    => 0, 
      width     => $end - $start + 1,
      colour    => $colour, 
      absolutey => 1
    }));
    
    $composite->push($composite2);
    
    my $bump_height = $h + 2;
    
    if ($show_labels ne 'off' && $labels) {
      if (my $label = $self->feature_label($gene)) {
        my @lines = split "\n", $label;
        
        for (my $i = 0; $i < scalar @lines; $i++){
          my $line = "$lines[$i] ";
          my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
          
          $composite->push($self->Text({
            x         => $composite->x,
            y         => $y + $h + $i*($th + 1),
            height    => $th,
            width     => $w / $pix_per_bp,
            font      => $fontname,
            ptsize    => $fontsize,
            halign    => 'left',
            colour    => $colour,
            text      => $line,
            absolutey => 1
          }));
          
          $bump_height += $th + 1;
        }
      }
    }
    
    # bump
    my $bump_start = int($composite->x * $pix_per_bp);
    my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
    
    my $row = $self->bump_row($bump_start, $bump_end);
    
    # shift the composite container by however much we're bumped
    $composite->y($composite->y - $strand * $bump_height * $row);
    $composite->colour($highlights->{$gene_stable_id}) if $config->get_option('opt_highlight_feature') !=0 && $highlights->{$gene_stable_id};
    $self->push($composite);
  }
  
  if ($transcript_drawn) {
    my $type = $self->my_config('name');
    my %legend_old = @{$config->{'legend_features'}{$type}{'legend'}||[]};
    $used_colours{$_} = $legend_old{$_} for keys %legend_old;
    my @legend = %used_colours;
    $config->{'legend_features'}{$type} = {
      priority => $self->_pos,
      legend   => \@legend
    };
  } elsif ($config->get_option('opt_empty_tracks') != 0) {
    $self->errorTrack(sprintf 'No %s in this region', $self->error_track_name);
  }
}

sub render_genes {
  my $self = shift;

  return $self->render_text('gene') if $self->{'text_export'};

  my $config           = $self->{'config'};
  my $container        = $self->{'container'}{'ref'} || $self->{'container'};

  my $start_point = $container->start;
  my $end_point = $container->end;
  my $reg_end = $container->seq_region_length;
  my $is_ciruclar = $container->is_circular;
  my $addition = 0;

  my $length           = $container->length;
  my $pix_per_bp       = $self->scalex;
  my $strand           = $self->strand;
  my $selected_gene    = $self->my_config('g') || $self->core('g');
  my $strand_flag      = $self->my_config('strand');
  my $database         = $self->my_config('db');
  my $max_length       = $self->my_config('threshold') || 1e6;
  my $max_length_nav   = $self->my_config('navigation_threshold') || 50e3;
  my $label_threshold  = $self->my_config('label_threshold') || 50e3;
  my $navigation       = $self->my_config('navigation') || 'on';
  my $previous_species = $self->my_config('previous_species');
  my $next_species     = $self->my_config('next_species');
  my $previous_target  = $self->my_config('previous_target');
  my $next_target      = $self->my_config('next_target');
  my $join_types       = $self->get_parameter('join_types');
  my $link             = $self->get_parameter('compara') ? $self->my_config('join') : 0;
  my $alt_alleles_col  = $self->my_colour('alt_alleles_join');
  my $h                = 8;
  my $join_z           = 1000;
  
  my %font_details = $self->get_font_details('outertext', 1);
  my $h = ($self->get_text_width(0, 'X_y', '', %font_details))[3];
  
  $self->_init_bump;
  
  if ($length > $max_length * 1001) {
    $self->errorTrack("Genes only displayed for less than $max_length Kb.");
    return;
  }
  
  my $show_navigation = $navigation eq 'on';
  my $flag = 0;
  my @genes_to_label;
  my %operons;
  my ($genes_to_filter, $highlights) = $self->features;
  my $genes = [];
## If start > end, transfer post-origin operons to the post-origin slice, start_slice
  my $start_slice; 
  if($start_point > $end_point){
    $start_slice = $container->adaptor->fetch_by_region($container->coord_system_name,$container->seq_region_name,1,$end_point);
  }
 
 
  foreach my $gene (@$genes_to_filter) {
    my @ops;
## get_all_Operons is liable to get all features on the antislice, so don't try it a slice with start > end
    my $slice = $gene->feature_Slice;
    if($slice->start > $slice->end){ 
      $slice = $slice->invert;
    }
    @ops = @{$slice->get_all_Operons} if $slice->can('get_all_Operons');
    if(0<scalar @ops){
      foreach my $opn (@ops){
        if(ref($opn) ne 'Bio::EnsEMBL::Operon'){next;}
        if(!exists $operons{$opn->dbID}){
## If start > end, transfer post-origin operons to the post-origin slice, start_slice
          $opn = $opn->transfer($start_point > $end_point ? $start_slice : $container);
          $opn->{external_name} = $opn->display_label;      
          $operons{$opn->dbID}=1;
          $opn->{'is_operon'}=1;
          $opn->{genes} = [$gene->stable_id];
          bless($opn,'Bio::EnsEMBL::Gene');
          push(@$genes,$opn);
        }
        else{
          push(@{$opn->{genes}},$gene);
        }
      }
    }
    else{
      push(@$genes,$gene);
    }
    $gene->{'is_operon'}=0;
  }

## EG  
  # copy and translate genes that cross the origin so that they are drawn on both sides
  if ($is_ciruclar) {
    foreach my $gene (grep {$_->start < 0} @$genes) {
      my $copy = clone($gene);
      $copy->start($reg_end + $gene->start);
      $copy->end($copy->start + $gene->length);
      push @$genes, $copy;
    }
  }
##
   
  foreach my $gene (@$genes) {
    my $gene_strand = $gene->strand;
    
    next if $gene_strand != $strand && $strand_flag eq 'b';
    
    my $colour_key     = $self->colour_key($gene);
    my $gene_col       = $self->my_colour($colour_key);
    my $gene_type      = $self->my_colour($colour_key, 'text');
    my $label          = $self->feature_label($gene);
    my $gene_stable_id = $gene->stable_id;
    my $start          = $gene->start;
    my $end            = $gene->end;
   
    my ($chr_start, $chr_end) = $self->slice2sr($start, $end);
    
    next if $end < 1 || $start > $length;
    
    $start = 1 if $start < 1;
    $end   = $length if $end > $length;


    if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)){
      $addition = $reg_end - $start_point + 1;
    } else {
      $addition = 0;
    }
   
    my $rect = $self->Rect({
      x         => $start - 1 + $addition,
      y         => 0,
      width     => $end - $start + 1,
      height    => $h,
      colour    => $gene_col,
      absolutey => 1,
      href      => $show_navigation ? $self->href($gene) : undef,
      title     => ($gene->external_name ? $gene->external_name . '; ' : '') .
                   "Gene: $gene_stable_id; Location: " .
                   $gene->seq_region_name . ':' . $gene->seq_region_start . '-' . $gene->seq_region_end
    });
    
    if ($show_navigation) {
      if($gene->{'is_operon'}){
        my ($_opgene_stable_id) = grep($selected_gene,@{$gene->{'genes'}});
        $_opgene_stable_id ||= @{$gene->{'genes'}}[0];
        $rect->{'href'} = $self->_url({
          species => $self->species,
          type    => 'Gene',
          action  => 'OperonView',
          g       => $_opgene_stable_id,
          db      => $database
        });
      }
      else{
        $rect->{'href'} = $self->_url({
          species => $self->species,
          type    => 'Gene',
          action  => 'Summary',
          g       => $gene_stable_id,
          db      => $database
        });
      }
    }
    
    push @genes_to_label, {
      start     => $start + $addition,
      label     => $label,
      end       => $end + $addition,
      href      => $rect->{'href'},
      title     => $rect->{'title'},
      gene      => $gene,
      col       => $gene_col,
      highlight => $config->get_option('opt_highlight_feature') != 0 ? $highlights->{$gene_stable_id} : undef,
      type      => $gene_type
    };
    
    my $bump_start = int($rect->x * $pix_per_bp);
    my $bump_end = $bump_start + int($rect->width * $pix_per_bp) + 1;
    my $row = $self->bump_row($bump_start, $bump_end);
    
    $rect->y($rect->y + (6 * $row));
    $rect->height(4);

    if ($link) {
      my $alt_alleles     = $gene->get_all_alt_alleles;
      my $seq_region_name = $gene->slice->seq_region_name;
      my ($target, @gene_tags);
      
      if ($previous_species) {
        for ($self->get_gene_joins($gene, $previous_species, $join_types)) {
          $target = $previous_target ? ":$seq_region_name:$previous_target" : '';
          
          $self->join_tag($rect, "$gene_stable_id:$_->[0]$target", 0.5, 0.5, $_->[1], 'line', $join_z);
          
          $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
          $config->{'legend_features'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
        }
        
        push @gene_tags, map { join '=', $_->stable_id, $gene_stable_id } @{$self->filter_by_target($alt_alleles, $previous_target)};
      }
      
      if ($next_species) {
        for ($self->get_gene_joins($gene, $next_species, $join_types)) {
          $target = $next_target ? ":$next_target:$seq_region_name" : '';
          
          $self->join_tag($rect, "$_->[0]:$gene_stable_id$target", 0.5, 0.5, $_->[1], 'line', $join_z);
          
          $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
          $config->{'legend_features'}{'joins'}{'legend'}{$_->[2]} = $_->[1];
        }
        
        push @gene_tags, map { join '=', $gene_stable_id, $_->stable_id } @{$self->filter_by_target($alt_alleles, $next_target)};
      }
      
      $self->join_tag($rect, $_, 0.5, 0.5, $alt_alleles_col, 'line', $join_z) for @gene_tags; # join alt_alleles
      
      if (@gene_tags) {
        $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
        $config->{'legend_features'}{'joins'}{'legend'}{'Alternative alleles'} = $alt_alleles_col;
      }
    }
    
    $self->push($rect);
    
    if ($config->get_option('opt_highlight_feature') != 0 && $highlights->{$gene_stable_id}) {
      $self->unshift($self->Rect({
        x         => ($start  + $addition - 1) - 1/$pix_per_bp,
        y         => $rect->y - 1,
        width     => ($end - $start + 1) + 2/$pix_per_bp,
        height    => $rect->height + 2,
        colour    => $highlights->{$gene_stable_id},
        absolutey => 1
      }));
    }
    
    $flag = 1;
  }
  
  # Now we need to add the label track, followed by the legend
  if ($flag) {
    my $gl_flag = $self->get_parameter('opt_gene_labels');
    $gl_flag = 1 unless defined $gl_flag;
    $gl_flag = shift if @_;
    $gl_flag = 0 if $label_threshold * 1001 < $length;
    
    if ($gl_flag) {
      my $start_row = $self->_max_bump_row + 1;
      my $image_end = $self->get_parameter('image_end');
      
      $self->_init_bump;

      foreach my $gr (@genes_to_label) {
        my $x         = $gr->{'start'} - 1;
        my $tag_width = (4 / $pix_per_bp) - 1;
        my $w         = ($self->get_text_width(0, $gr->{'label'}, '', %font_details))[2] / $pix_per_bp;
        my $label_x   = $x + $tag_width;
        my $right_align;
        
        if ($label_x + $w > $image_end) {
          $label_x     = $x - $w - $tag_width;
          $right_align = 1;
        }
        
        my $label = $self->Text({
          x         => $label_x,
          y         => 0,
          height    => $h,
          width     => $w,
          halign    => 'left',
          colour    => $gr->{'col'},
          text      => $gr->{'label'},
          title     => $gr->{'title'},
          href      => $gr->{'href'},
          absolutey => 1,
          %font_details
        });
        
        my $bump_start = int($label_x * $pix_per_bp) - 4;
        my $bump_end   = $bump_start + int($label->width * $pix_per_bp) + 1;
        my $row        = $self->bump_row($bump_start, $bump_end);
        
        $label->y($row * (2 + $h) + ($start_row - 1) * 6);
        
        # Draw little taggy bit to indicate start of gene
        $self->push(
          $label,
          $self->Rect({
            x         => $x,
            y         => $label->y + 2,
            width     => 0,
            height    => 4,
            colour    => $gr->{'col'},
            absolutey => 1
          }),
          $self->Rect({
            x         => $right_align ? $x - (3 / $pix_per_bp) : $x,
            y         => $label->y + 6,
            width     => 3 / $pix_per_bp,
            height    => 0,
            colour    => $gr->{'col'},
            absolutey => 1
          })
        );
        
        if ($config->get_option('opt_highlight_feature') != 0 && $gr->{'highlight'}) {
          $self->unshift($self->Rect({
            x         => $gr->{'start'} - 1 - (1 / $pix_per_bp),
            y         => $label->y + 1,
            width     => $label->width + 1 + (2 / $pix_per_bp),
            height    => $label->height + 2,
            colour    => $gr->{'highlight'},
            absolutey => 1
          }));
        }
      }
    }
    
    my %used_colours = map { $_->{'type'} => $_->{'col'} } @genes_to_label;
    my @legend = %used_colours;
    
    $self->{'legend'}{'gene_legend'}{$self->type} = {
      priority => $self->_pos,
      legend   => \@legend
    }
  } elsif ($config->get_option('opt_empty_tracks') != 0) {
    $self->errorTrack(sprintf 'No %s in this region', $self->error_track_name);
  }
}

sub render_text {
  my $self = shift;
  my ($feature_type, $collapsed) = @_;
  
  my $container   = $self->{'container'}{'ref'} || $self->{'container'};
  my $length      = $container->length;
  my $strand      = $self->strand;
  my $strand_flag = $self->my_config('strand') || 'b';
  my $target      = $self->get_parameter('single_Transcript');
  my $target_gene = $self->get_parameter('single_Gene');
  my ($genes)     = $self->features;
  my $export;
  
  foreach my $gene (@$genes) {
    my $gene_id = $gene->can('stable_id') ? $gene->stable_id : undef;
    
    next if $target_gene && $gene_id ne $target_gene;
    
    my $gene_type   = $gene->status . '_' . $gene->biotype;
    my $gene_name   = $gene->can('display_xref') && $gene->display_xref ? $gene->display_xref->display_id : undef;
    my $gene_source = $gene->source;
    
    if ($feature_type eq 'gene') {
      $export .= $self->_render_text($gene, 'Gene', { 
        headers => [ 'gene_id', 'gene_name', 'gene_type' ],
        values  => [ $gene_id, $gene_name, $gene_type ]
      });
    } else {
      my $exons = {};
      
      foreach my $transcript (@{$gene->get_all_Transcripts}) {
        next if $transcript->start > $length || $transcript->end < 1;
        
        my $transcript_id = $transcript->stable_id;
        
        next if $target && ($transcript_id ne $target); # For exon_structure diagram only given transcript
        
        my $transcript_name = 
          $transcript->can('display_xref') && $transcript->display_xref ? $transcript->display_xref->display_id : 
          $transcript->can('analysis') && $transcript->analysis ? $transcript->analysis->logic_name : 
          undef;
        
        foreach (sort { $a->start <=> $b->start } @{$transcript->get_all_Exons}) {
          next if $_->start > $length || $_->end < 1;
          
          if ($collapsed) {
            my $stable_id = $_->stable_id;
            
            next if $exons->{$stable_id};
            
            $exons->{$stable_id} = 1;
          }
           
          $export .= $self->export_feature($_, $transcript_id, $transcript_name, $gene_id, $gene_name, $gene_type, $gene_source);
        }
      }
    }
  }
  
  return $export;
}

#============================================================================#
#
# The following three subroutines are designed to get homologous peptide ids
# 
#============================================================================#

# Get homologous gene ids for given gene
sub get_gene_joins {
  my ($self, $gene, $species, $join_types, $source) = @_;
  
  my $config     = $self->{'config'};
  my $compara_db = $config->hub->database('compara');
  return unless $compara_db;
  
  my $ma = $compara_db->get_GeneMemberAdaptor;
  return unless $ma;
  
  my $qy_member = $ma->fetch_by_source_stable_id($source, $gene->stable_id);
  return unless defined $qy_member;
  
  my $method = $config->get_parameter('force_homologue') || $species eq $config->{'species'} ? $config->get_parameter('homologue') : undef;
  my $func   = $source ? 'get_homologous_peptide_ids_from_gene' : 'get_homologous_gene_ids';
  
  return $self->$func($species, $join_types, $compara_db->get_HomologyAdaptor, $qy_member, $method ? [ $method ] : undef);
}

sub get_homologous_gene_ids {
    my ($self, $species, $join_types, $homology_adaptor, $qy_member, $method) = @_;
    my @homologues;

    foreach my $homology (@{$homology_adaptor->fetch_all_by_Member_paired_species($qy_member, $species, $method)}) {
  my $colour_key = $join_types->{$homology->description};

  next if $colour_key eq 'hidden';

  my $colour = $self->my_colour($colour_key . '_join');
  my $label  = $self->my_colour($colour_key . '_join', 'text');

  foreach my $member (@{$homology->get_all_GeneMembers}) {
      next if $member->stable_id eq $qy_member->stable_id;

      push @homologues, [ $member->stable_id, $colour, $label ];
  }
    }

    return @homologues;
}

# Get homologous protein ids for given gene
sub get_homologous_peptide_ids_from_gene {
    my ($self, $species, $join_types, $homology_adaptor, $qy_member, $method) = @_;
    my ($stable_id, @homologues, @homologue_genes);

    foreach my $homology (@{$homology_adaptor->fetch_all_by_Member_paired_species($qy_member, $species, $method)}) {
  my $colour_key = $join_types->{$homology->description};

  next if $colour_key eq 'hidden';

  my $colour = $self->my_colour($colour_key . '_join');
  my $label  = $self->my_colour($colour_key . '_join', 'text');

  foreach my $member (@{$homology->get_all_Members}) {
      my $gene_member = $member->gene_member;

      if ($gene_member->stable_id eq $qy_member->stable_id) {
    $stable_id = $member->stable_id;
      } else {
    push @homologues,      [ $member->stable_id,      $colour, $label ];
    push @homologue_genes, [ $gene_member->stable_id, $colour         ];
      }
  }
    }

    return ($stable_id, \@homologues, \@homologue_genes);
}

sub get_homologous_gene_ids_old {
  my ($self, $gene, $species, $join_types) = @_;
  
  my $compara_db = $self->{'config'}->hub->database('compara');
  return unless $compara_db;
  
  my $ma = $compara_db->get_MemberAdaptor;
  return unless $ma;
  
  my $qy_member = $ma->fetch_by_source_stable_id(undef, $gene->stable_id);
  return unless defined $qy_member;
  
  my $config = $self->{'config'};
  my $ha     = $compara_db->get_HomologyAdaptor;
  my $method = $species eq $config->{'species'} ? $config->get_parameter('homologue') : undef;
  my @homologues;
  
  # $config->get_parameter('homologue') may be undef, so can't just do [ $config->get_parameter('homologue') ] because [ undef ] as an argument breaks fetch_all_by_Member_paired_species
  foreach my $homology (@{$ha->fetch_all_by_Member_paired_species($qy_member, $species, $method ? [ $method ] : undef)}) {
    my $colour_key = $join_types->{$homology->description};
    
    next if $colour_key eq 'hidden';
    
    my $colour = $self->my_colour($colour_key . '_join');
    my $label  = $self->my_colour($colour_key . '_join', 'text');
    
    foreach my $member_attribute (@{$homology->get_all_Member_Attribute}) {
      my ($member, $attribute) = @$member_attribute;
      
      next if $member->stable_id eq $qy_member->stable_id;
      
      push @homologues, [ $member->stable_id, $colour, $label ];
    }
  }
  
  return @homologues;
}

# Get homologous protein ids for given gene
sub get_homologous_peptide_ids_from_gene_old {
  my ($self, $gene, $species, $join_types) = @_;
  
  my $compara_db = $gene->adaptor->db->get_adaptor('compara');
  return unless $compara_db;
  
  my $ma = $compara_db->get_MemberAdaptor;
  return unless $ma;
  
  my $qy_member = $ma->fetch_by_source_stable_id('ENSEMBLGENE', $gene->stable_id);
  return unless defined $qy_member;
  
  my $config  = $self->{'config'}; 
  my $ha      = $compara_db->get_HomologyAdaptor;
  my $method = $species eq $config->{'species'} ? $config->get_parameter('homologue') : undef;
  my @homologues;
  my @homologue_genes;
  
  my $stable_id = undef;
  my $peptide_id = undef;
  
  foreach my $homology (@{$ha->fetch_all_by_Member_paired_species($qy_member, $species, $method ? [ $method ] : undef)}) {
    my $colour_key = $join_types->{$homology->description};
    
    next if $colour_key eq 'hidden';
    
    my $colour = $self->my_colour($colour_key . '_join');
    my $label  = $self->my_colour($colour_key . '_join', 'text');
    
    foreach my $member_attribute (@{$homology->get_all_Member_Attribute}) {
      my ($member, $attribute) = @$member_attribute;
      
      if ($member->stable_id eq $qy_member->stable_id) {
        unless ($stable_id) {
          my $T = $ma->fetch_by_dbID($peptide_id = $attribute->peptide_member_id);
          $stable_id = $T->stable_id;
        }
      } else {
        push @homologues, [ $attribute->peptide_member_id, $colour, $label ];
        push @homologue_genes, [ $member->stable_id, $colour ];
      }
    }
  }
  
  return ($stable_id, $peptide_id, \@homologues, \@homologue_genes);
}



sub feature_label {
  my $self       = shift;
  my $gene       = shift;
  my $transcript = shift || $gene;
  my $id         = $transcript->external_name || $transcript->stable_id;
     $id         = $transcript->strand == 1 ? "$id >" : "< $id";
  
  return $id if $self->get_parameter('opt_shortlabels') || $transcript == $gene;
  
  my $label = $self->my_config('label_key') || '[text_label] [display_label]';
  
  return $id if $label eq '-';
  
  my $ini_entry = $self->my_colour($self->colour_key($gene, $transcript), 'text');
  
  if ($label =~ /[biotype]/) {
    my $biotype = $transcript->biotype;
       $biotype =~ s/_/ /g;
       $label   =~ s/\[biotype\]/$biotype/g;
## EG: avoid printing the same value twice
    $ini_entry = '' if ($ini_entry eq $biotype);
## EG: avoid printing the same value twice
  }
  
  $label =~ s/\[text_label\]/$ini_entry/g;
  $label =~ s/\[gene.(\w+)\]/$1 eq 'logic_name' || $1 eq 'display_label' ? $gene->analysis->$1 : $gene->$1/eg;
  $label =~ s/\[(\w+)\]/$1 eq 'logic_name' || $1 eq 'display_label' ? $transcript->analysis->$1 : $transcript->$1/eg;
  
  $id .= "\n$label" unless $label eq '-';
  
  return $id;
}

sub colour_key {
  my $self       = shift;
  my $gene       = shift;
  my $transcript = shift || $gene;
  my $pattern    = $self->my_config('colour_key') || '[biotype]';
  
  # hate having to put ths hack here, needed because any logic_name specific web_data entries
  # get lost when the track is merged - needs rewrite of imageconfig merging code
  return 'merged' if $transcript->analysis->logic_name =~ /ensembl_havana/;
  
  # EG: the colour can be altered via an attribute assigned to the gene
  # e.g a PHIbase_mutant attribute is assigned to a gene with value 'virulence'
  # then the web_data should have label set to [attrib.PHIbase_mutant][biotype] 
  # and all the possible attribute values(colours) should be added to conf/ini-files/COLOURS.ini
    if ($pattern =~ /\[attrib\.(\w+)\]/) {
      if (my ($attr) = @{ $gene->get_all_Attributes($1) }) {
        return $attr->value;
      }    
      $pattern =~ s/\[attrib\.(\w+)\]//;
    }  

    $pattern =~ s/\[gene.(\w+)\]/$1 eq 'logic_name' ? $gene->analysis->$1 : $gene->$1/eg;
    $pattern =~ s/\[(\w+)\]/$1 eq 'logic_name' ? $transcript->analysis->$1 : $transcript->$1/eg;

    return lc $pattern;
}

## EG: basically it is feature_label, but without preceeding feature id
sub colour_label {
    my $self       = shift;
    my $gene       = shift;
    my $transcript = shift || $gene;

    my $label = $self->my_config('label_key') || '[text_label] [display_label]';
    return '' if $label eq '-';

    my $ini_entry = $self->my_colour($self->colour_key($gene, $transcript), 'text');

    if ($label =~ /[biotype]/) {
      my $biotype  = $transcript->biotype;
      $biotype =~ s/_/ /g;
      $label =~ s/\[biotype\]/$biotype/g;
      if ($ini_entry eq $biotype) {
          $ini_entry = '';
      }
    }
    $label =~ s/\[text_label\]/$ini_entry/g;
    $label =~ s/\[gene.(\w+)\]/$1 eq 'logic_name' || $1 eq 'display_label' ? $gene->analysis->$1 : $gene->$1/eg;
    $label =~ s/\[(\w+)\]/$1 eq 'logic_name' || $1 eq 'display_label' ? $transcript->analysis->$1 : $transcript->$1/eg;
    return $label;
}

sub operon_text_label {
  my ($self, $gene, $transcript,$long) = @_;
  my $id  = $transcript->display_label || $transcript->stable_id;
  return $id if $self->get_parameter( 'opt_shortlabels');
  $id .= sprintf "\n%s",$transcript->operon->display_label;
  my %types = map { $_->biotype => 1 } @{$transcript->get_all_Genes};
  my $biotype = join(", ", keys %types);
  if($long){
    my $label = sprintf("%s %s",$biotype,$transcript->analysis->display_label);
    $id .= "\n$label" unless $label eq '-';
  }
  return $id;
}

sub operon_href {
  my ($self, $operon, $transcript) = @_;
  my ($gene) = @{$transcript->get_all_Genes};
 #my $action = $self->my_config('zmenu') ?  $self->my_config('zmenu') :  $ENV{'ENSEMBL_ACTION'};
  my $params = {
    species => $self->species,
    type    => 'Gene',
    action  => 'OperonView',#$action,
    t       => $transcript->stable_id||$transcript->display_label,
    g       => $gene->stable_id, 
    db      => $self->my_config('db')
  };
  
  $params->{'r'} = undef if $self->{'container'}->{'web_species'} ne $self->species;
  
  return $self->_url($params);
}

sub _render_operon_genes{
    my ($self,$genes,$labels,$meta)=@_;
    my $no_bump = $meta->{'no_bump'} || 0;
    my $config            = $self->{'config'};
    my $container         = $self->{'container'}{'ref'} || $self->{'container'};
    my $length            = $container->length;

    my $start_point = $container->start;
    my $end_point = $container->end;
    my $reg_end = $container->seq_region_length;
    my $addition = 0;

    my $pix_per_bp        = $self->scalex;
    my $strand            = $self->strand;
    my $selected_db       = $self->core('db');
    my $selected_trans    = $self->core('t');
    my $selected_gene     = $self->my_config('g') || $self->core('g');
    my $strand_flag       = $self->my_config('strand');
    my $db                = $self->my_config('db');
    my $show_labels       = $self->my_config('show_labels');
    my $previous_species  = $self->my_config('previous_species');
    my $next_species      = $self->my_config('next_species');
    my $previous_target   = $self->my_config('previous_target');
    my $next_target       = $self->my_config('next_target');
    my $join_types        = $self->get_parameter('join_types');
    my $link              = $self->get_parameter('compara') ? $self->my_config('join') : 0;
    my $target            = $self->get_parameter('single_Transcript');
    my $target_gene       = $self->get_parameter('single_Gene');
    my $alt_alleles_col   = $self->my_colour('alt_alleles_join');
    my $y                 = 0;
    my $h                 = $meta->{'height'} || $self->my_config('height') || ($target ? 30 : 8); # Single transcript mode - set height to 30 - width to 8
    my $join_z            = 1000;
    my $transcript_drawn  = 0;
    my $non_coding_height = ($self->my_config('non_coding_scale')||0.75) * $h;
    my $non_coding_start  = ($h - $non_coding_height) / 2;
    my $label_operon_genes = $self->my_config('label_operon_genes');
    my $no_operons = $self->my_config('no_operons') || $target;
    my $oglabel = $meta->{'oglabel'} || 0;
    my $used_colours = $meta->{'used_colours'};
    my ($fontname, $fontsize) = $self->get_font_details('outertext');
    my $th = ($self->get_text_width(0, 'Xg', 'Xg', 'ptsize' => $fontsize, 'font' => $fontname))[3];
    
    my $all_composite = $self->Composite();
    if(!$no_bump){$all_composite=$self;}
    foreach my $gene(@$genes){

    my $gene_strand = $gene->strand;
    my $gene_stable_id = $gene->can('stable_id') ? $gene->stable_id : undef;
    
    next if $gene_strand != $strand && $strand_flag eq 'b'; # skip features on wrong strand
    next if $target_gene && $gene_stable_id ne $target_gene;
    
    my (%tags, @gene_tags, $tsid);
    
    if ($link && $gene_stable_id) {
      my $alt_alleles = $gene->get_all_alt_alleles;
      my $alltrans    = $gene->get_all_Transcripts; # vega stuff to link alt-alleles on longest transcript
      my @s_alltrans  = sort { $a->length <=> $b->length } @$alltrans;
      my $long_trans  = pop @s_alltrans;
      my @transcripts;
      
      $tsid = $long_trans->stable_id;
      
      foreach my $gene (@$alt_alleles) {
        my $vtranscripts = $gene->get_all_Transcripts;
        my @sorted_trans = sort { $a->length <=> $b->length } @$vtranscripts;
        push @transcripts, (pop @sorted_trans);
      }
      
      if ($previous_species) {
        my ($sid, $pid, $homologues, $homologue_genes) = $self->get_homologous_peptide_ids_from_gene($gene, $previous_species, $join_types);
        
        push @{$tags{$sid}}, map {[ "$_->[0]:$pid", $_->[1] ]} @$homologues if $sid && $pid;
        push @{$tags{$sid}}, map {[ "$gene_stable_id:$_->[0]", $_->[1] ]} @$homologue_genes if $sid;
        push @gene_tags, map { join '=', $_->stable_id, $tsid } @{$self->filter_by_target(\@transcripts, $previous_target)};
        
        for (@$homologues) {
          (my $legend = $_->[2]) =~ s/_multi/ 1-to-many or many-to-many/;
          $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
          $config->{'legend_features'}{'joins'}{'legend'}{ucfirst $legend} = $_->[1];
        }
      }
      
      if ($next_species) {
        my ($sid, $pid, $homologues, $homologue_genes) = $self->get_homologous_peptide_ids_from_gene($gene, $next_species, $join_types);
        
        push @{$tags{$sid}}, map {[ "$pid:$_->[0]", $_->[1] ]} @$homologues if $sid && $pid;
        push @{$tags{$sid}}, map {[ "$_->[0]:$gene_stable_id", $_->[1] ]} @$homologue_genes if $sid;
        push @gene_tags, map { join '=', $tsid, $_->stable_id } @{$self->filter_by_target(\@transcripts, $next_target)};
        
        for (@$homologues) {
          (my $legend = $_->[2]) =~ s/_multi/ 1-to-many or many-to-many/;
          $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
          $config->{'legend_features'}{'joins'}{'legend'}{ucfirst $legend} = $_->[1];
        }
      }
    }
    
# EG     
#   my $thash;
##
    my @sorted_transcripts = map $_->[1], sort { $b->[0] <=> $a->[0] } map [ $_->start * $gene_strand, $_ ], @{$gene->get_all_Transcripts};
    
    foreach my $transcript (@sorted_transcripts) {
      my $transcript_stable_id = $transcript->stable_id;
# EG     
   #  if($gene->adaptor){ # don't try this if there is no adaptor...
        # we need this - sometimes the transcript object doesn't have all the translations
        my $_tsa = $gene->adaptor->db->get_adaptor('transcript');
        $transcript = $_tsa->fetch_by_stable_id($transcript_stable_id);
        $transcript = $transcript->transfer($gene->slice);
   #  }

      next if $transcript->start > $length || $transcript->end < 1;
      my @alt_translations = sort { $a->genomic_start <=> $b->genomic_start }  @{$transcript->get_all_alternative_translations};
      my $numTranslations=1+scalar @alt_translations;
      
      my @exons = sort { $a->start <=> $b->start } grep { $_ } @{$transcript->get_all_Exons}; # sort exons on their start coordinate 
            

      next unless scalar @exons; # Skip if no exons for this transcript
      next if @exons[0]->strand != $gene_strand && $self->{'do_not_strand'} != 1; # If stranded diagram skip if on wrong strand
      next if $target && $transcript->stable_id ne $target; # For exon_structure diagram only given transcript
      
      $transcript_drawn = 1;        

      my $composite = $self->Composite({
        y      => $y,
        height => $h,
        title  => $self->title($transcript, $gene),
        href   => $self->href($gene, $transcript)
      });

      my $colour_key = $self->colour_key($gene, $transcript);
      my $colour     = $meta->{'no_colour'}?undef:$self->my_colour($colour_key);
      my $label      = $self->my_colour($colour_key, 'text');
      my $highlight  = $selected_db eq $db && $transcript_stable_id ? (
        $selected_trans eq $transcript_stable_id ? 'highlight2' :
        $selected_gene  eq $gene_stable_id       ? 'highlight1' : undef 
      ) : undef;
      
      $highlight = $self->my_colour('ccds_hi') || 'lightblue1' if $transcript->get_all_Attributes('ccds')->[0]; # use another highlight colour if the trans has got a CCDS attrib

      $used_colours->{$label} = $colour;
      
      my $coding_start = defined $transcript->coding_region_start ? $transcript->coding_region_start : -1e6;
      my $coding_end   = defined $transcript->coding_region_end   ? $transcript->coding_region_end   : -1e6;
      
      my $composite2 = $self->Composite({ y => $y, height => $h });
               
      if ($transcript->translation) {
        $self->join_tag($composite2, $_->[0], 0.5, 0.5, $_->[1], 'line', $join_z) for @{$tags{$transcript->translation->stable_id}||[]};
      }
      
      if ($transcript->stable_id eq $tsid) {
        $self->join_tag($composite2, $_, 0.5, 0.5, $alt_alleles_col, 'line', $join_z) for @gene_tags;
        
        if (@gene_tags) {
          $config->{'legend_features'}{'joins'}{'priority'} ||= 1000;
          $config->{'legend_features'}{'joins'}{'legend'}{'Alternative alleles'} = $alt_alleles_col;
        }
      }
      
      my %composites;#one for each translation
      for (my $i = 0; $i < @exons; $i++) {
        my $exon = @exons[$i];
        
        next unless defined $exon; # Skip this exon if it is not defined (can happen w/ genscans) 
        
        my $next_exon = ($i < $#exons) ? @exons[$i+1] : undef; # First draw the exon
        last if $exon->start > $length; # We are finished if this exon starts outside the slice
        
        my ($box_start, $box_end);
        
        # only draw this exon if is inside the slice
        if ($exon->end > 0) { 
          # calculate exon region within boundaries of slice
          if(($start_point>$end_point)) {
                  $addition = $reg_end - $start_point + 1;
            #if($exon->slice->is_circular ) {
                  #  $addition = 0;
            #}
          } else {
                  $addition = 0;
          }

          $box_start = $exon->start;
          $box_start = 1 if $box_start < 1 ;
          $box_end = $exon->end;
          $box_end = $length if $box_end > $length;
          # The start of the transcript is before the start of the coding
          # region OR the end of the transcript is after the end of the
          # coding regions.  Non coding portions of exons, are drawn as
          # non-filled rectangles
          # Draw a non-filled rectangle around the entire exon
    
          if ($box_start < $coding_start || $box_end > $coding_end) {
            $composite2->push($self->Rect({
              x            => $box_start + $addition - 1 ,
              y            => $y + $non_coding_start,
              width        => $box_end - $box_start  + 1,
              height       => $non_coding_height,
              bordercolour => $colour,
              absolutey    => 1
             }));
           }
           
           # Calculate and draw the coding region of the exon
           my $filled_start = $box_start < $coding_start ? $coding_start : $box_start;
           my $filled_end   = $box_end > $coding_end ? $coding_end : $box_end;
           
           # only draw the coding region if there is such a region
           if ($filled_start <= $filled_end ) {
              # Draw a filled rectangle in the coding region of the exon
              $composite2->push($self->Rect({
                x         => $filled_start + $addition - 1,
                y         => $y,
                width     => $filled_end - $filled_start + 1,
                height    => $h/$numTranslations,
                colour    => $colour,
                absolutey => 1
              }));
          }
          my $translationIndex=1;
          foreach my $alt_translation (@alt_translations){
            my $t_coding_start=$alt_translation->genomic_start;
            my $t_coding_end=$alt_translation->genomic_end;
            # Calculate and draw the coding region of the exon
            my $t_filled_start = $box_start < $t_coding_start ? $t_coding_start : $box_start;
            my $t_filled_end   = $box_end > $t_coding_end     ? $t_coding_end   : $box_end;
            # only draw the coding region if there is such a region
            # Draw a filled rectangle in the coding region of the exon
            if ($t_filled_start <= $t_filled_end) {
              $composites{$alt_translation->stable_id} = $self->Composite({ y => $y, height => $h }) unless defined $composites{$alt_translation->stable_id};
              my $_y= (int(10 * ($y + $translationIndex * $h/$numTranslations)))/10;
              my $_h= (int(10 * ($h/$numTranslations)))/10;
              $composites{$alt_translation->stable_id}->push(
                $self->Rect({
                 x         => abs($t_filled_start + $addition - 1),
                 width     => abs($t_filled_end - $t_filled_start + 1),
                 y         => $_y,
                 height    => $_h,
                 colour => $colour,
                 absolutey => 1,
                 absolutex => 0
                 }
                )
              );
            }
            $translationIndex++;
          }
        }
        
        # we are finished if there is no other exon defined
        last unless defined $next_exon;

        my $intron_start = $exon->end + 1; # calculate the start and end of this intron
        my $intron_end = $next_exon->start - 1;
        
        next if $intron_end < 0;         # grab the next exon if this intron is before the slice
        last if $intron_start > $length; # we are done if this intron is after the slice

        if(($start_point>$end_point) && ($gene->slice->end == $end_point) && ($gene->slice->start != $start_point)) {
            $addition = $reg_end - $start_point + 1;
          #if ($exon->slice->is_circular) {
          # $addition = 0;
          #}
        } else {
            $addition = 0;
        }
        
        # calculate intron region within slice boundaries
        $box_start = $intron_start < 1 ? 1 : $intron_start;
        $box_end   = $intron_end > $length ? $length : $intron_end;
        
        my $intron;
        
        if ($box_start == $intron_start && $box_end == $intron_end) {
          # draw an wholly in slice intron
          $composite2->push($self->Intron({
            x         => $box_start + $addition - 1,
            y         => $y,
            width     => $box_end - $box_start + 1,
            height    => $h,
            colour    => $colour,
            absolutey => 1,
            strand    => $strand
          }));
        } else { 
          # else draw a "not in slice" intron
          $composite2->push($self->Line({
            x         => $box_start + $addition - 1 ,
            y         => $y + int($h/2),
            width     => $box_end - $box_start + 1,
            height    => 0,
            absolutey => 1,
            colour    => $colour,
            dotted    => 1
          }));
        }
      }
      
      foreach my $alt_translation (@alt_translations) {
        $composite2->push($composites{$alt_translation->stable_id});
      }
      $composite->push($composite2);
      
      my $bump_height = 1.5 * $h;
      if ($show_labels ne 'off' && $labels) {
        if (my $text_label = $self->feature_label($gene, $transcript)) {
          my @lines = split "\n", $text_label; 
          
          for (my $i = 0; $i < @lines; $i++) {
            my $line = "$lines[$i] ";
            my $w = ($self->get_text_width(0, $line, '', 'ptsize' => $fontsize, 'font' => $fontname))[2];
            
            $composite->push($self->Text({
              x         => $composite->x,                          #$addition
              y         => $y + $h + $i*($th+1),
              height    => $th,
              width     => $w / $pix_per_bp,
              font      => $fontname,
              ptsize    => $fontsize,
              halign    => 'left', 
              colour    => $colour,
              text      => $line,
              absolutey => 1
            }));
            
            $bump_height += $th + 1;
          }
        }
      }

      # bump
      my $bump_start = int($composite->x * $pix_per_bp);
      my $bump_end = $bump_start + int($composite->width * $pix_per_bp) + 1;
      my $row = $self->bump_row($bump_start, $bump_end) unless $no_bump;
      
      # shift the composite container by however much we're bumped
      $composite->y($composite->y - $strand * $bump_height * $row);
      
      $composite->colour($highlight) if defined $highlight && !defined $target;
      $all_composite->push($composite);#for gene if single, else operon
    }# end of one transcript
  }# end of one gene
  return $all_composite;
}

1;
