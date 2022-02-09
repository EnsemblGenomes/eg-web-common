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

package EnsEMBL::Web::Object::Variation;

sub count_ldpops {
  my $self = shift;
    
  # find VCF config
  my $sd = $self->species_defs;
  my $c = $sd->ENSEMBL_VCF_COLLECTIONS;
  my $vdb = $self->Obj->adaptor->db->get_db_adaptor('variation');
  return undef unless ( $c && $vdb->can('use_vcf') );

  my $pa  = $self->database('variation')->get_PopulationAdaptor;
  my $count = scalar @{$pa->fetch_all_LD_Populations};
  return undef unless $count > 0;
  return $count;
}


## extract the primer/marker information linked to the variant
sub get_primer_data {
  my $self = shift;

  my $attribs = $self->Obj->get_all_attributes();

   if ($attribs->{'primer_type'}) {

    foreach my $label ('primer_type', 'snp_type', 'total_contigs', 'link_to_primer', 'ems_genotype', 'mutant_quality', 'residual_heterogeneity') {
      $attribs->{$label} =~ s/,$//;
    }

    # Build the link to the marker page
    my $marker = $attribs->{'link_to_primer'};
    my $url = $self->hub->url({
        type   => 'Marker',
        action => 'Details',
        m      => $marker
    });
    my $marker_link = qq{<a href="$url">$marker</a>};

    $self->{'primer_entry'} = "<ul><li><b>PRIMER TYPE:</b> ".$attribs->{'primer_type'}."</li>".
                              "<li><b>SNP TYPE:</b> ".$attribs->{'snp_type'}."</li>".
                              "<li><b>EMS GENOTYPE:</b> ".$attribs->{'ems_genotype'}."</li>".
                              "<li><b>TOTAL CONTIGS:</b> ".$attribs->{'total_contigs'}."</li>".
                              "<li><b>MUTANT QUALITY:</b> ".$attribs->{'mutant_quality'}."</li>".
                              "<li><b>RESIDUAL HETEROGENEITY:</b> ".$attribs->{'residual_heterogeneity'}."</li>".
                              "<li><b>LINK TO PRIMER</b> : $marker_link</li></ul>";
  }

  ##Cases where there is no link to a marker, we display less fields
  elsif ($attribs->{'mutant_quality'}){

    foreach my $label ('ems_genotype', 'mutant_quality', 'residual_heterogeneity') {
      $attribs->{$label} =~ s/,$//;
    }

    $self->{'primer_entry'} = "<li><b>EMS GENOTYPE:</b> ".$attribs->{'ems_genotype'}."</li>".
                              "<li><b>MUTANT QUALITY:</b> ".$attribs->{'mutant_quality'}."</li>".
                              "<li><b>RESIDUAL HETEROGENEITY:</b> ".$attribs->{'residual_heterogeneity'}."</li></ul>";

  }

  return $self->{'primer_entry'};
}

## extract external information linked to the variant
sub get_external_links {
  my $self = shift;

  my $attribs = $self->Obj->get_all_attributes();

  ##Get necessary attribs for external links
  my $html_out;
  my $external_link = $attribs->{'cerealsdb_external_links'};
  my $qtl_link      = $attribs->{'cerealsdb_qtl'};

  ##Removing extra comma at the end of the link if it appears
  if ($external_link){
        $external_link =~ s/,$//g
  }

  ##Just external link to CerealsDB
  if ($external_link){
    $html_out = qq{<a href="$external_link">Additional details from CerealsDB</a>};
  }

  ##QTL link as well
  if ($qtl_link){
    $html_out = qq{<ul><li><a href="$external_link">Additional details from CerealsDB</a></li>
                       <li><a href="$qtl_link">QTL data from CerealsDB</a></li>};
  }

  $self->{'external_link'} = "$html_out</ul>";
  return $self->{'external_link'};
}

1;
