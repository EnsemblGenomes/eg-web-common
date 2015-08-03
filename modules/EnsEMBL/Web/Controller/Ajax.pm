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

package EnsEMBL::Web::Controller::Ajax;

use strict;
use Data::Dumper;

sub ajax_species_autocomplete {
  my ($self, $hub) = @_;
  my $species_defs  = $hub->species_defs;
  my $term          = $hub->param('term'); # will return everything if no term specified
  my $result_format = $hub->param('result_format') || 'simple'; # simple/chosen
  
  my @species = $species_defs->valid_species;
  
  # sub to normalise strings for comparison e.g. k-12 == k12
  my $normalise = sub { 
    my $str = shift;
    $str =~ s/[^a-zA-Z0-9 ]//g;
    return $str;
  };
  
  $term = $normalise->($term);
  my @terms = split /\s+/, $term;

  my $paralogues = $species_defs->multi_hash->{'DATABASE_COMPARA'}->{'ENSEMBL_PARALOGUES'};

  # find matches
  my @matches;
  foreach my $sp (@species) {
    my $name    = $species_defs->get_config($sp, "SPECIES_COMMON_NAME");
    my $taxid   = $species_defs->get_config($sp, "TAXONOMY_ID");
    my $search  = $normalise->("$name $taxid");
    
    my $hits = 0;
    for (@terms) {
      $hits ++ if $search =~ /\Q$_\E/i;
    }
    next unless $hits >= @terms;

    my $compara     = exists $paralogues->{$sp};    
    my $begins_with = $search =~ /^\Q$term\E/i;
    
    my $score = 0;
    $score   += 2 if $compara;
    $score   += 1 if $begins_with;

    push(@matches, {
      value           => "$name, (TaxID $taxid)",
      production_name => $sp,
      score           => $score,
    });
  }

  # alphanumeric sort with score boost
  my $sort = sub {
    my ($a, $b) = @_;
    return $a->{value} cmp $b->{value} if $a->{score} == $b->{score};
    return $b->{score} <=> $a->{score};
  };

  @matches = sort {$sort->($a, $b)} @matches;
  
  my $data;
  
  if ($result_format eq 'chosen') {
    # return results in format compatible with chosen.ajaxaddition.jquery.js
    $data = {
      q => $hub->param('term'), # original term
      results => \@matches
    };
  } else {
    # default to simple array format
    $data = [@matches];
  }

  print $self->jsonify($data);
}


sub ajax_check_stable_id {
    my ( $self, $hub ) = @_;
    my $gene_id = $hub->param('stable_id');
    my @dbs = map lc( substr $_, 9 ),
        @{ $hub->species_defs->core_like_databases || [] };
    my $results = {};

    foreach my $db (@dbs) {

        my $gene_adaptor = $hub->get_adaptor( 'get_GeneAdaptor', $db );
        if ( my $gene = $gene_adaptor->fetch_by_stable_id($gene_id) ) {
            $gene = $gene->transform('toplevel');

            # print Dumper($gene);
            $results = {
                uc $gene_id => {
                    'label' => $gene_id,
                    'r' => $gene->seq_region_name() . ':'
                        . $gene->start() . "-"
                        . $gene->end(),
                    'db' => $db,
                    'g'  => $gene_id

                }
            };
            last;
        } 
    }
    print $self->jsonify($results);
}





1;
