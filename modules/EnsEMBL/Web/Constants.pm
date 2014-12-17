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

package EnsEMBL::Web::Constants;

use strict;
use warnings;
no warnings 'uninitialized';

sub ONTOLOGY_SETTINGS {
  return {
    'FYPO' => {
      biomart_filter => 'fypo_parent_term',
      name => 'Phenotype Ontology',
    },
    'MOD' => {
      biomart_filter => 'mod_parent_term',
      name => 'Protein Modification Ontology',
    },
    'GO' => {
      extlinks => {
	'View in QuickGO' => 'http://www.ebi.ac.uk/ego/GTerm?id=###ID###',
      },
      biomart_filter => 'go_parent_term',
      name => 'Gene Ontology',
      url => 'http://www.geneontology.org',
    },      
    'PO' => {
      extlinks => {
	'View in Plant Ontology' => 'http://www.plantontology.org/amigo/go.cgi?view=details&&query=###ID###',
      },
      biomart_filter => 'po_parent_term',
      name => 'Plant Ontology',
      url =>  'http://www.plantontology.org',
    },
    'TO' => {
      extlinks => {
        'View in Trait Ontology' => 'http://gramene.org/db/ontology/search_term?id=###ID###'
      } 
    },
    'GRO' => {
      extlinks => {
        'View in Growth Stage Ontology' => 'http://gramene.org/db/ontology/search_term?id=###ID###'
      } 
    },
    'GR_tax' => {
      extlinks => {
        'View in Taxonomy Ontology' => 'http://gramene.org/db/ontology/search_term?id=###ID###'
      } 
    },
    'EO' => {
      extlinks => {
        'View in Environment Ontology' => 'http://gramene.org/db/ontology/search_term?id=###ID###'
      } 
    }
  };
}


1;
