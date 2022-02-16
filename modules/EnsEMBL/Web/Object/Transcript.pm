=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::Transcript;

# no need to count ontology terms - it is done in configuration module
sub count_go {
    return 1;
}


sub count_similarity_matches {
  my $self = shift;
  my $type = $self->get_db;
  my $dbc = $self->database($type)->dbc;
  my %all_xrefs;

  my $olist ='';

  if (my @ontologies = @{$self->species_defs->DISPLAY_ONTOLOGIES || []}) {
      $olist = '^('.(join '|', @ontologies).')$';
  }

  # xrefs on the transcript
  my $sql1 = qq{
    SELECT x.display_label, edb.db_name, edb.type, edb.status
      FROM transcript t, object_xref ox, xref x, external_db edb
     WHERE t.transcript_id = ox.ensembl_id
       AND ox.xref_id = x.xref_id
       AND x.external_db_id = edb.external_db_id
       AND ox.ensembl_object_type = 'Transcript'
       AND t.transcript_id = ?};

  my $sth = $dbc->prepare($sql1);
  $sth->execute($self->Obj->dbID);
  
  while (my ($label, $db_name, $type, $status) = $sth->fetchrow_array) {
    my $key = $db_name.$label;
    $all_xrefs{'transcript'}{$key} = { 'id' => $label, 'db_name' => $db_name, 'type' => $type, 'status' => $status };
  }

  # xrefs on the translation
  my $sql2 = qq{
    SELECT x.display_label, edb.db_name, edb.type, edb.status
      FROM translation tl, object_xref ox, xref x, external_db edb
     WHERE tl.translation_id = ox.ensembl_id
       AND ox.xref_id = x.xref_id
       AND x.external_db_id = edb.external_db_id
       AND ox.ensembl_object_type = 'Translation'
       AND tl.transcript_id = ?};

  $sth = $dbc->prepare($sql2);
  $sth->execute($self->Obj->dbID);
  
  while (my ($label, $db_name, $type, $status) = $sth->fetchrow_array) {
    my $key = $db_name.$label;
    $all_xrefs{'translation'}{$key} = { 'id' => $label, 'db_name' => $db_name, 'type' => $type, 'status' => $status };
  }

  # filter out what isn't shown on the 'External References' page
  my @counted_xrefs;
  foreach my $t (qw(transcript translation)) {
    my $xrefs = $all_xrefs{$t};
    while (my ($key,$det) = each %$xrefs) { 
      next unless (grep {$det->{'type'} eq $_} qw(MISC PRIMARY_DB_SYNONYM)); 
      # these filters are taken directly from Component::_sort_similarity_links
      # code duplication needs removing, and some of these may well not be needed any more
      next if $det->{'status'} eq 'ORTH';                        # remove all orthologs
      next if lc $det->{'db_name'} eq 'medline';                 # ditch medline entries - redundant as we also have pubmed
      next if $det->{'db_name'} =~ /^flybase/i && $det->{'id'} =~ /^CG/;  # Ditch celera genes from FlyBase
      next if $det->{'db_name'} eq 'Vega_gene';                  # remove internal links to self and transcripts
      next if $det->{'db_name'} eq 'Vega_transcript';
      next if $det->{'db_name'} eq 'Vega_translation';
#      next if $det->{'db_name'} eq 'GO';
      next if $det->{'db_name'} eq 'goslim_goa';
      next if $det->{'db_name'} eq 'OTTP' && $det->{'display_label'} =~ /^\d+$/; #ignore xrefs to vega translation_ids

      next if ($olist && ($det->{'db_name'} =~ $olist));

      push @counted_xrefs, $key;
    }
  }

  return scalar @counted_xrefs;
}

sub getAllelesConsequencesOnSlice {
  my ($self, $sample, $key, $sample_slice) = @_;
 
  # If data already calculated, return
  my $allele_info  = $self->__data->{'sample'}{$sample}->{'allele_info'};  
  my $consequences = $self->__data->{'sample'}{$sample}->{'consequences'};    
  return ($allele_info, $consequences) if $allele_info && $consequences;
  
  # Else
  my $valids = $self->valids;  

  # Get all features on slice
## EG
# We don't have read coverage data for EG or VB so do not set the coverage flag 
# More info in JIRA ticket VB-1924
  #my $allele_features = $sample_slice->get_all_AlleleFeatures_Slice(1) || []; 
  my $allele_features = $sample_slice->get_all_AlleleFeatures_Slice(0) || []; 
##  
  return ([], []) unless @$allele_features;

  my @filtered_af =
    sort { $a->[2]->start <=> $b->[2]->start }
    grep { $valids->{'opt_class_' . lc($self->var_class($_->[2]))} }                           # [ fake_s, fake_e, AF ] Filter our unwanted classes
    grep { scalar map { $valids->{'opt_' . lc $_} ? 1 : () } @{$_->[2]->get_all_sources} } # [ fake_s, fake_e, AF ] Filter our unwanted sources
    map  { $_->[1] ? [ $_->[0]->start + $_->[1], $_->[0]->end + $_->[1], $_->[0] ] : () }  # [ fake_s, fake_e, AlleleFeature ] Filter out AFs not on munged slice
    map  {[ $_, $self->munge_gaps($key, $_->start, $_->end) ]}                             # [ AF, offset ] Map to fake coords. Create a munged version AF
    @$allele_features;
  
  return ([], []) unless @filtered_af;

  # consequences of AlleleFeatures on the transcript
  my @slice_alleles = map { $_->[2]->transfer($self->Obj->slice) } @filtered_af;

  push @$consequences, $_->get_all_TranscriptVariations([$self->Obj])->[0] foreach @slice_alleles;
  return ([], []) unless @$consequences;
  
  # this is a hack, there's an issue with weakening to avoid circular
  # references in VariationFeature that causes the reference to the VF to be
  # garbage collected, so we make a copy here such that we can still get to it
  # later
  $_->{_cache_variation_feature} = $_->variation_feature foreach @$consequences;

  my @valid_conseq;
  my @valid_alleles;

  #foreach (sort {$a->start <=> $b->start} @$consequences) { # conseq on our transcript
  foreach (@$consequences) { # conseq on our transcript
    #my $last_af =  $valid_alleles[-1];
    #my $allele_feature;
    #
    #if ($last_af && $last_af->[2]->start eq $_->start) {
    #  $allele_feature = $last_af;
    #} else {
    #  $allele_feature = shift @filtered_af;
    #}
    
  my $allele_feature = shift @filtered_af;
    #next unless $allele_feature;
  
    foreach my $type (@{$_->consequence_type || []}) {
      next unless $valids->{'opt_' . lc $type};
      warn "Allele undefined for ", $allele_feature->[2]->variation_name . "\n" unless $allele_feature->[2]->allele_string;
    
      # [ fake_s, fake_e, SNP ]   Filter our unwanted consequences
      push @valid_conseq,  $_;
      push @valid_alleles, $allele_feature;
      last;
    }
  }
  
  $self->__data->{'sample'}{$sample}->{'consequences'} = \@valid_conseq  || [];
  $self->__data->{'sample'}{$sample}->{'allele_info'}  = \@valid_alleles || [];
  
  return (\@valid_alleles, \@valid_conseq);
}

1;
