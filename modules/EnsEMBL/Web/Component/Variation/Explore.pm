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

package EnsEMBL::Web::Component::Variation::Explore;

use strict;

sub content {
  my $self               = shift;
  my $hub                = $self->hub;
  my $object             = $self->object;
  my $variation          = $object->Obj;
  my $species            = $hub->species;

  my $avail     = $self->object->availability;

  my ($seq_url, $gt_url, $pop_url, $geno_url, $context_url, $ld_url, $pheno_url, $phylo_url, $cit_url);
  $seq_url        = $hub->url({'action' => 'Sequence'});
  $context_url    = $hub->url({'action' => 'Context'});
  if ($avail->{'has_transcripts'}) {
    $gt_url   = $hub->url({'action' => 'Mappings'});
  }
  if ($avail->{'has_populations'}) {
    if ($avail->{'not_somatic'}) {
      $pop_url   = $hub->url({'action' => 'Population'});
    }
    elsif ($avail->{'is_somatic'}) {
      $pop_url  = $hub->url({'action' => 'Populations'});
    }
  }

  if ($avail->{'has_individuals'} && $avail->{'not_somatic'}) {
    $geno_url   = $hub->url({'action' => 'Individual'});
    if ($avail->{'has_ldpops'}) {
      $ld_url    = $hub->url({'action' => 'HighLD'});
    }
  }
  if ($avail->{'has_ega'}) {
    $pheno_url    = $hub->url({'action' => 'Phenotype'});
  }
  if ($avail->{'has_alignments'}) {
    $phylo_url    = $hub->url({'action' => 'Compara_Alignments'});
  }
  if ($avail->{'has_citation'}) {
    $cit_url      = $hub->url({'action' => 'Citations'});
  }
  
  my ($p_title, $p_img);
  if($avail->{'not_somatic'}) {
    ($p_title, $p_img) = ('Allele and genotype frequencies by population', 'population_genetics');
  }
  else {
    ($p_title, $p_img) = ('Samples with this variant', 'sample_information');
  }

  my @buttons = (
    {'title' => 'Graphical neighbourhood region', 'img' => 'genomic_context',        'url' => $context_url},
    {'title' => 'Consequences (e.g. missense)',   'img' => 'gene_transcript',        'url' => $gt_url},
    {'title' => $p_title,                 'img' => $p_img,                   'url' => $pop_url},
    {'title' => 'Individual genotypes',   'img' => 'individual_genotypes',   'url' => $geno_url},
    {'title' => 'LD plots and tables',    'img' => 'linkage_disequilibrium', 'url' => $ld_url},
    {'title' => 'Diseases and traits',    'img' => 'phenotype_data',         'url' => $pheno_url},
    {'title' => 'Citations',                        'img' => 'citations',    'url' => $cit_url},
    {'title' => 'Sequence conservation via cross-species alignments',   
                                          'img' => 'phylogenetic_context',   'url' => $phylo_url},
    {'title' => 'Upstream and downstream sequence', 'img' => 'flanking_sequence',      'url' => $seq_url},
  );

  my $html = '<div class="icon-holder">';

  foreach my $button (@buttons) {
    my $title = $button->{'title'};
    my $img   = 'var_'.$button->{'img'};
    my $url   = $button->{'url'};
    if ($url) {
      $html .= qq(<a href="$url"><img src="/i/96/${img}.png" class="portal _ht" alt="$title" title="$title" /></a>);
    }
    else {
      $title .= ' (NOT AVAILABLE)';
      $html  .= qq(<img src="/i/96/${img}_off.png" class="portal _ht" alt="$title" title="$title" />);
    }
  }

  $html .= '</div>';

  ## Variation documentation links
## EG - use old vep link
#  my $vep_link = $hub->url({'species' => $species, 'type' => 'Tools', 'action' => 'VEP', '__clear' => 1});
   my $vep_link = "/$species/UserData/UploadVariations?db=core";
##
  $html .= qq(
    <div class="column-wrapper">
      <div class="column-two column-first">
        <div class="column-left">
          <h2>Using the website</h2>
          <ul>
            <li>Video: <a href="/Help/Movie?id=208">Browsing SNPs and CNVs in Ensembl</a></li>
            <li>Video: <a href="/Help/Movie?id=214">Clip: Genome Variation</a></li>
            <li>Video: <a href="/Help/Movie?id=284">BioMart: Variation IDs to HGNC Symbols</a></li>
            <li>Exercise: <a href="/info/website/tutorials/malaria_basic_genetics_exercises_Ensembl.pdf">Genomes and SNPs in Malaria</a></li>
          </ul>
          <h2>Analysing your data</h2>
            <p><a href="$vep_link" alt="[logo]" style="vertical-align:middle" /></a> Test your own variants with the <a href="$vep_link">Variant Effect Predictor</a></p>
        </div>
      </div>
      <div class="column-two column-next">
        <div class="column-right">
          <h2>Programmatic access</h2>
          <ul>
            <li>Tutorial: <a href="/info/docs/api/variation/variation_tutorial.html">Accessing variation data with the Variation API</a></li>
          </ul>
          <h2>Reference materials</h2>
          <ul>
            <li><a href="/info/genome/variation/index.html">Ensembl variation documentation portal</a></li>
            <li><a href="/info/genome/variation/data_description.html">Ensembl variation data description</a></li>
            <!--<li><a href="/info/website/tutorials/variations_worked_example.pdf">Website Walkthrough - Variations</a></li>-->
            <li><a href="/info/website/tutorials/Ensembl_variation_quick_reference_card.pdf">Variation Quick Reference card</a></li>
          </ul>
        </div>
      </div>
    </div>
  );

  return $html;
}


1;
