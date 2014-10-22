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

package EnsEMBL::Web::Component::Tools::Blast::Alignment;

use strict;

use Bio::Seq;

## EG - WU-BLAST can return hits where query seq is on reverse strand
##      not supported by Ensembl so modified here for EG 
sub query_sequence {
  my ($self, $job, $hit, $blast_method, $species) = @_;
  my $query_sequence = $self->object->get_input_sequence_for_job($job)->{'sequence'};
## EG 
  my $ori            = $hit->{qori}; # strand
  my $start          = $ori == 1 ? $hit->{'qstart'} : $hit->{'qend'};
  my $end            = $ori == 1 ? $hit->{'qend'} : $hit->{'qstart'};
##   
  my $length         = $end - $start + 1;
  my $full_length;

  if ($blast_method =~ /blastx/i) {
    my $codon_table_id = 1;
    my $frame          = $hit->{'qframe'};
       $length         = $length / 3;

    if ($frame =~ /\-/) {
      my $strand        = $hit->{'gori'};
      my $slice_adaptor = $self->hub->get_adaptor('get_SliceAdaptor', 'core', $species);
      my $temp_seq;

      $frame = 0;

      foreach (@{$hit->{'g_coords'}}) {
        my $slice       = $slice_adaptor->fetch_by_toplevel_location(sprintf '%s:%s-%s:%s', $hit->{'gid'}, $start, $end, $hit->{'gori'});
           $temp_seq   .= $slice->seq;
           $full_length = 1;
      }

      $query_sequence = $temp_seq;
    }

    $frame = $frame > 0 ? $frame -= 1 : $frame;

    my $peptide = Bio::Seq->new(
      -seq      => $query_sequence,
      -moltype  => 'dna',
      -alphabet => 'dna',
      -id       => 'sequence'
    );

    $query_sequence = $peptide->translate(undef, undef, $frame, $codon_table_id)->seq;
    $query_sequence =~ s/\*$//;
    $start          = ($hit->{'qstart'} / 3) + 1;
    $start          = length($query_sequence) - $start if $hit->{'qori'} =~ /\-/;
  }
## EG
  my $sub_sequence = $full_length ? $query_sequence : substr($query_sequence, $start - 1, $length);

  if ($ori != 1) {
    # need to return reverse complimentatry sequence
    my $map = {
      A => 'T',
      T => 'A',
      G => 'C',
      C => 'G'
    };
    $sub_sequence = join '', map { $map->{$_} } reverse split '', $sub_sequence;
  }

  return $sub_sequence;
## EG  
}

1;
