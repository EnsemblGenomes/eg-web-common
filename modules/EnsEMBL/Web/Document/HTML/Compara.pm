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

package EnsEMBL::Web::Document::HTML::Compara;

## Provides content for compara documeentation - see /info/genome/compara/analyses.html
## Base class - does not itself output content

use strict;

use Math::Round;
use EnsEMBL::Web::Document::Table;
use Bio::EnsEMBL::Compara::Utils::SpeciesTree;
use Data::Dumper;

use base qw(EnsEMBL::Web::Document::HTML);


sub mlss_data {
  my ($self, $methods) = @_;

  my $compara_db = $self->hub->database('compara');
  return unless $compara_db;

  my $mlss_adaptor    = $compara_db->get_adaptor('MethodLinkSpeciesSet');
  my $genome_adaptor  = $compara_db->get_adaptor('GenomeDB');
 
  my $data = {};
  my $species = {};

  ## Munge all the necessary information
  foreach my $method (@{$methods||[]}) {
    my $mls_sets  = $mlss_adaptor->fetch_all_by_method_link_type($method);

    foreach my $mlss (@$mls_sets) {
	my $ref_species = $mlss->get_value_for_tag("reference_species");

	my @gdbs = @{$mlss->species_set_obj->genome_dbs ||[]};

	my $ref_genome_db;

	if ($ref_species) {
	    if (my @found = grep { $_->name eq $ref_species } @gdbs) {
		$ref_genome_db = $found[0];
	    }
	} else {
	    $ref_genome_db = $gdbs[0];
	}

	if ($ref_genome_db) {
        ## Add to full list of species
	    my $ref_name = ucfirst($ref_genome_db->name);
	    $species->{$ref_name}++;

        ## Build data matrix
	    my @non_ref_genome_dbs = grep {$_->dbID != $ref_genome_db->dbID} @{$mlss->species_set_obj->genome_dbs};
	    if (scalar(@non_ref_genome_dbs)) {
          # Alignment between 2+ species
		foreach my $nonref_db (@non_ref_genome_dbs) {
		    $species->{ucfirst($nonref_db->name)}++;
		    $data->{$ref_name}{ucfirst($nonref_db->name)} = [$method, $mlss->dbID, $mlss->has_tag('ref_mis_matches')];
		}
	    } else {
            # Self-alignment. No need to increment $species->{$ref_name} as it has been done earlier
		$data->{$ref_name}{$ref_name} = [$method, $mlss->dbID, $mlss->has_tag('ref_mis_matches')];
	    }
	} else {
	    warn "Can't get ref genome db for ", $mlss->name;
	}
    }
  }
  my @species_list = sort keys %$species;

  return (\@species_list, $data);
}

1;
