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
    $self->study(),
    $self->location,
    $feature_slice ? $self->co_located($feature_slice) : (),
    #$self->validation_status,
    $self->evidence_status,
    $self->clinical_significance,
    $self->synonyms,
    $self->hgvs,
    $self->sets
  );

  return sprintf qq{<div class="summary_panel">$info_box%s</div>}, $summary_table->render;
}

sub study {
  my $self       = shift;
  my $object     = $self->object;
  my $study_name;

  my $va= $self->object->Obj->{adaptor};
  my $study_id = $va->get_study_ids_by_var_id($self->object->Obj->dbID);

  my $sa = $self->hub->get_adaptor('get_StudyAdaptor', 'variation');
  my $study = $sa->fetch_all_by_dbID_list($study_id);

  return unless $study;

  my @return = ();

  foreach (0.. @$study - 1) {
    my $study_link;
    my $ext_ref = $study->[$_]->{external_reference};
    $study_link = $self->hub->get_ExtURL_link("PMID: $ext_ref", 'EUROPE_PMC', $ext_ref) if $ext_ref =~ /^(\d+)$/;

    my $study_line        = sprintf '<a href="%s" class="constant">%s</a>', $study->[$_]->{ext_ref}, $study->[$_]->{name};
    push @return, $study_line.' | '.$study->[$_]->{description}.' ['.$study_link.']' if $study->[$_]->{description} && $study_link;
  }
  return @return ? ['Study', join ',<br><br>', @return] : ();
}

1;
