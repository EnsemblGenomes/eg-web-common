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

# $Id: Export.pm,v 1.1 2011-12-12 16:37:49 it2 Exp $

package EnsEMBL::Web::Object::Export;

sub features {
  my $self          = shift;
  my $format        = shift;
  my $slice         = $self->slice;
  my $params        = $self->params;
  my @common_fields = qw(seqname source feature start end score strand frame);
  my @extra_fields  = $format eq 'gtf' ? qw(gene_id transcript_id) : qw(hid hstart hend genscan gene_id transcript_id exon_id gene_type variation_name probe_name);  
  my $availability  = $self->availability;
  
  $self->{'config'} = {
    extra_fields  => \@extra_fields,
    format        => $format,
    delim         => $format eq 'csv' ? ',' : "\t"
  };
  
  if($format ne 'bed'){$self->string(join $self->{'config'}->{'delim'}, @common_fields, @extra_fields) unless $format eq 'gff';}
  
  if ($params->{'similarity'}) {
    foreach (@{$slice->get_all_SimilarityFeatures}) {
      $self->feature('similarity', $_, { 
        hid    => $_->hseqname, 
        hstart => $_->hstart, 
        hend   => $_->hend 
      });
    }
  }
  
  if ($params->{'repeat'}) {
    foreach (@{$slice->get_all_RepeatFeatures}) {
      $self->feature('repeat', $_, { 
        hid    => $_->repeat_consensus->name, 
        hstart => $_->hstart, 
        hend   => $_->hend 
      });
    }
  }
  
  if ($params->{'genscan'}) {
    foreach my $t (@{$slice->get_all_PredictionTranscripts}) {
      foreach my $e (@{$t->get_all_Exons}) {
        $self->feature('pred.trans.', $e, { genscan => $t->stable_id });
      }
    }
  }
  
  if ($params->{'variation'}) {
    foreach (@{$slice->get_all_VariationFeatures}) {
      $self->feature('variation', $_, { variation_name => $_->variation_name });	    
    }
  }

  if($params->{'probe'} && $availability->{'database:funcgen'}) {
    my $fg_db = $self->database('funcgen'); 
## EG
    my $probe_feature_adaptor = $fg_db ? $fg_db->get_ProbeFeatureAdaptor : undef;      
    my @probe_features = $probe_feature_adaptor ? @{$probe_feature_adaptor->fetch_all_by_Slice($slice)} : ();
##    
    foreach my $pf(@probe_features){
      my $probe_details = $pf->probe->get_all_complete_names();
      my @probes = split(/:/,@$probe_details[0]);
      $self->feature('ProbeFeature', $pf, { probe_name => @probes[1] },{ source => @probes[0]});
    }
  }
  
if ($params->{'gene'}) {
    my $dbs = $self->dbs;
    foreach my $db (@{$dbs}) {
      foreach my $g (@{$slice->get_all_Genes(undef, $db)}) {
        my $source = $self->gene_source($g,$db);
        foreach my $t (@{$g->get_all_Transcripts}) {
          foreach my $e (@{$t->get_all_Exons}) {
            $self->feature('gene', $e, { 
               exon_id       => $e->stable_id, 
               transcript_id => $t->stable_id, 
               gene_id       => $g->stable_id, 
               gene_type     => $g->status . '_' . $g->biotype
            }, { source => $source });
          }
        }
      }
    }
  }
 
  $self->misc_sets(keys %{$params->{'misc_set'}}) if $params->{'misc_set'};
}

1;
