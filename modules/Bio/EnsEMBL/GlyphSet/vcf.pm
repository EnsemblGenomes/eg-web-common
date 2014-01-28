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

package Bio::EnsEMBL::GlyphSet::vcf;
use strict;

#use base qw(Bio::EnsEMBL::GlyphSet_simple);

use base qw(Bio::EnsEMBL::GlyphSet::_variation);
use Bio::EnsEMBL::ExternalData::VCF::VCFAdaptor;
use Bio::EnsEMBL::Variation::OverlapConsequence;

use Data::Dumper;
use HTML::Entities qw(encode_entities);

# calculation of the consequence type is very time consuming 
# so we do it only when there are less then 150 snps to display
my $MAX_SNPS_TO_CALC = 150;

sub reset {
  my ($self) = @_;
  $self->{'glyphs'} = [];
  foreach (qw(x y width minx miny maxx maxy bumped)) {
      delete $self->{$_};
  }
}

# get a bam adaptor
sub vcf_adaptor {
  my $self = shift;
  
  my $url = $self->my_config('url');
  if ($url =~ /\#\#\#CHR\#\#\#/) {
      my $region = $self->{'container'}->seq_region_name;
      $url =~ s/\#\#\#CHR\#\#\#/$region/g;
  }
  $self->{_cache}->{_vcf_adaptor} ||= Bio::EnsEMBL::ExternalData::VCF::VCFAdaptor->new($url);
  
  return $self->{_cache}->{_vcf_adaptor};
}

