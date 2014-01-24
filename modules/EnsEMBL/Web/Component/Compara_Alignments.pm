package EnsEMBL::Web::Component::Compara_Alignments;

use strict;

use HTML::Entities qw(encode_entities);

sub content {
  my $self      = shift;
  my $object    = $self->object;
  my $cdb       = shift || $object->param('cdb') || 'compara';
  my $slice     = $object->can('slice') ? $object->slice : $object->get_slice_object->Obj;
  my $threshold = 1000100 * ($object->species_defs->ENSEMBL_GENOME_SIZE||1);
  my $species   = $object->species;
  my $type      = $object->type;
  my $hub       = $self->hub;

  if ($type eq 'Location' && $slice->length > $threshold) {
    return $self->_warning(
      'Region too large',
      '<p>The region selected is too large to display in this view - use the navigation above to zoom in...</p>'
    );
  }
  
  my $align_param = $object->param('align');
  my ($align) = split '--', $align_param;
  
  my ($error, $warnings) = $self->check_for_align_errors($align, $species, $cdb);

  return $error if $error;
  
  my $html;
  
  if ($type eq 'Gene') {
    my $location = $object->Obj; # Use this instead of $slice because the $slice region includes flanking
    
    $html .= sprintf(
      '<p style="padding:0.5em 0 1.5em"><strong><a href="%s">Go to a graphical view</a> (Genomic align slice) of this alignment</strong></p>',
      $hub->url({
        type   => 'Location',
        action => 'Compara_Alignments/Image',
        align  => $align,
        r      => $location->seq_region_name . ':' . $location->seq_region_start . '-' . $location->seq_region_end
      })
    );
  }
  
  $slice = $slice->invert if $object->param('strand') == -1;

  if($slice->start > $slice->end)  {


      my $sl1 = Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                         -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                         -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                         -START              => $slice->{'start'},
                                         -END                => $slice->{'seq_region_length'},
                                         -STRAND             => $slice->{'strand'},
                                         -ADAPTOR            => $slice->{'adaptor'});

      my $sl2 = Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                         -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                         -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                         -START              => 1,
                                         -END                => $slice->{'end'},
                                         -STRAND             => $slice->{'strand'},
                                         -ADAPTOR            => $slice->{'adaptor'});



      my ($slices1, $slice_length1) = $self->get_slices($sl1, $align_param, $species, undef, undef, $cdb);
      my ($slices2, $slice_length2) = $self->get_slices($sl2, $align_param, $species, undef, undef, $cdb);
      my ($slices, $slice_length) =   $self->get_slices($slice, $align_param, $species, undef, undef, $cdb);

      my $total_length = $slice_length1 + $slice_length2;
      if ($align && $total_length >= $self->{'subslice_length'}) {
          my ($table, $padding) = $self->get_slice_table($slices, 1);
          #warn 'BEFORE CHUNKING';

          $html .= '<div class="sequence_key"></div>' . $table 
            . $self->chunked_content($slice_length1, $self->{'subslice_length'}, {padding => $padding, length => $slice_length1, slicepart => 1}) 
            . $self->chunked_content($slice_length2, $self->{'subslice_length'}, {padding => $padding, length => $slice_length2, slicepart => 2}) . $warnings;

      } else {
          $html .= $self->content_sub_slice($slice, $slices, $warnings, undef, $cdb); # Direct call if the sequence length is short enough           
      }

      return $html;

  } #if($slice->start > $slice->end)           
  
  # Get all slices for the gene
  my ($slices, $slice_length) = $self->get_slices($slice, $align_param, $species, undef, undef, $cdb);
  
  if ($align && $slice_length >= $self->{'subslice_length'}) {
    my ($table, $padding) = $self->get_slice_table($slices, 1);   
    $html .= '<div class="sequence_key"></div>' . $table . $self->chunked_content($slice_length, $self->{'subslice_length'}, {padding => $padding, length => $slice_length}) . $warnings;
  } else {
    $html .= $self->content_sub_slice($slice, $slices, $warnings, undef, $cdb); # Direct call if the sequence length is short enough
  }
  
  return $html;
}

