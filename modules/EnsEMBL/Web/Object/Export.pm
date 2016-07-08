=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::Export;

use strict;

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
          foreach my $cds (@{$t->get_all_CDS||[]}) {
            $self->feature('CDS', $cds, { Parent => $t_id, Name => $t->translation->stable_id }, $properties);
          }
        }

        if ($params->{'exon'}) {
          foreach my $e (@{$t->get_all_Exons}) {
            $self->feature('exon', $e, { Parent => $t_id, Name => $e->stable_id }, $properties);
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
