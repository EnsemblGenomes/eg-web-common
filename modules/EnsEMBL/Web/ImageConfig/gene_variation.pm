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

# $Id: gene_variation.pm,v 1.2 2013-05-15 14:44:07 jh15 Exp $

package EnsEMBL::Web::ImageConfig::gene_variation;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;
  
  $self->{'colours'}{$_} = $self->species_defs->colour($_) for qw(variation haplotype);


  $self->set_parameters({
    title            => 'Variation Image',
    show_labels      => 'yes',  # show track names on left-hand side
    label_width      => 100,    # width of labels on left-hand side
    opt_halfheight   => 0,      # glyphs are half-height [ probably removed when this becomes a track config ]
    opt_empty_tracks => 0,      # include empty tracks
  });
  
  $self->create_menus(qw(      
    sequence
    transcript
    variation
    somatic
    gsv_transcript
    other
    gsv_domain
  ));
  
  $self->get_node('variation')->set('caption', '');
  $self->get_node('somatic')->set('caption', '');
  $self->get_node('gsv_transcript')->set('caption', '');
  
  $self->load_tracks;

  $self->modify_configs(
    [ 'variation', 'somatic', 'gsv_transcript', 'other' ],
    { menu => 'no' }
  );
  

  my $func = $self->{'code'} ne $self->{'type'} ? "init_$self->{'code'}" : "init_configurator";
  $self->$func if $self->can($func);

}

sub init_configurator {
    my $self = shift;
    $self->add_tracks( 'sequence',
			[ 'contig',    'Contigs',             'contig', { display => 'off', strand => 'r', description => 'Track showing underlying assembly contigs' }],
			[ 'seq',       'Sequence',            'sequence',        { display => 'normal', strand => 'b', bump_width => 0, threshold => 0.2, colourset => 'seq',      description => 'Track showing sequence in both directions'  }],
			[ 'codon_seq', 'Translated sequence', 'codonseq',        { display => 'off', strand => 'b', bump_width => 0, threshold => 0.5, colourset => 'codonseq', description => 'Track showing 6-frame translation of sequence' }],
			[ 'codons',    'Start/stop codons',   'codons',          { display => 'off', strand => 'b', threshold => 50,  colourset => 'codons',   description => 'Track indicating locations of start and stop codons in region' }]);
}


sub init_gene {
  my $self = shift;
  my $hub  = $self->hub;
  my $region = $hub->param('r');
  my ($reg_name, $start, $end) = $region =~ /(.+?):(\d+)-(\d+)/;
  my $length = $end - $start + 1;
  $length ||= 0;
  my @tracks;

  push @tracks, [ 'contig', 'Contigs', 'contig', { display => 'off', strand => 'r', description => 'Track showing underlying assembly contigs' }];
 
  push @tracks, [ 'seq', 'Sequence', 'sequence', { display => 'normal', strand => 'b', bump_width => 0, threshold => 0.2, colourset => 'seq',      description => 'Track showing sequence in both directions' }] if $length < 201;  #Sequence only displayed for less than 0.2Kb
 
  push @tracks, [ 'codon_seq', 'Translated sequence', 'codonseq', { display => 'off', strand => 'b', bump_width => 0, threshold => 0.5, colourset => 'codonseq', description => 'Track showing 6-frame translation of sequence' }]   if $length < 501;  #Translated sequence only displayed for less than 0.5Kb
 
  push @tracks, [ 'codons',    'Start/stop codons',   'codons',   { display => 'off', strand => 'b', threshold => 50,  colourset => 'codons',   description => 'Track indicating locations of start and stop codons in region' }];

  $self->add_tracks( 'sequence', (@tracks));

  $self->add_tracks('variation',
  # [ 'snp_join',         '', 'snp_join',         { display => 'on',     strand => 'b', menu => 'no', tag => 0, colours => $self->{'colours'}{'variation'}, context => 0 }],
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'b', menu => 'no', tag => 1, colours => 'bisque', src => 'all'          }]
  );
  
  $self->add_tracks('other',
    [ 'scalebar', '', 'scalebar', { display => 'normal', strand => 'b', menu => 'no'               }],
    [ 'ruler',    '', 'ruler',    { display => 'normal', strand => 'b', menu => 'no', notext => 1  }],
    [ 'spacer',   '', 'spacer',   { display => 'normal', strand => 'b', menu => 'no', height => 5  }],
  );
    
  $self->get_node('gsv_domain')->remove;
  
  $self->modify_configs(
    [ 'variation_feature_variation' ],
    { display => 'normal', caption => 'Variations', strand => 'b' }
  );
  $self->modify_configs(
    [ 'somatic_mutation_COSMIC' ],
    { display => 'normal', caption => 'COSMIC', strand => 'b' }
  );
}