sub content_sub_slice {
  my $self = shift;
  my ($slice, $slices, $warnings, $defaults, $cdb) = @_;
  
  my $object = $self->object;
  
  $slice ||= $object->can('slice') ? $object->slice : $object->get_slice_object->Obj;
  $slice = $slice->invert if !$_[0] && $object->param('strand') == -1;
  
  my $start = $object->param('subslice_start');
  my $end = $object->param('subslice_end');
  my $padding = $object->param('padding');
  my $slice_length = $object->param('length') || $slice->length;
  my $slicepart = $object->param('slicepart');

  my $config = {
    display_width   => $object->param('display_width') || 60,
    site_type       => ucfirst lc $object->species_defs->ENSEMBL_SITETYPE || 'Ensembl',
    species         => $object->species,
    comparison      => 1,
    db              => $object->can('get_db') ? $object->get_db : 'core',
    sub_slice_start => $start,
    sub_slice_end   => $end
  };
  
  for (qw(exon_display exon_ori snp_display line_numbering conservation_display codons_display region_change_display title_display align)) {
    $config->{$_} = $object->param($_) unless $object->param($_) eq 'off';
  }
  
  if ($config->{'line_numbering'}) {
    $config->{'end_number'} = 1;
    $config->{'number'}     = 1;
  }
  
  $config = { %$config, %$defaults } if $defaults;
  
  # Requesting data from a sub slice                                                                                                                                                          
  #CASE 1: SPLITTING THE SLICE, NO CHUNKING                                                                                                                                        
  if ( ($slice->start > $slice->end) && (!$start &&  !$end) )  {

       #warn 'CASE 1: SPLITTING THE SLICE, NO CHUNKING';

       my ($slices0, $slices1, $slices2);
       my (@arr_slices, @arr_table);

       my $sl1 = Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                       -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                       -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                       -START              => $slice->{'start'},
                                       -END                => $slice->{'seq_region_length'},
                                       -STRAND             => $slice->{'strand'},
                                       -ADAPTOR            => $slice->{'adaptor'});

       my $sl2 = Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                       -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                       -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                       -START              => 1,
                                       -END                => $slice->{'end'},
                                       -STRAND             => $slice->{'strand'},
                                       -ADAPTOR            => $slice->{'adaptor'});


       ($slices1) = $self->get_slices($sl1, $config->{'align'}, $config->{'species'}, undef, undef, $cdb);
       ($slices2) = $self->get_slices($sl2, $config->{'align'}, $config->{'species'}, undef, undef, $cdb);

       if (ref($slices1) eq "ARRAY") {
           push @arr_slices, $slices1;
           push @arr_table, @{$slices1};
       }
       if (ref($slices2) eq "ARRAY") {
           push @arr_slices, $slices2;
           push @arr_table, @{$slices2};
       }

       my $res_html = "";
       $res_html .= $self->get_key($object).$self->get_slice_table(\@arr_table);
       foreach $slices (@arr_slices) {
          $config->{'slices'} = $slices;

          my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);

          # markup_comparisons must be called first to get the order of the comparison sequences                                                                                                                    
          # The order these functions are called in is also important because it determines the order in which things are added to $config->{'key'}                                                                 

          $self->markup_comparisons($sequence, $markup, $config) if $config->{'align'};
          $self->markup_conservation($sequence, $config) if $config->{'conservation_display'};
          $self->markup_region_change($sequence, $markup, $config) if $config->{'region_change_display'};
          $self->markup_codons($sequence, $markup, $config) if $config->{'codons_display'};
          $self->markup_exons($sequence, $markup, $config) if $config->{'exon_display'};
          $self->markup_variation($sequence, $markup, $config) if $config->{'snp_display'};
          $self->markup_line_numbers($sequence, $config) if $config->{'line_numbering'};
          my $style = $start == 1 ? "margin-bottom:0px;" : $end == $slice_length ? "margin-top:0px;" : "margin-top:0px; margin-bottom:0px" if $start && $end;

          $config->{'html_template'} = qq{<pre style="$style">%s</pre>};

          if ($padding) {
            my @pad = split ',', $padding;
            $config->{'padded_species'}->{$_} = $_ . (' ' x ($pad[0] - length $_)) for keys %{$config->{'padded_species'}};

            if ($config->{'line_numbering'} eq 'slice') {
                $config->{'padding'}->{'pre_number'} = $pad[1];
                $config->{'padding'}->{'number'} = $pad[2];
            }
          }

          $res_html.= $self->build_sequence($sequence, $config);

       } # foreach $slices                                                                                                                                                                                           

      return  $res_html. $warnings;
  }

  #CASE 2: DIVIDING THE SLICE IN TWO PARTS, CHUNKING FOR EACH PART                                                                                                          
  elsif ( ($slice->start > $slice->end) && ($start &&  $end) )  {

     #warn 'CASE 2: DIVIDING THE SLICE IN TWO PARTS, CHUNKING FOR EACH PART';
     my $sl;
     if($slicepart == 1) {
         $sl = Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                       -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                       -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                       -START              => $slice->{'start'},
                                       -END                => $slice->{'seq_region_length'},
                                       -STRAND             => $slice->{'strand'},
                                       -ADAPTOR            => $slice->{'adaptor'});
     }  elsif($slicepart == 2){
         $sl = Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                       -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                       -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                       -START              => 1,
                                       -END                => $slice->{'end'},
                                       -STRAND             => $slice->{'strand'},
                                       -ADAPTOR            => $slice->{'adaptor'});

     }

     ($slices) = $self->get_slices($sl, $config->{'align'}, $config->{'species'}, $start, $end, $cdb);

  }  else {
     ($slices) = $self->get_slices($slice, $config->{'align'}, $config->{'species'}, $start, $end, $cdb) if $start && $end;
  }

  # Requesting data from a sub slice
 
  
  $config->{'slices'} = $slices;
  
  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);
  
  # markup_comparisons must be called first to get the order of the comparison sequences
  # The order these functions are called in is also important because it determines the order in which things are added to $config->{'key'}
  $self->markup_comparisons($sequence, $markup, $config)   if $config->{'align'};
  $self->markup_conservation($sequence, $config)           if $config->{'conservation_display'};
  $self->markup_region_change($sequence, $markup, $config) if $config->{'region_change_display'};
  $self->markup_codons($sequence, $markup, $config)        if $config->{'codons_display'};
  $self->markup_exons($sequence, $markup, $config)         if $config->{'exon_display'};
  $self->markup_variation($sequence, $markup, $config)     if $config->{'snp_display'};
  $self->markup_line_numbers($sequence, $config)           if $config->{'line_numbering'};
  
  # Only if this IS NOT a sub slice - print the key and the slice list
  my $template = sprintf('<div class="sequence_key">%s</div>', $self->get_key($config)) . $self->get_slice_table($config->{'slices'}) unless $start && $end;
  
  # Only if this IS a sub slice - remove margins from <pre> elements
  my $style = $start == 1 ? 'margin-bottom:0px;' : $end == $slice_length ? 'margin-top:0px;': 'margin-top:0px; margin-bottom:0px' if $start && $end;
  
  $config->{'html_template'} = qq{$template<pre style="$style">%s</pre>};
  
  if ($padding) {
    my @pad = split ',', $padding;
    
    $config->{'padded_species'}->{$_} = $_ . (' ' x ($pad[0] - length $_)) for keys %{$config->{'padded_species'}};
    
    if ($config->{'line_numbering'} eq 'slice') {
      $config->{'padding'}->{'pre_number'} = $pad[1];
      $config->{'padding'}->{'number'}     = $pad[2];
    }
  }
  
  return $self->build_sequence($sequence, $config) . $warnings;
}


