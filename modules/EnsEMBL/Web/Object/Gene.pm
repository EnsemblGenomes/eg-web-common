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

# $Id: Gene.pm,v 1.29 2013-12-06 12:09:01 nl2 Exp $

package EnsEMBL::Web::Object::Gene;

use Data::Dumper;

sub counts {
  my $self = shift;
  my $obj = $self->Obj;

  return {} unless $obj->isa('Bio::EnsEMBL::Gene');
  
  my $key = sprintf '::COUNTS::GENE::%s::%s::%s::', $self->species, $self->hub->core_param('db'), $self->hub->core_param('g');
  my $counts = $self->{'_counts'};
  $counts ||= $MEMD->get($key) if $MEMD;
  
  if (!$counts) {
    $counts = {
      transcripts        => scalar @{$obj->get_all_Transcripts},
      exons              => scalar @{$obj->get_all_Exons},
      similarity_matches => $self->get_xref_available,
      operons => 0,
    };
    if ($obj->feature_Slice->can('get_all_Operons')){
      $counts->{'operons'} = scalar @{$obj->feature_Slice->get_all_Operons};
    }
    $counts->{structural_variation} = 0;
    if ($self->database('variation')){ 
      my $vdb = $self->species_defs->get_config($self->species,'databases')->{'DATABASE_VARIATION'};
      $counts->{structural_variation} = $vdb->{'tables'}{'structural_variation'}{'rows'};
    }
    my $compara_db = $self->database('compara');
    
    if ($compara_db) {
      my $compara_dbh = $compara_db->get_MemberAdaptor->dbc->db_handle;
      
      if ($compara_dbh) {
        $counts = {%$counts, %{$self->count_homologues($compara_dbh)}};
      
        my ($res) = $compara_dbh->selectrow_array(
          'select count(*) from family_member fm, member as m where fm.member_id=m.member_id and stable_id=? and source_name =?',
          {}, $obj->stable_id, 'ENSEMBLGENE'
        );
        
        $counts->{'families'} = $res;
      }
      my $alignments = $self->count_alignments;
      $counts->{'alignments'} = $alignments->{'all'} if $self->get_db eq 'core';
      $counts->{'pairwise_alignments'} = $alignments->{'pairwise'} + $alignments->{'patch'};
    }
    if (my $compara_db = $self->database('compara_pan_ensembl')) {
      my $compara_dbh = $compara_db->get_MemberAdaptor->dbc->db_handle;

      my $pan_counts = {};

      if ($compara_dbh) {
        $pan_counts = $self->count_homologues($compara_dbh);
      
        my ($res) = $compara_dbh->selectrow_array(
          'select count(*) from family_member fm, member as m where fm.member_id=m.member_id and stable_id=? and source_name =?',
          {}, $obj->stable_id, 'ENSEMBLGENE'
        );
        
        $pan_counts->{'families'} = $res;
      }
      
      $pan_counts->{'alignments'} = $self->count_alignments('DATABASE_COMPARA_PAN_ENSEMBL')->{'all'} if $self->get_db eq 'core';

      foreach (keys %$pan_counts) {
        my $key = $_."_pan";
        $counts->{$key} = $pan_counts->{$_};
      }
    }

    $counts = {%$counts, %{$self->_counts}};

    $MEMD->set($key, $counts, undef, 'COUNTS') if $MEMD;
    $self->{'_counts'} = $counts;
  }
  
  return $counts;
}

sub store_TransformedTranscripts {
  my $self = shift;
  my $offset = shift;  

  $offset ||= $self->__data->{'slices'}{'transcripts'}->[1]->start -1;

  foreach my $trans_obj ( @{$self->get_all_transcripts} ) {
    my $transcript = $trans_obj->Obj;
  my ($raw_coding_start,$coding_start);
  if (defined( $transcript->coding_region_start )) {    
    $raw_coding_start = $transcript->coding_region_start;
    $raw_coding_start -= $offset;
    $coding_start = $raw_coding_start + $self->munge_gaps( 'transcripts', $raw_coding_start );
  }
  else {
    $coding_start  = undef;
    }

  my ($raw_coding_end,$coding_end);
  if (defined( $transcript->coding_region_end )) {
    $raw_coding_end = $transcript->coding_region_end;
    $raw_coding_end -= $offset;
    $coding_end = $raw_coding_end + $self->munge_gaps( 'transcripts', $raw_coding_end );
  }
  else {
    $coding_end = undef;
  }
    my $raw_start = $transcript->start;
    my $raw_end   = $transcript->end  ;
    my @exons = ();
    foreach my $exon (@{$transcript->get_all_Exons()}) {
      my $es = $exon->start - $offset; 
      my $ee = $exon->end   - $offset;
      my $O =  $self->munge_gaps( 'transcripts', $es );

      push @exons, [ $es + $O, $ee + $O, $exon ];
    }
    $coding_start ||= 1;
    $coding_end   ||= 1;
    $trans_obj->__data->{'transformed'}{'exons'}        = \@exons;
    $trans_obj->__data->{'transformed'}{'coding_start'} = $coding_start;
    $trans_obj->__data->{'transformed'}{'coding_end'}   = $coding_end;
    $trans_obj->__data->{'transformed'}{'start'}        = $raw_start;
    $trans_obj->__data->{'transformed'}{'end'}          = $raw_end;
  }
}

