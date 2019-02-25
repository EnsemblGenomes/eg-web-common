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

package EnsEMBL::Web::ImageConfig;

use strict;
use previous qw(menus);

sub menus {
  my $self  = shift;
  my $menus = $self->PREV::menus(@_);
  my $add   = {
    dna_align_rna          => [ 'RNA alignments', 'mrna_prot' ],

    ms_domain              => 'Mass spectrometry peptides',
    
    # community annotation
    cap                    => [ 'Apollo gene models', 'gene_transcript' ],

    # used to organise fungi/protists external tracks
    chromatin_binding      => 'Chromatin binding',      
    pb_intron_branch_point => 'Intron Branch Point',    
    polya_sites            => 'Polyadenylation sites',  
    replication_profiling  => 'Replication Profiling',  
    regulatory_elements    => 'Regulatory Elements',    
    tss                    => 'Transcription Start Sites',
    transcriptome          => 'Transcriptome',          
    nucleosome             => 'Nucleosome Positioning', 
    polymerase             => 'Polymerase Usage',       
    dna_methylation        => 'DNA Methylation',        
    histone_mod            => 'Histone Modification', 
    
    # used to organise plants external tracks
    wheat_alignment        => 'Wheat SNPs and alignments',
    wheat_assembly         => [ 'Wheat Assemblies and SNPs',           'wheat_alignment' ],
    wheat_transcriptomics  => [ 'Wheat transcriptomics',               'wheat_alignment' ],
    wheat_ests             => [ 'Wheat UniGene and ESTs',              'wheat_alignment' ],
    rnaseq_cultivar        => [ 'RNASeq study of nine cultivars',      'mrna_prot' ],
    rnaseq_tissue          => [ 'RNASeq study of eight growth stages', 'mrna_prot' ],
    resequencing           => [ 'Resequencing', 'functional' ], 
  };

  # EG ENSEMBL-3655 change terminology for Barley community
  if ($self->hub->species =~ /Hordeum_vulgare/i ) {
    $add->{prediction} = [ 'Low-confidence genes', 'gene_transcript' ];
  }

  return { %$menus, %$add };
}

1;
