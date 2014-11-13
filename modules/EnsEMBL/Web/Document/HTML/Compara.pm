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

sub matrix {
    my ($self) = @_;

    my $hub  = $self->hub;
    my $methods = ['SYNTENY', 'TRANSLATED_BLAT_NET','BLASTZ_NET', 'LASTZ_NET'];
    my $data = $self->get_matrix_data($methods, 1);

    foreach my $sp (keys %$data) {
	$data->{$sp}->{'name'} = $sp;
	$data->{$sp}->{'common_name'}    = $hub->species_defs->get_config($sp, 'SPECIES_COMMON_NAME') || $hub->species_defs->get_config(ucfirst($sp), 'SPECIES_COMMON_NAME') || ucfirst($sp);
	(my $short_name = ucfirst($sp)) =~ s/([A-Z])[a-z]+_([a-z]{3})([a-z]+)?/$1.$2/; ## e.g. H.sap
	$data->{$sp}->{'short_name'}     = $short_name;
    }

#    warn Dumper $data;
    my $html .= qq{<table class="spreadsheet" style="width:100%;padding-bottom:2em">\n\n};

    my ($i, $j, @to_do) = (0, 0);

    foreach my $species (sort keys %$data) {
	my $ybg = $i % 2 ? 'bg1' : 'bg3';
	$html .= sprintf qq{<tr>\n<th class="$ybg" style="padding:2px"><b><i><a href="%s">%s</a></i></b></th>\n},
	,$data->{$species}->{'name'}, $data->{$species}->{'common_name'};
	foreach my $other_species (@to_do) {
	    my $cbg;
	    if ($i % 2) {
		$cbg = $j % 2 ? 'bg1' : 'bg3';
	    }
	    else {
		$cbg = $j % 2 ? 'bg3' : 'bg4';
	    }

	    my $content = '';
	    foreach my $method (sort keys %{$data->{$species}->{align}->{$other_species} || {}}) {
		my $label = substr($method, 0, 1);
		my ($mlss_id , $stats) = @{$data->{$species}->{align}->{$other_species}->{$method} || []};

		if ($stats) {
		    $content .= "<a href='/mlss.html?mlss=$mlss_id'>$label</a> "; 
		} else {
		    $content .= "$label ";
		}
	    }

	    $html .= sprintf '<td class="center %s" style="padding:2px;vertical-align:middle">%s</td>', $cbg, $content;
	    $j++;
	}
	$j = 0;

	my $xbg = $i % 2 ? 'bg1' : 'bg4';

	$html .= sprintf '<th class="center %s" style="padding:2px">%s</th>', $xbg, $data->{$species}->{'short_name'};
	$html .= '</tr>';
	$i++;
	push @to_do, $species;
    }
    $html .= "</table>\n";
    return $html;
}

sub get_matrix_data {
  my ($self, $methods, $debug) = @_;

  my $compara_db = $self->hub->database('compara');
  return unless $compara_db;

  my $mlss_adaptor    = $compara_db->get_adaptor('MethodLinkSpeciesSet');
  my $genome_adaptor  = $compara_db->get_adaptor('GenomeDB');
 
  my $data = {};
  my $species = {};
# existence of this tag defines if stats are available
  my $stats_tag = 'num_blocks';
  
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
	    my $ref_name = $ref_genome_db->name;
	    my @non_ref_genome_dbs = grep {$_->dbID != $ref_genome_db->dbID} @gdbs;


        ## Build data matrix

	    if (scalar(@non_ref_genome_dbs)) {
          # Alignment between 2+ species
		foreach my $nonref_db (@non_ref_genome_dbs) {
		    $data->{$ref_name}->{align}->{$nonref_db->name}->{$method} = [$mlss->dbID,  $mlss->has_tag($stats_tag) ? 1 : 0];
		    $data->{$nonref_db->name}->{align}->{$ref_name}->{$method} = [$mlss->dbID,  $mlss->has_tag($stats_tag) ? 1 : 0];
		}
	    } else {
            # Self-alignment. No need to increment $species->{$ref_name} as it has been done earlier
		$data->{$ref_name}->{align}->{$ref_name}->{$method} = [ $mlss->dbID, $mlss->has_tag($stats_tag) ? 1 : 0];
	    }
	} else {
	    warn "Can't get ref genome db for ", $mlss->name;
	}
    }
  }

  return $data;
}

1;
