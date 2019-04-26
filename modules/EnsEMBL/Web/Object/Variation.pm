=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

    foreach my $label ('primer_type', 'snp_type', 'total_contigs', 'link_to_primer') {
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
                              "<li><b>TOTAL CONTIGS:</b> ".$attribs->{'total_contigs'}."</li>".
                              "<li><b>LINK TO PRIMER</b> : $marker_link</li></ul>";
  }

  return $self->{'primer_entry'};
}

1;
