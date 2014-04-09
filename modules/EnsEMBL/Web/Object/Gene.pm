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
use strict;
use previous qw(counts availability);

sub availability {
  my $self = shift;
  $self->PREV::availability(@_);
 
  my $obj = $self->Obj;
    
  if ($obj->isa('Bio::EnsEMBL::Gene')) {
    my $member     = $self->database('compara') ? $self->database('compara')->get_GeneMemberAdaptor->fetch_by_source_stable_id('ENSEMBLGENE', $obj->stable_id) : undef;
    my $pan_member = $self->database('compara_pan_ensembl') ? $self->database('compara_pan_ensembl')->get_GeneMemberAdaptor->fetch_by_source_stable_id('ENSEMBLGENE', $obj->stable_id) : undef;
    my $counts     = $self->counts($member, $pan_member);
    
    $self->{_availability}->{has_homoeologs} = $counts->{homoeologs};
    
    $self->{_availability}->{has_gene_supporting_evidence} = $counts->{gene_supporting_evidence};
  }

  return $self->{_availability};
}

sub _counts {
  my ($self, $member, $pan_member) = @_;
  my $obj = $self->Obj;

  return {} unless $obj->isa('Bio::EnsEMBL::Gene');
  
  my $counts = $self->{'_counts'};
 
  if (!$counts) {    
    if ($member) {
      $counts->{'homoeologs'} = $member->number_of_homoeologues;
    }
    $counts->{'gene_supporting_evidence'} = $self->count_gene_supporting_evidence;
  }
    
  return $counts || {};
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

## EG - add homoeolog descriptions
sub get_homology_matches {
  my ($self, $homology_source, $homology_description, $disallowed_homology, $compara_db) = @_;
  #warn ">>> MATCHING $homology_source, $homology_description BUT NOT $disallowed_homology";
  
  $homology_source      ||= 'ENSEMBL_HOMOLOGUES';
  $homology_description ||= 'ortholog';
  $compara_db           ||= 'compara';
  
  my $key = "$homology_source::$homology_description";
  
  if (!$self->{'homology_matches'}{$key}) {
    my $homologues = $self->fetch_homology_species_hash($homology_source, $homology_description, $compara_db);
    
    return $self->{'homology_matches'}{$key} = {} unless keys %$homologues;
    
    my $gene         = $self->Obj;
    my $geneid       = $gene->stable_id;
    my $adaptor_call = $self->param('gene_adaptor') || 'get_GeneAdaptor';
    my %homology_list;

    # Convert descriptions into more readable form
    my %desc_mapping = (
      ortholog_one2one          => '1-to-1',
      apparent_ortholog_one2one => '1-to-1 (apparent)', 
      ortholog_one2many         => '1-to-many',
      possible_ortholog         => 'possible ortholog',
      ortholog_many2many        => 'many-to-many',
      within_species_paralog    => 'paralogue (within species)',
      other_paralog             => 'other paralogue (within species)',
      putative_gene_split       => 'putative gene split',
      contiguous_gene_split     => 'contiguous gene split',
## EG      
      gene_split                => 'gene split',
      homoeolog_one2one         => '1-to-1',
      homoeolog_one2many        => '1-to-many',
      homoeolog_many2many       => 'many-to-many',
##
    );
    
    foreach my $display_spp (keys %$homologues) {
      my $order = 0;
      
      foreach my $homology (@{$homologues->{$display_spp}}) { 
        my ($homologue, $homology_desc, $homology_subtype, $query_perc_id, $target_perc_id, $dnds_ratio, $gene_tree_node_id) = @$homology;
        
        next unless $homology_desc =~ /$homology_description/;
        next if $disallowed_homology && $homology_desc =~ /$disallowed_homology/;
        
        # Avoid displaying duplicated (within-species and other paralogs) entries in the homology table (e!59). Skip the other_paralog (or overwrite it)
        next if $homology_list{$display_spp}{$homologue->stable_id} && $homology_desc eq 'other_paralog';
        
        $homology_list{$display_spp}{$homologue->stable_id} = { 
          homology_desc       => $desc_mapping{$homology_desc} || 'no description',
          description         => $homologue->description       || 'No description',
          display_id          => $homologue->display_label     || 'Novel Ensembl prediction',
          homology_subtype    => $homology_subtype,
          spp                 => $display_spp,
          query_perc_id       => $query_perc_id,
          target_perc_id      => $target_perc_id,
          homology_dnds_ratio => $dnds_ratio,
          gene_tree_node_id   => $gene_tree_node_id,
          order               => $order,
          location            => sprintf('%s:%s-%s:%s', map $homologue->$_, qw(chr_name chr_start chr_end chr_strand))
        };
        
        $order++;
      }
    }
    
    $self->{'homology_matches'}{$key} = \%homology_list;
  }
  
  return $self->{'homology_matches'}{$key};
}

1;