sub get_slices {
  my $self = shift;
  my ($slice, $align, $species, $start, $end, $cdb) = @_;
  my (@slices, @formatted_slices, $length);
  my $underlying_slices = !$self->has_image; # Don't get underlying slices for alignment images - they are only needed for text sequence views, and the process is slow.

## EG  
  my ($length1, $length2);
  if ($align) {
      if($slice->start > $slice->end) {

          #warn ' Slice is split! ';
          my $sl1= Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                            -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                            -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                            -START              => $slice->{'start'},
                                            -END                => $slice->{'seq_region_length'},
                                            -STRAND             => $slice->{'strand'},
                                            -ADAPTOR            => $slice->{'adaptor'});

          my $sl2= Bio::EnsEMBL::Slice->new(-COORD_SYSTEM      =>  $slice->{'coord_system'},
                                            -SEQ_REGION_NAME    => $slice->{'seq_region_name'},
                                            -SEQ_REGION_LENGTH  => $slice->{'seq_region_length'},
                                            -START              => 1,
                                            -END                => $slice->{'end'},
                                            -STRAND             => $slice->{'strand'},
                                            -ADAPTOR            => $slice->{'adaptor'});


          $length1 = $self->get_alignments($sl1, $align, $species)->[0]->length;
          $length2 = $self->get_alignments($sl2, $align, $species)->[0]->length;
          $length = $length1 + $length2; #Although in this case length doesn't play any role                                                                          
          #NO $start and $end  are passed                                                                         
          push @slices, @{$self->get_alignments($sl1, $align, $species, undef, undef, $cdb)};
          push @slices, @{$self->get_alignments($sl2, $align, $species, undef, undef, $cdb)};

      } else  {
          push @slices, @{$self->get_alignments(@_)};
      }

  } else {
    push @slices, $slice; # If no alignment selected then we just display the original sequence as in geneseqview
  }
##
  
  foreach (@slices) {
    my $name = $_->can('display_Slice_name') ? $_->display_Slice_name : $species;
    
    push @formatted_slices, {
      slice             => $_,
      underlying_slices => $underlying_slices && $_->can('get_all_underlying_Slices') ? $_->get_all_underlying_Slices : [ $_ ],
      name              => $name,
      display_name      => $self->get_slice_display_name($name, $_)
    };
    
    $length ||= $_->length; # Set the slice length value for the reference slice only
  }
  
  return (\@formatted_slices, $length);
}

1;
