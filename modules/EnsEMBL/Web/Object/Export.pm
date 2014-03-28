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

sub gff3_features {
  my $self         = shift;
  my $slice        = $self->slice;
  my $params       = $self->params;
  my $species_defs = $self->hub->species_defs;
  
  # Always use the forward strand, else CDS coordinates are incorrect (Bio::EnsEMBL::Exon->coding_region_start and _end return coords for forward strand only. Thanks, Core API team.)
  $slice = $slice->invert if $slice->strand < 0;
  
  $self->{'config'} = {
    format             => 'gff3',
    delim              => "\t",
    ordered_attributes => {},
    feature_order      => {},
    feature_type_count => 0,
    
    # TODO: feature types
    #    feature_map => {
    #      dna_align          => { func => 'get_all_DnaAlignFeatures',          type => 'nucleotide_match' },
    #      marker             => { func => 'get_all_MarkerFeatures',            type => 'region' },
    #      repeat             => { func => 'get_all_RepeatFeatures',            type => 'repeat_region' },
    #      assembly_exception => { func => 'get_all_AssemblyExceptionFeatures', type => '' },
    #      ditag              => { func => 'get_all_DitagFeatures',             type => '' },
    #      external           => { func => 'get_all_ExternalFeatures',          type => '' },
    #      oligo              => { func => 'get_all_OligoFeatures',             type => 'oligo' },
    #      qtl                => { func => 'get_all_QtlFeatures',               type => 'region' },
    #      simple             => { func => 'get_all_SimpleFeatures',            type => '' },
    #      protein_align      => { func => 'get_all_ProteinAlignFeatures',      type => 'protein_match' }
    #    }
  };

  my ($g_id, $t_id);
  my $dbs = $self->dbs;
  foreach my $db (@{$dbs}) {
    foreach my $g (@{$slice->get_all_Genes(undef, $db)}) {
      my $properties = { source => $self->gene_source($g,$db) };

      if ($params->{'gene'}) {
        $g_id = $g->stable_id;
## EG   
        my $g_name = $g->display_xref ? $g->display_xref->display_id : $g_id;       
        $self->feature('gene', $g, { ID => $g_id, Name => $g_name, biotype => $g->biotype }, $properties);
##
      }

      foreach my $t (@{$g->get_all_Transcripts}) {
        if ($params->{'transcript'}) {
          $t_id = $t->stable_id;
## EG         
          my $t_name = $t->display_xref ? $t->display_xref->display_id : $t_id;
          $self->feature('transcript', $t, { ID => $t_id, Parent => $g_id, Name => $t_name, biotype => $t->biotype }, $properties);
##
        }

        if ($params->{'intron'}) {
          for my $intron (@{$t->get_all_Introns}){
            next unless $intron->length;
            $self->feature('intron', $intron, { Parent => $t_id, Name => $self->id_counter('intron') }, $properties);
          }
        }

        if ($params->{'exon'} || $params->{'cds'}) {
          foreach my $e (@{$t->get_all_Exons}) {
            $self->feature('exon', $e, { Parent => $t_id, Name => $e->stable_id }, $properties) if $params->{'exon'};
 
            if ($params->{'cds'}) {
              my $start = $e->coding_region_start($t);
              next unless $start; # $start will be undef if the exon is not coding
              $self->feature('CDS', $e, { Parent => $t_id, Name => $t->translation->stable_id }, $properties);
            }
          }
        }
      }
    }
  }
  
  my %order = reverse %{$self->{'config'}->{'feature_order'}};
  
  $self->string('##gff-version 3');
  $self->string(sprintf('##sequence-region %s 1 %d', $slice->seq_region_name, $slice->seq_region_length));
  $self->string('');
  $self->string($self->output($order{$_})) for sort { $a <=> $b } keys %order;
}

1;