sub features {
  my $self = shift;
  my $t1 = time;

  unless ($self->{_cache}->{features}) {
      my $ppbp = $self->scalex;
      my $slice = $self->{'container'};
      my $START = $self->{'container'}->start;
      my $consensus = $self->vcf_adaptor->fetch_variations($slice->seq_region_name, $slice->start, $slice->end);

      if ( ref $consensus eq 'ARRAY' && !@$consensus ){
        my $synonym_obj = $slice->get_all_synonyms(); # arrayref of Bio::EnsEMBL::SeqRegionSynonym objects
        my $features;

        foreach my $synonym (@$synonym_obj) {
          $features =  $self->vcf_adaptor->fetch_variations($synonym->name, $slice->start, $slice->end);
          last if (ref $features eq 'ARRAY' && @$features > 0);
        }
        $consensus = $features;
      }

      my $fnum =  scalar(@{$consensus || []}) || return [];
      my $calc_type = $fnum > $MAX_SNPS_TO_CALC ? 0 : 1;
#      warn "COUNT : $fnum \n";

      my @features;
      my $config  = $self->{'config'};
      my $species = $slice->adaptor->db->species;

# VEP seems to only work on the whole chromosome coordinates - so we get the slice for the chromosome
      my $sa = $slice->adaptor;
      my $slice1 = $sa->fetch_by_region('toplevel', $slice->seq_region_name) || $sa->fetch_by_region(undef, $slice->seq_region_name);
      return [] unless $slice1;

      my $vfa = Bio::EnsEMBL::Variation::DBSQL::VariationFeatureAdaptor->new_fake($species);
      my $complex_indel  = Bio::EnsEMBL::Variation::OverlapConsequence->new_fast({
	  'feature_SO_term' => 'primary_transcript',
	  'description' => 'Insertion or deletion that spans an exon/intron or coding sequence/UTR border',
	  'SO_accession' => 'SO:0001577',
	  'SO_term' => 'complex_change_in_transcript',
	  'predicate' => 'Bio::EnsEMBL::Variation::Utils::VariationEffect::complex_indel',
	  'label' => 'Complex in/del',
	  'rank' => '5',
	  'display_term' => 'COMPLEX_INDEL',
	  'feature_class' => 'Bio::EnsEMBL::Transcript'
	  }
										 );
      my $not_predicted =  Bio::EnsEMBL::Variation::OverlapConsequence->new_fast({
	  'SO_term' => 'intergenic_variant',
	  'is_default' => 1,
	  'label' => 'Intergenic',
	  'description' => 'More than 5 kb either upstream or downstream of a transcript',
	  'rank' => '100',
	  'SO_accession' => 'SO:0001628',
	  'display_term' => 'INTERGENIC'
	  });
      
      foreach my $a (@$consensus) {
# in case of structural variants we set the consequence type ourselves
# otherwise the VEP will calculate it
	  my $oc;
	  my $vs = $a->{POS}- $START+1;
	  my $ve = $vs;

	  my $info ='';
	  foreach my $i (sort keys %{$a->{INFO}||{}}) {
	      $info .= ";  $i: $a->{INFO}->{$i}";
	  }

	  if (my $sv = $a->{INFO}->{SVTYPE}) {
	      $oc = $complex_indel;
	      if ($sv eq 'DEL') {
		  my $svlen = $a->{INFO}->{SVLEN} || 0;
		  $ve = $vs + abs($svlen);
		  if (length($a->{REF}) > 30) {
		      $a->{REF} = substr($a->{REF}, 0, 30)." ...";
		  }
	      } elsif ($sv eq 'TDUP') {
		  my $svlen = $a->{INFO}->{SVLEN} || 0;
		  $ve = $vs + $svlen + 1;
	      } elsif ($sv eq 'INS') {
		  $ve = $vs -1;
	      }
	  } else {
	      my ($reflen, $altlen) = (length($a->{REF}), length($a->{ALT}->[0]));
	      if ($reflen > 1) {
		  $ve = $vs + $reflen -1;
	      } elsif ($altlen > 1) {
		  $ve = $vs - 1;
	      }
	      
	      # if we dont want to calculate the consequences then we just assign the NOT_PREDICTED
	      $oc = $not_predicted unless ($calc_type);
	  }

	  my $allele_string = join '/', $a->{REF},  @{$a->{ALT}||[]};
	  my $vf_name = $a->{ID} eq '.' ? $a->{CHROM}.'_'.$a->{POS}.'_'.$allele_string : $a->{ID};

          my $gstart = $a->{POS};
          my $gend = $gstart + 1;
	  my $seq_id = $slice->seq_region_name();
          my $genotype_info =  defined $a->{'gtypes'} ?
                               (keys %{$a->{'gtypes'}} ? "<a href='/Export/VCFView/Location?pos=$seq_id:$gstart-$gend;&vcf=".$self->vcf_adaptor->{'_url'}."' class='modal_link'>Genotype Info</a>" : "")  
                               : "";

	  my $new_vf_name = $genotype_info ne "" ? $vf_name."; ".$genotype_info : $vf_name;
	  
	  my $vf = Bio::EnsEMBL::Variation::VariationFeature->new(
								  -start          => $a->{POS}, 
								  -end            => $a->{POS},
								  -slice          => $slice1,
								  -allele_string  => $allele_string,
								  -strand         => 1,
								  -map_weight     => 1,
								  -adaptor        => $vfa,
								  -variation_name => $new_vf_name,
								  );

	  if ($oc) {
	      $vf->add_OverlapConsequence($oc);
# to avoid looking for all transcript variations etc when calling display_consequence.. 
	      $vf->{_most_severe_consequence} = $oc;
	  }

	  if ($calc_type) {
	      my $type    = lc $vf->display_consequence;
	      if (!$config->{'variation_types'}{$type}) {
		  my $colours = $self->my_config('colours');
		  push @{$config->{'variation_legend_features'}->{'variations'}->{'legend'}}, $colours->{$type}->{'text'}, $colours->{$type}->{'default'};
		  $config->{'variation_types'}{$type} = 1;
	      }
	  }

	  #Hack:: B:E:V:VariationFeature needs chromosome based coordinates to calculate effect
	  #but the drawing code needs the slice based coordinates 

	  $vf->{'start'} = $vs;
	  $vf->{'end'} = $ve;
	  $vf->{'slice'} = $slice;
	  $vf->{'seqname'} = $info ? "; INFO: --------------------------$info" : '';
	  push @features, $vf;
      }
   
    $self->{_cache}->{features} = \@features;
  }
  return $self->{_cache}->{features};
}



