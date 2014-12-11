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

package EnsEMBL::Web::Component::Variation::Summary;

sub content {
  my $self               = shift;
  my $hub                = $self->hub;
  my $object             = $self->object;
  my $variation          = $object->Obj;
  my $vf                 = $hub->param('vf');
  my $variation_features = $variation->get_all_VariationFeatures;
  my ($feature_slice)    = map { $_->dbID == $vf ? $_->feature_Slice : () } @$variation_features; # get slice for variation feature

  my $info_box;
  if ($variation->failed_description || (scalar keys %{$object->variation_feature_mapping} > 1)) { 
    ## warn if variation has been failed
    $info_box = $self->multiple_locations($feature_slice, $variation->failed_description); 
  }

  my $summary_table      = $self->new_twocol(
    $self->variation_source,
    $self->alleles($feature_slice),
    $self->location,
    $feature_slice ? $self->co_located($feature_slice) : (),
    #$self->validation_status,
    $self->evidence_status,
    $self->clinical_significance,
    $self->synonyms,
    $self->inter_homoeologues,
    $self->hgvs,
    $self->sets
  );

  return sprintf qq{<div class="summary_panel">$info_box%s</div>}, $summary_table->render;
}

## EG ENSEMBL-3426 link to inter-homoeologues - will need to update for E79
sub inter_homoeologues {
  my $self           = shift;
  my $hub            = $self->hub;
  my $attribs        = $self->object->Obj->get_all_attributes();
  my $attrib_adaptor = $hub->get_adaptor('get_AttributeAdaptor', 'variation');
  my @rows;

  foreach my $code (keys %$attribs) {
    my $name    = $attribs->{$code};
    my $caption = ucfirst( $attrib_adaptor->attrib_type_name_for_attrib_type_code($code) );
    my $url     = $hub->url({ v => $name, vf => undef });
    push @rows, [$caption, sprintf('<a href="%s">%s</a> %s', $url, $name)];
  } 

  return @rows ;
}
##

1;
