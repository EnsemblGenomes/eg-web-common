=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Query::GlyphSet::Transcript;

use strict;
use warnings;

sub _colour_key {
  my ($self,$args,$gene,$transcript) = @_;

  $transcript ||= $gene;
  my $pattern = $args->{'pattern'} || '[biotype]';
  
  # hate having to put ths hack here, needed because any logic_name
  # specific web_data entries get lost when the track is merged - needs
  # rewrite of imageconfig merging code

## EG  
  if ($transcript->analysis) {
    my $logic_name = $transcript->analysis->logic_name;

    if ($transcript->biotype eq 'protein_coding') {
      return 'merged_iwgsc_taestivum' if $logic_name eq 'iwgsc';
      return 'merged_pgsb_taestivum'  if $logic_name eq 'pgsb_3b_taestivum' or $logic_name eq 'pgsb_taestivum ';
    }

    return 'merged' if $logic_name =~ /ensembl_havana/;
  }
##
  
  # EG: the colour can be altered via an attribute assigned to the gene
  # e.g a PHIbase_mutant attribute is assigned to a gene with value 'virulence'
  # then the web_data should have label set to [attrib.PHIbase_mutant][biotype] 
  # and all the possible attribute values(colours) should be added to conf/ini-files/COLOURS.ini
  if ($pattern =~ /\[attrib\.(\w+)\]/) {
    if (my ($attr) = @{ $gene->get_all_Attributes($1) }) {
      return $attr->value;
    }    
    $pattern =~ s/\[attrib\.(\w+)\]//;
  }  

  $pattern =~ s/\[gene.(\w+)\]/$1 eq 'logic_name' ? $gene->analysis->$1 : $gene->$1/eg;
  $pattern =~ s/\[(\w+)\]/$1 eq 'logic_name' ? $transcript->analysis->$1 : $transcript->$1/eg;

  return lc $pattern;
}

1;