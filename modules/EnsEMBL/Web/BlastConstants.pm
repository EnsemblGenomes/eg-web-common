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
    'general'             => {

      'caption'             => '',

      'fields'              => [

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
      }
      ]

    },

    'scoring'             => {

       'caption'             => '',

      'fields'              => [

      'dropoff'             => {
        'type'                => 'dropdown',
        'label'               => 'Dropoff',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(0 2 4 6 8 10) ]
      },

      'matrix'              => {
        'type'                => 'dropdown',
        'label'               => 'Scoring matrix to use',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(BLOSUM45 BLOSUM50 BLOSUM62 BLOSUM80 BLOSUM90 PAM30 PAM70 PAM250) ]
      },

      'match_scores'        => {
        'type'                => 'dropdown',
        'label'               => 'Match/mismatch scores',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(2,-7 1,-3 2,-5 1,-2 2,-3 1,-1 5,-4 4,-5) ]
      },

      'gapopen'             => {
        'type'                => 'dropdown',
        'label'               => 'Penalty for opening a gap',
        'values'              => [ map { 'value' => $_, 'caption' => ($_ == -1 ? 'default' : $_) }, (-1, (0..21), 25) ]
      },

      'gapext'              => {
        'type'                => 'dropdown',
        'label'               =>  'Penalty for extending a gap',
        'values'              => [ map { 'value' => $_, 'caption' => ($_ == -1 ? 'default' : $_) }, (-1, (1..6), 8, 10) ]
      },

      'gapalign'            => {
        'type'                => 'checklist',
        'label'               => 'Perform alignment using gaps',
        'values'              => [ { 'value' => '1' } ],
      },

      'compstats'           => {
        'type'                => 'dropdown',
        'label'               => 'Compositional adjustments',
        'values'              => [ map { 'value' => $_, 'caption' => $_ }, qw(F D 1 2 3) ]                                
      }
      ]

    },

    'filters_and_masking'  => {

      'caption'             => '',
      'fields'              => [

      'filter'              => {
        'type'                => 'checklist',
        'label'               => 'Filter low complexity regions',
        'values'              => [ { 'value' => '1' } ],
        'commandline_values'  => {'1' => 'T', '' => 'F'}
      }
    ]
    }

  ];
}

sub CONFIGURATION_DEFAULTS {
  return {

    'all'                     => {
      'alignments'              => '50',
      'scores'                  => '50',
      'exp'                     => '1e-1',     
      'filter'                  => '1',
    },

    'NCBIBLAST_BLASTN'        => {
      'dropoff'                 => '0',
      'match_scores'            => '2,-3',
      'gapopen'                 => '5',
      'gapext'                  => '2',
      'gapalign'                => '1',      
    },

    'NCBIBLAST_BLASTP'        => {
      'dropoff'                 => '0',
      'matrix'                  => 'BLOSUM62',
      'gapopen'                 => '11',
      'gapext'                  => '1',
      'gapalign'                => '1',      
    },

    'NCBIBLAST_BLASTX'        => {
      'dropoff'                 => '0',      
      'matrix'                  => 'BLOSUM62', 
      'gapopen'                 => '11',
      'gapext'                  => '1',
      'gapalign'                => '1',            
    },

    'NCBIBLAST_TBLASTX'       => {
      'matrix'                  => 'BLOSUM62',
    },

    'NCBIBLAST_TBLASTN'       => {
      'dropoff'                 => '0',      
      'matrix'                  => 'BLOSUM62', 
      'gapopen'                 => '11',
      'gapext'                  => '1',
      'gapalign'                => '1',   
      'compstats'               => 'F',
    },

  };
}

sub CONFIGURATION_SETS {

  my $sets = {
    'dna'         => {
      'near'        => {
        'exp'           => 10,
        'match_scores'  => '1,-3',
        'gapopen'       => 5,
        'gapextend'     => 2
      },
      'near_oligo'  => {
        'exp'           => 1000,
        'match_scores'  => '1,-3',
        'gapopen'       => 5,
        'gapextend'     => 2
      },
      'normal'      => {
        'exp'           => 10,
        'match_scores'  => '1,-3',
        'gapopen'       => 5,
        'gapextend'     => 2
      },
      'distant'     => {
        'exp'           => 10,
        'match_scores'  => '1,-1',
        'gapopen'       => 2,
        'gapextend'     => 1
      },
    },
    'protein'     => {
      'near'        => {
        'matrix'      => 'BLOSUM90',
        'gapopen'     => 10,
        'gapext'      => 1        
      },
      'normal'      => {
        'matrix'      => 'BLOSUM62',
        'gapopen'     => 11,
        'gapext'      => 1
      },
      'distant'     => {
        'matrix'      => 'BLOSUM45',
        'gapopen'     => 14,
        'gapext'      => 2
      },
    }
  };

  return [
    { 'value' => 'near',        'caption' => 'Near match'},
    { 'value' => 'near_oligo',  'caption' => 'Short sequences'},
    { 'value' => 'normal',      'caption' => 'Normal', 'selected' => 'true'},
    { 'value' => 'distant',     'caption' => 'Distant homologies'}
  ], {
    'NCBIBLAST_BLASTN'        => $sets->{'dna'},
    'NCBIBLAST_BLASTP'        => $sets->{'protein'},
    'NCBIBLAST_BLASTX'        => $sets->{'protein'},
    'NCBIBLAST_TBLASTN'       => $sets->{'protein'},
    'NCBIBLAST_TBLASTX'       => $sets->{'protein'},
  };
}

1;