sub store_TransformedDomains {
    my $self = shift;
    my $key  = shift;
    my $offset = shift;

    my %domains;

    $offset ||= $self->__data->{'slices'}{'transcripts'}->[1]->start -1;
    foreach my $trans_obj ( @{$self->get_all_transcripts} ) {
	my %seen;
	my $transcript = $trans_obj->Obj;
	next unless $transcript->translation;
	foreach my $pf ( @{$transcript->translation->get_all_ProteinFeatures( lc($key) )} ) {
## rach entry is an arry containing the actual pfam hit, and mapped start and end co-ordinates
	    if (exists $seen{$pf->id}{$pf->start}){
		next;
	    } else {
		$seen{$pf->id}->{$pf->start} =1;
		my @A = ($pf);
		foreach( $transcript->pep2genomic( $pf->start, $pf->end ) ) {
		    my $O = $self->munge_gaps( 'transcripts', $_->start - $offset, $_->end - $offset) - $offset;
		    push @A, $_->start + $O, $_->end + $O;
		}
		push @{$trans_obj->__data->{'transformed'}{lc($key).'_hits'}}, \@A;
	    }
	}
    }
}


sub get_munged_slice2 {
    my $self = shift;
    my $ori     = shift;
    my $slice   = shift;
    my $CONTEXT = 'FULL'; 

    $slice    = $slice->invert if $ori && $slice->strand != $ori;
    $slice = $slice->expand($CONTEXT, $CONTEXT);

    my $gene_stable_id = $self->stable_id;

    my $length = $slice->length();
  
    my $EXTENT  = $CONTEXT eq 'FULL' ? 1000 : $CONTEXT;
  ## first get all the transcripts for a given gene...                                           
    my @ANALYSIS = ( $self->get_db() eq 'core' ? (lc($self->species_defs->AUTHORITY)||'ensembl') : 'otter' );
    @ANALYSIS = qw(ensembl havana ensembl_havana_gene) if $ENV{'ENSEMBL_SPECIES'} eq 'Homo_sapiens';
  # my $features = [map { @{ $slice->get_all_Genes($_)||[]} } @ANALYSIS ];                                                                                                                               
    my $features = $slice->get_all_Genes( undef, $self->param('opt_db') );
    my @lengths;

    @lengths = ( $length );

  ## @lengths contains the sizes of gaps and exons(+- context)                                                                                                                         
    my $collapsed_length = 0;
    my $flag = 0;
    my $subslices = [];
    my $pos = 0;
    foreach(@lengths,0) {
	if ($flag=1-$flag) {
	    push @$subslices, [ $pos+1, 0, 0 ] ;
	    $collapsed_length += $_;
	} else {
	    $subslices->[-1][1] = $pos;
	}
	$pos+=$_;
    }
  ## compute the width of the slice image within the display                                                                                                                                            
  my $PIXEL_WIDTH =
    ($self->param('image_width')||800) -
        ( $self->param( 'label_width' ) || 100 ) -
	3 * ( $self->param( 'margin' )      ||   5 );

  ## Work out the best size for the gaps between the "exons"                                                                                                                                             
    my $fake_intron_gap_size = 11;
    my $intron_gaps  = ((@lengths-1)/2);

    if( $intron_gaps * $fake_intron_gap_size > $PIXEL_WIDTH * 0.75 ) {
	$fake_intron_gap_size = int( $PIXEL_WIDTH * 0.75 / $intron_gaps );
    }
  ## Compute how big this is in base-pairs                                                                                                                                                         
    my $exon_pixels  = $PIXEL_WIDTH - $intron_gaps * $fake_intron_gap_size;
    my $scale_factor = $collapsed_length / $exon_pixels;
    my $padding      = int($scale_factor * $fake_intron_gap_size) + 1;
    $collapsed_length += $padding * $intron_gaps;

  ## Compute offset for each subslice                                                                                                                                               
    my $start = 0;
    foreach(@$subslices) {
	$_->[2] = $start - $_->[0];
	$start += $_->[1]-$_->[0]-1 + $padding;
    }

    return [ 'munged', $slice, $subslices, $collapsed_length ];
}

sub getVariationsOnSlice {
    my( $self, $slice, $subslices, $gene, $so_terms, $no_munge) = @_;
    my $sliceObj = $self->new_object('Slice', $slice, $self->__data);
    my ($count_snps, $filtered_snps, $context_count) = $sliceObj->getFakeMungedVariationFeatures($subslices,$gene,$no_munge);
    $self->__data->{'sample'}{"snp_counts"} = [$count_snps, scalar @$filtered_snps];
    $self->__data->{'SNPS'} = $filtered_snps;
    return ($count_snps, $filtered_snps, $context_count);
}

## EG - remove status from gene type
sub gene_type {
  my $self = shift;
  my $db = $self->get_db;
  my $type = '';
  if( $db eq 'core' ){
    #$type = ucfirst(lc($self->Obj->status))." ".$self->Obj->biotype;
    $type = ucfirst($self->Obj->biotype);
    $type =~ s/_/ /;
    $type ||= $self->db_type;
  } elsif ($db =~ /vega/) {
    #my $biotype = ($self->Obj->biotype eq 'tec') ? uc($self->Obj->biotype) : ucfirst(lc($self->Obj->biotype));
    #$type = ucfirst(lc($self->Obj->status))." $biotype";
    my $type = ($self->Obj->biotype eq 'tec') ? uc($self->Obj->biotype) : ucfirst(lc($self->Obj->biotype));
    $type =~ s/_/ /g;
    $type =~ s/unknown //i;
    return $type;
  } else {
    $type = $self->logic_name;
    if ($type =~/^(proj|assembly_patch)/ ){
      #$type = ucfirst(lc($self->Obj->status))." ".$self->Obj->biotype;
      $type = ucfirst($self->Obj->biotype);
    }
    $type =~ s/_/ /g;
    $type =~ s/^ccds/CCDS/;
  }
  $type ||= $db;
  if( $type !~ /[A-Z]/ ){ $type = ucfirst($type) } #All lc, so format
  return $type;
}


1;
