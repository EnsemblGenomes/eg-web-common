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

package EnsEMBL::Web::BlastConstants;

use strict;
use warnings;
no warnings 'qw';

sub CONFIGURATION_FIELDS {
  return [
    'general'             => [

      'alignments'          => {
        'type'                => 'dropdown',
        'label'               => 'Maximum number of alignments displayed',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(5 10 20 50 100 150 200 250 500 750 1000) ]
      },

      'scores'              => {
        'type'                => 'dropdown',
        'label'               => 'Maximum number of scores displayed',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(5 10 20 50 100 150 200 250 500 750 1000) ]
      },

      'exp'                 => {
        'type'                => 'dropdown',
        'label'               => 'E-value threshold',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(1e-200 1e-100 1e-50 1e-10 1e-5 1e-4 1e-3 1e-2 1e-1 1.0 10 100 1000 10000) ]
      },
    ],

    'scoring'             => [

      # NCBI
      # 'matrix'              => {
      #   'type'                => 'dropdown',
      #   'label'               => 'Scoring matrix to use',
      #   'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(BLOSUM45 BLOSUM50 BLOSUM62 BLOSUM80 BLOSUM90 PAM30 PAM70 PAM250) ]
      # },

      # # WUBLAST
      # 'matrix'              => {
      #   'type'                => 'dropdown',
      #   'label'               => 'Scoring matrix to use',
      #   'values'              => [ 
      #     map { 'value' => lc($_), 'caption' => $_ }, 
      #     qw(internal identity PuPy BLOSUM62 BLOSUM30 BLOSUM35 BLOSUM40 BLOSUM45 BLOSUM50 BLOSUM65 BLOSUM70 BLOSUM75 BLOSUM80 BLOSUM85 BLOSUM90 BLOSUM100 Gonnet),
      #     map {'PAM' . ($_ * 10)} 1..50  
      #   ]
      # },

      # NCBI only
      # 'dropoff'             => {
      #   'type'                => 'dropdown',
      #   'label'               => 'Dropoff',
      #   'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(0 2 4 6 8 10) ]
      # },

      # 'match_scores'        => {
      #   'type'                => 'dropdown',
      #   'label'               => 'Match/mismatch scores',
      #   'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(2,-7 1,-3 2,-5 1,-2 2,-3 1,-1 5,-4 4,-5) ]
      # },

      # 'gapopen'             => {
      #   'type'                => 'dropdown',
      #   'label'               => 'Penalty for opening a gap',
      #   'values'              => [ map { 'value' => $_, 'caption' => ($_ == -1 ? 'default' : $_) }, (-1, (0..21), 25) ]
      # },

      # 'gapext'              => {
      #   'type'                => 'dropdown',
      #   'label'               =>  'Penalty for extending a gap',
      #   'values'              => [ map { 'value' => $_, 'caption' => ($_ == -1 ? 'default' : $_) }, (-1, (1..6), 8, 10) ]
      # },

      # 'gapalign'            => {
      #   'type'                => 'checklist',
      #   'label'               => 'Perform alignment using gaps',
      #   'values'              => [ { 'value' => '1' } ],
      # },

      # 'compstats'           => {
      #   'type'                => 'dropdown',
      #   'label'               => 'Compositional adjustments',
      #   'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(F D 1 2 3) ]                                
      # },
      # /NCBI only


      # WU-BLAST only
      'strand'              => {
        'type'                => 'dropdown',
        'label'               => 'Nucleotide strand',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(none both top bottom) ]
      },
      'stats'               => {
        'type'                => 'dropdown',
        'label'               => 'Statistical model',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(sump poisson kap) ]                                
      },

      'sensitivity'         => {
        'type'                => 'dropdown',
        'label'               => 'Search sensitivity',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(vlow low medium normal high) ]                                
      },

      'topcombon'           => {
        'type'                => 'dropdown',
        'label'               => 'Consistent sets of HSPs to be reported',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(1 2 3 4 5 50 100 1000 all) ]                                
      },
      # /WU-BLAST only
    ],

    'filters_and_masking'  => [

      # NCBI
      # 'filter'              => {
      #   'type'                => 'checklist',
      #   'label'               => 'Filter low complexity regions',
      #   'values'              => [ { 'value' => '1' } ],
      #   'commandline_values'  => {'1' => 'T', '' => 'F'}
      # },

      # WUBLAST
      'filter'              => {
        'type'                => 'dropdown',
        'label'               => 'Filter low complexity regions',
        'values'              => [ { 'value' => '1' } ],
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(none seg xnu seg+xnu dust) ]      
      },

      # # WU-BLAST only
      # 'viewfilter'          => {
      #   'type'                => 'checklist',
      #   'label'               => 'View filtered sequence',
      #   'values'              => [ { 'value' => '1' } ],
      #   'commandline_values'  => {'1' => 'true', '' => 'false'}
      # },
      # # /WU-BLAST only

    ]
  ];
}

sub CONFIGURATION_DEFAULTS {
  return {

    'all'                     => {
      'alignments'              => '50',
      'scores'                  => '50',
      'exp'                     => '10',     
      'filter'                  => '1',
    },


    # 'NCBIBLAST_BLASTN'        => {
    #   'dropoff'                 => '0',
    #   'match_scores'            => '1,-3',
    #   'gapopen'                 => '-1',
    #   'gapext'                  => '-1',
    #   'gapalign'                => '1',      
    # },

    # 'NCBIBLAST_TBLASTX'       => {
    #   'matrix'                  => 'BLOSUM62',
    #   'dropoff'                 => '0',
    #   'gapopen'                 => '-1',
    #   'gapext'                  => '-1',
    #   'gapalign'                => '1',
    # },

    # 'NCBIBLAST_TBLASTN'       => {
    #   'matrix'                  => 'BLOSUM62',
    #   'dropoff'                 => '0',
    #   'gapopen'                 => '-1',
    #   'gapext'                  => '-1',      
    #   'compstats'               => 'F',
    #   'gapalign'                => '1',
    # },


    'WUBLAST_BLASTN'          => {
      #'matrix'                  => 'blosum62',
      'stats'                   => 'sump',
      'sensitivity'             => 'normal',
      'topcombon'               => '1',
      'viewfilter'              => '1',
      'strand'                  => 'both',
    },

    'WUBLAST_TBLASTX'         => {
      #'matrix'                  => 'blosum62',
      'stats'                   => 'sump',
      'sensitivity'             => 'normal',
      'topcombon'               => '1',
      #'viewfilter'              => '1',
      'strand'                  => 'both',
    },

    'WUBLAST_TBLASTN'         => {
      #'matrix'                  => 'internal',
      'stats'                   => 'sump',
      'sensitivity'             => 'normal',
      'topcombon'               => '1',
      #'viewfilter'              => '1',
      'strand'                  => 'both',
    },
  };
}

sub CONFIGURATION_SETS {
  # not currently used for EG
}

1;