sub init_gene_top {
  my $self = shift;

  $self->add_tracks('variation',
#    [ 'snp_join',         '', 'snp_join',         { display => 'on',     strand => 'b', menu => 'no', tag => 0, colours => $self->{'colours'}{'variation'} }],

    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'b', menu => 'no', tag => 0, colours => 'bisque', src => 'all'          }]
  );
  
  $self->add_tracks('other',
    [ 'scalebar', '', 'scalebar', { display => 'normal', strand => 'f', menu => 'no'               }],
    [ 'ruler',    '', 'ruler',    { display => 'normal', strand => 'f', menu => 'no', notext => 1  }],
    [ 'spacer',   '', 'spacer',   { display => 'normal', strand => 'r', menu => 'no', height => 5  }],
    [ 'draggable', '', 'draggable', { 'display' => 'normal',  menu => 'no' } ]
  );
    
  $self->get_node('gsv_domain')->remove;
  
  $self->modify_configs(
    [ 'variation_feature_variation' ],
    { display => 'normal', caption => 'Variations', strand => 'f' }
  );
  
  $self->modify_configs(
    [ 'transcript' ],
    {  display => 'transcript_nolabel', show_labels => 'off' }
  );
}

sub init_transcripts_top {
  my $self = shift;
  
  $self->add_tracks('other',
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'f', menu => 'no', tag => 1, colours => 'bisque', src => 'all'                         }],
    [ 'snp_join',         '', 'snp_join',         { display => 'normal', strand => 'f', menu => 'no', tag => 1, colours => $self->{'colours'}{'variation'}, context => 50 }],
  );
  
  $self->get_node($_)->remove for qw(gsv_domain transcript);
}

sub init_transcript {
  my $self = shift;
  
  $self->add_tracks('other',
    [ 'gsv_variations', '', 'gsv_variations', { display => 'on',     strand => 'r', menu => 'no', colours => $self->{'colours'}{'variation'} }],
    [ 'spacer',         '', 'spacer',         { display => 'normal', strand => 'r', menu => 'no', height => 10,                              }],
  );
  
  $self->get_node('transcript')->remove;
  
  $self->modify_configs(
    [ 'gsv_variations' ],
    { display => 'box' }
  );
}

sub init_transcripts_bottom {
  my $self = shift;
  
  $self->add_tracks('other',
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'r', menu => 'no', tag => 1, colours => 'bisque', src => 'all'                         }],
    [ 'snp_join',         '', 'snp_join',         { display => 'normal', strand => 'r', menu => 'no', tag => 1, colours => $self->{'colours'}{'variation'}, context => 50 }],
    [ 'ruler',            '', 'ruler',            { display => 'normal', strand => 'r', menu => 'no', notext => 1, name => 'Ruler'                                        }],
    [ 'spacer',           '', 'spacer',           { display => 'normal', strand => 'r', menu => 'no', height => 50,                                                       }],
  );
  
  $self->get_node($_)->remove for qw(gsv_domain transcript);
}

sub init_snps {
  my $self= shift;
  
  $self->set_parameters({
    bgcolor   => 'background1',
    bgcolour1 => 'background3',
    bgcolour2 => 'background1'
  });
  
  $self->add_tracks('other',
    [ 'snp_fake',             '', 'snp_fake',             { display => 'on',  strand => 'f', colours => $self->{'colours'}{'variation'}, tag => 2                                    }],
    [ 'variation_legend',     '', 'variation_legend',     { display => 'on',  strand => 'r', menu => 'no', caption => 'Variation legend'                                             }],
    [ 'snp_fake_haplotype',   '', 'snp_fake_haplotype',   { display => 'off', strand => 'r', colours => $self->{'colours'}{'haplotype'}                                              }],
    [ 'tsv_haplotype_legend', '', 'tsv_haplotype_legend', { display => 'off', strand => 'r', colours => $self->{'colours'}{'haplotype'}, caption => 'Haplotype legend', src => 'all' }],
  );
  
  $self->get_node($_)->remove for qw(gsv_domain transcript);
}

1;
