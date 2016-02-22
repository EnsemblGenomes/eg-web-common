=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Draw::GlyphSet::vcf;

### Module for drawing data in VCF format (either user-attached, or
### internally configured via an ini file or database record

use strict;

use Bio::EnsEMBL::Variation::DBSQL::VariationFeatureAdaptor;
use Bio::EnsEMBL::Variation::Utils::Constants;

sub features {
  my $self = shift;

  if (!$self->{'_cache'}{'features'}) {
    my $ppbp        = $self->scalex;
    my $slice       = $self->{'container'};
    my $start       = $slice->start;
    my @features;

    my $vcf_adaptor = $self->vcf_adaptor;
    ## Don't assume the adaptor can find and open the file!
    
## EG support seq region synonyms    
    my $consensus = eval { $vcf_adaptor->fetch_variations($slice->seq_region_name, $slice->start, $slice->end); };

    if ( ref $consensus eq 'ARRAY' && !@$consensus ){
      my $synonym_obj = $slice->get_all_synonyms(); # arrayref of Bio::EnsEMBL::SeqRegionSynonym objects

      foreach my $synonym (@$synonym_obj) {
        $consensus =  eval { $self->vcf_adaptor->fetch_variations($synonym->name, $slice->start, $slice->end) };
        last if (ref $consensus eq 'ARRAY' && @$consensus > 0);
      }
    }
##
    return @features unless (ref $consensus eq 'ARRAY' && @$consensus);

    my $fnum        = scalar @$consensus;
    my $calc_type   = $fnum > 200 ? 0 : 1;
    my $config      = $self->{'config'};
    my $species     = $slice->adaptor->db->species;

    # Can we actually draw this many features?
    unless ($calc_type) {
      return 'too_many';
    } 

    # If we have a variation db attached we can try and find a known SNP mapped at the same position
    # But at the moment we do not display this info so we might as well just use the faster method 
    #     my $vfa = $slice->_get_VariationFeatureAdaptor()->{list}->[0];
    
    my $vfa = Bio::EnsEMBL::Variation::DBSQL::VariationFeatureAdaptor->new_fake($species);
    
    foreach my $a (@$consensus) {
      my $unknown_type = 1;
      my $vs           = $a->{'POS'} - $start + 1;
      my $ve           = $vs;
      my $info;
         $info .= ";  $_: $a->{'INFO'}{$_}" for sort keys %{$a->{'INFO'} || {}};

      if (my $sv = $a->{'INFO'}{'SVTYPE'}) {
        $unknown_type = 0;
        
        if ($sv eq 'DEL') {
          my $svlen = $a->{'INFO'}{'SVLEN'} || 0;
             $ve    = $vs + abs $svlen;
             
          $a->{'REF'} = substr($a->{'REF'}, 0, 30) . ' ...' if length $a->{'REF'} > 30;
        } elsif ($sv eq 'TDUP') {
          my $svlen = $a->{'INFO'}{'SVLEN'} || 0;
             $ve    = $vs + $svlen + 1;
        } elsif ($sv eq 'INS') {
          $ve = $vs -1;
        }
      } else {
        my ($reflen, $altlen) = (length $a->{'REF'}, length $a->{'ALT'}[0]);
        
        if ($reflen > 1) {
          $ve = $vs + $reflen - 1;
        } elsif ($altlen > 1) {
          $ve = $vs - 1;
        }
      }
      
      my $allele_string = join '/', $a->{'REF'}, @{$a->{'ALT'} || []};
      my $vf_name       = $a->{'ID'} eq '.' ? "$a->{'CHROM'}_$a->{'POS'}_$allele_string" : $a->{'ID'};

      if ($slice->strand == -1) {
        my $flip = $slice->length + 1;
        ($vs, $ve) = ($flip - $ve, $flip - $vs);
      }
      
      my $snp = {
        start            => $vs, 
        end              => $ve, 
        strand           => 1, 
        slice            => $slice,
        allele_string    => $allele_string,
        variation_name   => $vf_name,
        map_weight       => 1, 
        adaptor          => $vfa, 
        seqname          => $info ? "; INFO: --------------------------$info" : '',
        consequence_type => $unknown_type ? ['INTERGENIC'] : ['COMPLEX_INDEL']
      };

      bless $snp, 'Bio::EnsEMBL::Variation::VariationFeature';
      
      # if user has defined consequence in VE field of VCF
      # no need to look up via DB
      if(defined($a->{'INFO'}->{'VE'})) {
        my $con = (split /\|/, $a->{'INFO'}->{'VE'})[0];
        
        if(defined($Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES{$con})) {
          $snp->{consequence_type} = [$con];
          $snp->{overlap_consequences} = [$Bio::EnsEMBL::Variation::Utils::Constants::OVERLAP_CONSEQUENCES{$con}];
          $calc_type = 0;
        }
      }
      
      # otherwise look up via DB
      $snp->get_all_TranscriptVariations if $calc_type && $unknown_type;
      
      push @features, $snp;
      
      $self->{'legend'}{'variation_legend'}{$snp->display_consequence} ||= $self->get_colour($snp);
    }

    $self->{'_cache'}{'features'} = \@features;
  }
  
  return $self->{'_cache'}{'features'};
}

1;
