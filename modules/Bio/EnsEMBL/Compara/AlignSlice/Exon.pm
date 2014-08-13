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

package Bio::EnsEMBL::Compara::AlignSlice::Exon;

use strict;

=head2 _get_aligned_sequence_from_original_sequence_and_cigar_line

  Arg [1]    : string $original_sequence
  Arg [1]    : string $cigar_line
  Example    : $aligned_sequence = _get_aligned_sequence_from_original_sequence_and_cigar_line(
                   "CGTAACTGATGTTA", "3MD8M2D3M")
  Description: get gapped sequence from original one and cigar line
  Returntype : string $aligned_sequence
  Exceptions : thrown if cigar_line does not match sequence length
  Caller     : methodname

=cut

sub _get_aligned_sequence_from_original_sequence_and_cigar_line {
  my ($original_sequence, $cigar_line, $mode) = @_;
  my $aligned_sequence = "";
  $mode ||= "";

  return undef if (!$original_sequence or !$cigar_line);

  my $seq_pos = 0;

  my @cig = ( $cigar_line =~ /(\d*[GMDI])/g );
  for my $cigElem ( @cig ) {
    my $cigType = substr( $cigElem, -1, 1 );
    my $cigCount = substr( $cigElem, 0 ,-1 );
    $cigCount = 1 unless ($cigCount =~ /^\d+$/);

    if( $cigType eq "M" ) {
      $aligned_sequence .= substr($original_sequence, $seq_pos, $cigCount);
      $seq_pos += $cigCount;
    } elsif( $cigType eq "G" || $cigType eq "D") {
      $aligned_sequence .=  "-" x $cigCount;
    } elsif( $cigType eq "I") {
      $aligned_sequence .=  "-" x $cigCount if ($mode ne "ref");
      $seq_pos += $cigCount;
    }
  }

## EG - ENSEMBL-3348 temporary fix for Phytophthora_kernoviae (should be dropped for EG24+)
  
  warn "Cigar line ($seq_pos) does not match sequence lenght (".length($original_sequence).")" if ($seq_pos != length($original_sequence));
  #throw("Cigar line ($seq_pos) does not match sequence lenght (".length($original_sequence).")") if ($seq_pos != length($original_sequence));

##

  return $aligned_sequence;
}

1;
