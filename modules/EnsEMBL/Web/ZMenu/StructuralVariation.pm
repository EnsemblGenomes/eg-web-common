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

package EnsEMBL::Web::ZMenu::StructuralVariation;

use strict;


sub feature_content {
  my ($self, $feature) = @_;
  my $hub         = $self->hub;
  my $variation   = $feature->structural_variation;
  my $sv_id       = $feature->variation_name;
  my $seq_region  = $feature->seq_region_name;
  my $start       = $feature->seq_region_start;
  my $end         = $feature->seq_region_end;
  my $class       = $variation->var_class;
  my $vstatus     = $variation->get_all_validation_states;
  my $study       = $variation->study;
  my $ssvs        = $variation->get_all_SupportingStructuralVariants;
  my $description = $variation->source_description;
  my $position    = $start;
  my $length      = $end - $start;
  my $max_length  = ($hub->species_defs->ENSEMBL_GENOME_SIZE || 1) * 1e6; 
  my ($med_link, $location_link, $study_name, $study_url, $ext_ref, $is_breakpoint, @allele_types);  
  
  $self->new_feature;

  if (defined $study) {
    $study_name  = $study->name;
    $description = $study->description;
    $study_url   = $study->url; 
    $ext_ref     = $study->external_reference;
  }
  
  if ($end < $start) {
    $position = "between $end & $start";
  } elsif ($end > $start) {
    $position = "$start-$end";
  }
  
	if (defined $feature->breakpoint_order && $feature->is_somatic == 1) {
	  $is_breakpoint = 1;
	} elsif ($length > $max_length) {
    $location_link = $hub->url({
      type     => 'Location',
      action   => 'Overview',
      r        => "$start-$end",
      cytoview => sprintf('%s=normal', $variation->is_somatic ? 'somatic_sv_feature' : 'variation_feature_structural'),
    });
  } else {
    $location_link = $hub->url({
      type   => 'Location',
      action => 'View',
      r      => "$seq_region:$start-$end",
    });
  }
  
  if ($ext_ref =~ /PMID/) {
    my @ref = split(/:/, $ext_ref);
    $med_link        = $hub->get_ExtURL('EUROPE_PMC', pop @ref); 
  }    

  foreach my $ssv (@$ssvs) {
    my $a_type = $ssv->var_class;
    push @allele_types, $a_type unless grep $a_type eq $_, @allele_types;
  }
  
  @allele_types = sort @allele_types;
  
  $self->caption($class eq 'CNV_PROBE' ? 'CNV probe: ' : 'Structural variation: ' . $sv_id);
  
  $self->add_entry({
    label_html => "$sv_id properties",
    link       => $hub->url({
      type     => 'StructuralVariation',
      action   => 'Summary',
      sv       => $sv_id,
    })
  });
  
  if ($is_breakpoint) {
    $self->add_entry({
      type       => 'Location',
      label_html => $self->get_locations($sv_id),
    });
	} else {
    $self->add_entry({
      type  => 'Location',
      label => sprintf('%s: %s', $self->neat_sr_name($feature->slice->coord_system->name, $seq_region), $position),
      link  => $location_link,
    });
	}
  
  $self->add_entry({
    type  => 'Source',
    label => $variation->source()->name(),
  });
  
  if (defined $study_name) {
    $self->add_entry({
      type  => 'Study',
      label => $study_name,
      link  => $study_url, 
    });
  }
  
  $self->add_entry({
    type  => 'Description',
    label => $description,
    link  => $med_link, 
  });
  
  $self->add_entry({
    type  => 'Class',
    label => $class,
  });
  
  if (scalar @allele_types) {
    $self->add_entry({
      type  => 'Allele type' . (scalar @allele_types > 1 ? 's' : ''),
      label => join(', ', @allele_types),
    });
  }
  
  if (scalar @$vstatus && $vstatus->[0]) {
    $self->add_entry({
      type  => 'Validation',
      label => join(',', @$vstatus),
    });    
  }
}


1;
