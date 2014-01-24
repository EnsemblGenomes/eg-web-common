# $Id: VariationImage.pm,v 1.6 2013-06-11 13:06:19 jk10 Exp $

package EnsEMBL::Web::Component::Gene::VariationImage;

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
  $self->has_image(1);
  $self->configurable(1);
}

sub content {
  my $self        = shift;
  my $no_snps     = shift;
  my $ic_type     = shift || 'gene_variation';  
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $image_width = $self->image_width     || 800;  
  my $context     = $hub->param('context') || 100; 
  my $extent      = $context eq 'FULL' ? 5000 : $context;
  my @confs       = qw(gene transcripts_top transcripts_bottom);
  my $image_configs;
  my $v           = $hub->param('v') || undef;
  my $r           = $hub->param('r');

  my ($reg_name, $start, $end) = $r =~ /(.+?):(\d+)-(\d+)/ if $r =~ /:/;

  my $slice = $object->database('core')->get_SliceAdaptor->fetch_by_region(
     $object->seq_region_type, $reg_name, $start, $end, 1);
  # Padding
  # Get 4 configs - and set width to width of context config
  # Get two slice -  gene (4/3x) transcripts (+/-extent)
  
  push @confs, 'snps' unless $no_snps;  

  foreach (@confs) { 
    $image_configs->{$_} = $hub->get_imageconfig($_ eq 'gene' ? $ic_type : 'gene_variation', $_);
    $image_configs->{$_}->set_parameters({
      image_width => $image_width, 
      context     => $context
    });
  }

  my $get_munged_slices = $object->get_munged_slice2( 1, $slice);
  my $sub_slices       =  $get_munged_slices->[2]; 


  # Fake SNPs
  # Grab the SNPs and map them to subslice co-ordinate
  # $snps contains an array of array each sub-array contains [fake_start, fake_end, B:E:Variation object] # Stores in $object->__data->{'SNPS'}

  my ($count_snps, $snps, $context_count) = $object->getVariationsOnSlice( $slice, $sub_slices  );
  my $start_difference =  0; 

  my @fake_filtered_snps;
  map { push @fake_filtered_snps,
     [ $_->[2]->start + $start_difference,
       $_->[2]->end   + $start_difference,
       $_->[2]] } @$snps;

  $image_configs->{'gene'}->{'filtered_fake_snps'} = \@fake_filtered_snps unless $no_snps;


  # Make fake transcripts
  $object->store_TransformedTranscripts($start);        ## Stores in $transcript_object->__data->{'transformed'}{'exons'|'coding_start'|'coding_end'}

  my @domain_logic_names = qw(Pfam scanprosite Prints pfscan PrositePatterns PrositeProfiles Tigrfam Superfamily Smart PIRSF 
                              seg blastprodom gene3d hmmpanther ncoils signalp tmhmm);

  foreach( @domain_logic_names ) { 
    $object->store_TransformedDomains($_, $start);              ## Stores in $transcript_object->__data->{'transformed'}{'Pfam_hits'}
  }
  $object->store_TransformedSNPS() unless $no_snps;      ## Stores in $transcript_object->__data->{'transformed'}{'snps'}

  # This is where we do the configuration of containers
  my @transcripts            = ();
  my @containers_and_configs = (); ## array of containers and configs

## sort so trancsripts are displayed in same order as in transcript selector table  
  my $strand = $object->Obj->strand;
  my @trans = @{$object->get_all_transcripts};
  my @sorted_trans;
  if ($strand ==1 ){
    @sorted_trans = sort { $b->Obj->external_name cmp $a->Obj->external_name || $b->Obj->stable_id cmp $a->Obj->stable_id } @trans;
  } else {
    @sorted_trans = sort { $a->Obj->external_name cmp $b->Obj->external_name || $a->Obj->stable_id cmp $b->Obj->stable_id } @trans;
  } 

  foreach my $trans_obj (@sorted_trans ) {  
## create config and store information on it...

    $trans_obj->__data->{'transformed'}{'extent'} = $extent;
    my $CONFIG = $hub->get_imageconfig( "${ic_type}", $trans_obj->stable_id );
    $CONFIG->init_transcript;
    $CONFIG->{'geneid'}     = $object->stable_id;
    $CONFIG->{'snps'}       = $snps unless $no_snps;
    $CONFIG->{'subslices'}  = $sub_slices;
    $CONFIG->{'extent'}     = $extent;
    $CONFIG->{'var_image'}   = 1;
    $CONFIG->{'_add_labels'} = 1;
      ## Store transcript information on config....
    my $TS = $trans_obj->__data->{'transformed'};
    $CONFIG->{'transcript'} = {
      'exons'        => $TS->{'exons'},
      'coding_start' => $TS->{'coding_start'},
      'coding_end'   => $TS->{'coding_end'},
      'transcript'   => $trans_obj->Obj,
      'gene'         => $object->Obj,
      $no_snps ? (): ('snps' => $TS->{'snps'})
    }; 
    
    $CONFIG->modify_configs( ## Turn on track associated with this db/logic name
      [$CONFIG->get_track_key( 'gsv_transcript', $object )],
      {qw(display normal show_labels off),'caption' => ''}  ## also turn off the transcript labels...
    );

    foreach ( @domain_logic_names ) { 
      $CONFIG->{'transcript'}{lc($_).'_hits'} = $TS->{lc($_).'_hits'};
    }  

###   # $CONFIG->container_width( $object->__data->{'slices'}{'transcripts'}[3] ); 

    $CONFIG->set_parameters({'container_width' => $slice->length   });
    $CONFIG->tree->dump("Transcript configuration", '([[caption]])')
    if $object->species_defs->ENSEMBL_DEBUG_FLAGS & $object->species_defs->ENSEMBL_DEBUG_TREE_DUMPS;

   if( $object->seq_region_strand < 0 ) {
      #push @containers_and_configs, $transcript_slice, $CONFIG;
       push @containers_and_configs, $slice, $CONFIG;
    } else {
      ## If forward strand we have to draw these in reverse order (as forced on -ve strand)
      #unshift @containers_and_configs, $transcript_slice, $CONFIG;
      unshift @containers_and_configs, $slice, $CONFIG;  
    }
    push @transcripts, { 'exons' => $TS->{'exons'} };
  }

## -- Map SNPs for the last SNP display --------------------------------- ##
  my $SNP_REL     = 5; ## relative length of snp to gap in bottom display...
  my $fake_length = -1; ## end of last drawn snp on bottom display...
  my $slice_trans = $transcript_slice;

## map snps to fake evenly spaced co-ordinates...
  my @snps2;
  unless( $no_snps ) {
    @snps2 = map {
      $fake_length+=$SNP_REL+1;
      [ $fake_length-$SNP_REL+1 ,$fake_length,$_->[2], $slice->seq_region_name,
        $slice->strand > 0 ?
          ( $slice->start + $_->[2]->start - 1,
            $slice->start + $_->[2]->end   - 1 ) :
          ( $slice->end - $_->[2]->end     + 1,
            $slice->end - $_->[2]->start   + 1 )
      ]
    } sort { $a->[0] <=> $b->[0] } @{ $snps };
## Cache data so that it can be retrieved later...
    #$object->__data->{'gene_snps'} = \@snps2; fc1 - don't think is used
    foreach my $trans_obj ( @{$object->get_all_transcripts} ) {
      $trans_obj->__data->{'transformed'}{'gene_snps'} = \@snps2;
    }
  }

  # Tweak the configurations for the five sub images
  # Gene context block;
  my $gene_stable_id = $object->stable_id;

  # Transcript block
  $image_configs->{'gene'}->{'geneid'}      = $gene_stable_id; 
  $image_configs->{'gene'}->set_parameters({ 'container_width' => $slice->length });

  $image_configs->{'gene'}->modify_configs( ## Turn on track associated with this db/logic name
    [$image_configs->{'gene'}->get_track_key( 'transcript', $object )],
    {'display'=> 'off', 'menu' => 'no'}   #turn off transcript track - it is already displayed in the GeneSNPImageTop  
  );
 
  # Intronless transcript top and bottom (to draw snps, ruler and exon backgrounds)
 foreach(qw(transcripts_top transcripts_bottom)) {
   $image_configs->{$_}->{'extent'}      = $extent;
   $image_configs->{$_}->{'geneid'}      = $gene_stable_id;
   $image_configs->{$_}->{'transcripts'} = \@transcripts;
   $image_configs->{$_}->{'snps'}        = $object->__data->{'SNPS'} unless $no_snps;
   $image_configs->{$_}->{'subslices'}   = $sub_slices;
   $image_configs->{$_}->{'fakeslice'}   = 1;
   $image_configs->{$_}->set_parameters({ 'container_width' => $slice->length });
  }
  $image_configs->{'transcripts_bottom'}->get_node('spacer')->set('display','off') if $no_snps;
  # SNP box track
  unless( $no_snps ) {
    $image_configs->{'snps'}->{'fakeslice'}   = 1;
    $image_configs->{'snps'}->{'snps'}        = \@snps2; 
    $image_configs->{'snps'}->set_parameters({ 'container_width' => $fake_length });  #???
    $image_configs->{'snps'}->{'snp_counts'} = [$count_snps, scalar @$snps, $context_count];
  } 

  # Render image
  my $image = $self->new_image([
      $slice, $image_configs->{'gene'},
      $slice, $image_configs->{'transcripts_top'}, 
      @containers_and_configs,
      $slice, $image_configs->{'transcripts_bottom'},  
      $no_snps ? ():
      ($slice, $image_configs->{'snps'})
    ],
    [ $object->stable_id, $v]
  );

  return if $self->_export_image($image, 'no_text');

  $image->imagemap         = 'yes';
  $image->{'panel_number'} = 'top';
  $image->set_button( 'drag', 'title' => 'Drag to select region' );
  
  my $html = $image->render; 
  
  if ($no_snps) {
    $html .= $self->_info(
      'Configuring the display',
      "<p>Tip: use the '<strong>Configure this page</strong>' link on the left to customise the protein domains displayed above.</p>"
    );
    return $html;
  }
  
  my $info_text = $self->config_info($image_configs->{'snps'});
  
  $html .= $self->_info(
    'Configuring the display',
    qq{
    <p>
      Tip: use the '<strong>Configure this page</strong>' link on the left to customise the protein domains and types of variations displayed above.<br />
      Please note the default 'Context' settings will probably filter out some intronic SNPs.<br />
      $info_text
    </p>}
  );
  
  return $html;
}

1;