sub title {
  my ($self, $f) = @_;
  my $slice = $self->{'container'};
  my $seq_id = $slice->seq_region_name();
  my $START = $slice->start;

  my $vs = $f->start + $START-1;
  my $ve = $f->end + $START-1;
  
  my $x = ($vs == $ve) ? $vs : "$vs-$ve";
  my $t = $f->display_consequence;
  my $title = $f->variation_name .
      "; Location: $seq_id:$x; Type: $t; Allele: ". encode_entities($f->allele_string). $f->id;

  return $title;
}

sub href {
  return undef;
}

sub render_histogram {
    my $self = shift;

    my $h           = 20;
    my $colour      = $self->my_config('col')  || 'gray50';
    my $line_colour = $self->my_config('line') || 'red';
    my $slice = $self->{'container'};
    my $scalex = $self->scalex;

    my $density = $self->features_density();
    my $maxvalue = (sort {$b <=> $a} values %$density)[0];    
    return $self->render_normal if ($maxvalue == 1);

    my $maxvalue = (sort {$b <=> $a} values %$density)[0];

    return $self->render_normal if ($maxvalue == 1);

    foreach my $pos (sort {$a <=> $b} keys %$density) {
	my $v = $density->{$pos};
	my $h1 = int(($v / $maxvalue) * $h);
	$self->push($self->Line({
	    x         => $pos,
	    y         => $h - $h1,
	    width     => 0,
	    height    => $h1,
	    colour    => $colour,
	    absolutey => 1,
	    absolutex => 1
	})); 
    }
      
    my( $fontname_i, $fontsize_i ) = $self->get_font_details( 'innertext' );
    my @res_i = $self->get_text_width(0, $maxvalue, '', 'font'=>$fontname_i, 'ptsize' => $fontsize_i );
    my $textheight_i = $res_i[3];

   $self->push( $self->Text({
	'text'          => $maxvalue,
	'width'         => $res_i[2],
	'textwidth'     => $res_i[2],
	'font'          => $fontname_i,
	'ptsize'        => $fontsize_i,
	'halign'        => 'right',
	'valign'        => 'top',
	'colour'        => $line_colour,
	'height'        => $textheight_i,
	'y'             => 0,
	'x'             => -4 - $res_i[2],
	'absolutey'     => 1,
	'absolutex'     => 1,
	'absolutewidth' => 1,
    }));

    $maxvalue = ' 0';
    @res_i = $self->get_text_width(0, $maxvalue, '', 'font'=>$fontname_i, 'ptsize' => $fontsize_i );
    $textheight_i = $res_i[3];
    
   $self->push( $self->Text({
	'text'          => $maxvalue,
	'width'         => $res_i[2],
	'textwidth'     => $res_i[2],
	'font'          => $fontname_i,
	'ptsize'        => $fontsize_i,
	'halign'        => 'right',
	'valign'        => 'bottom',
	'colour'        => $line_colour,
	'height'        => $textheight_i,
	'y'             => $textheight_i + 4,
	'x'             => -4 - $res_i[2],
	'absolutey'     => 1,
	'absolutex'     => 1,
	'absolutewidth' => 1,
    }));
}

sub features_density {
    my $self = shift;
    my $slice = $self->{'container'};
    my $START = $self->{'container'}->start - 1;
    my $snps = $self->features() || return {};

    my $density = {};
    my $scalex = $self->scalex;

# check if we display proper B:E:Variation ( those are already mapped to the slice and have method 'start')
    if ($snps->[0] && $snps->[0]->can('start')) {
	foreach my $snp (@{$snps||[]}) {
	    my $vs = int($snp->start * $scalex);
	    $density->{$vs}++;
	}
    } else {
	foreach my $snp (@{$snps||[]}) {
	    my $vs = int(($snp->{START} - $START) * $scalex);
	    $density->{$vs}++;
	}
    }
    return $density;
}

1;
