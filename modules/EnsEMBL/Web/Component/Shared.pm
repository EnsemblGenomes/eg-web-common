=head1 LICENSE

Copyright [2009-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Shared;

use strict;
use previous qw(species_stats);

use EnsEMBL::Web::Utils::FormatText qw(helptip glossary_helptip get_glossary_entry);

sub _sort_similarity_links {
  my $self             = shift;
  my $output_as_table  = shift || 0;
  my $show_version     = shift || 0;
  my $xref_type        = shift || '';
  my @similarity_links = @_;

  my $hub              = $self->hub;
  my $object           = $self->object;
  my $database         = $hub->database;
  my $db               = $object->get_db;
  my $urls             = $hub->ExtURL;
  my $fv_type          = $hub->action eq 'Oligos' ? 'OligoFeature' : 'Xref'; # default link to featureview is to retrieve an Xref
  my (%affy, %exdb);

  # Get the list of the mapped ontologies 
  my @mapped_ontologies = @{$hub->species_defs->SPECIES_ONTOLOGIES || ['GO']};
  my $ontologies = join '|', @mapped_ontologies, 'goslim_goa';

  foreach my $type (sort {
    $b->priority        <=> $a->priority        ||
    $a->db_display_name cmp $b->db_display_name ||
    $a->display_id      cmp $b->display_id
  } @similarity_links) {
    my $link       = '';
    my $join_links = 0;
    my $externalDB = $type->database;
    my $display_id = $type->display_id;
    my $primary_id = $type->primary_id;

    # hack for LRG
    $primary_id =~ s/_g\d*$// if $externalDB eq 'ENS_LRG_gene';

    next if $type->status eq 'ORTH';                            # remove all orthologs
    next if lc $externalDB eq 'medline';                        # ditch medline entries - redundant as we also have pubmed
    next if $externalDB =~ /^flybase/i && $display_id =~ /^CG/; # ditch celera genes from FlyBase
    next if $externalDB eq 'Vega_gene';                         # remove internal links to self and transcripts
    next if $externalDB eq 'Vega_transcript';
    next if $externalDB eq 'Vega_translation';
    next if $externalDB eq 'OTTP' && $display_id =~ /^\d+$/;    # don't show vega translation internal IDs
    next if $externalDB eq 'shares_CDS_with_ENST';

    if ($externalDB =~ /^($ontologies)$/) {
      push @{$object->__data->{'links'}{'go'}}, $display_id;
      next;
    } elsif ($externalDB eq 'GKB') {
      my ($key, $primary_id) = split ':', $display_id;
      push @{$object->__data->{'links'}{'gkb'}->{$key}}, $type;
      next;
    }

    my $text = $display_id;

    (my $A = $externalDB) =~ s/_predicted//;

    if ($urls && $urls->is_linked($A)) {
      $type->{ID} = $primary_id;
#Extract Wormbase species and make a correct link
      if ($A =~ /^wormbase/i) {
         my $wormbase_link = $hub->species_defs->ENSEMBL_EXTERNAL_URLS->{uc ($hub->species) . '_URL'};
         if ($wormbase_link) {
            $type->{WORMBASE_SPECIES_NAME} =  substr $wormbase_link, rindex($wormbase_link, '/') + 1;         
         }
      }
      $link = $urls->get_url($A, $type);      
      
      my $word = $display_id;
      $word .= " ($primary_id)" if $A eq 'MARKERSYMBOL';

      if ($link) {
        $text = qq{<a href="$link" class="constant">$word</a>};
      } else {
        $text = $word;
      }
    }
    if ($type->isa('Bio::EnsEMBL::IdentityXref')) {
      $text .= ' <span class="small"> [Target %id: ' . $type->ensembl_identity . '; Query %id: ' . $type->xref_identity . ']</span>';
      $join_links = 1;
    }
## EG
    if ($hub->species_defs->ENSEMBL_PFETCH_SERVER && $externalDB =~ /^(LocusLink|protein_id|RefSeq|EMBL|Gene-name|Uniprot)/i && ref($object->Obj) eq 'Bio::EnsEMBL::Transcript' && $externalDB !~ /uniprot_genename/i) {
##     
      my $seq_arg = $display_id;
      $seq_arg    = "LL_$seq_arg" if $externalDB eq 'LocusLink';

      my $url = $self->hub->url({
        type     => 'Transcript',
        action   => 'Similarity/Align',
        sequence => $seq_arg,
        extdb    => lc $externalDB
      });

      $text .= qq{ [<a href="$url">align</a>] };
    }
## EG
    #$text .= sprintf ' [<a href="%s">Search GO</a>]', $urls->get_url('GOSEARCH', $primary_id) if $externalDB =~ /^(SWISS|SPTREMBL)/i; # add Search GO link;
##
    if ($show_version && $type->version) {
      my $version = $type->version;
      $text .= " (version $version)";
    }

    if ($type->description) {
      (my $D = $type->description) =~ s/^"(.*)"$/$1/;
      $text .= '<br />' . encode_entities($D);
      $join_links = 1;
    }

    if ($join_links) {
      $text = qq{\n <div>$text};
    } else {
      $text = qq{\n <div class="multicol">$text};
    }

    # override for Affys - we don't want to have to configure each type, and
    # this is an internal link anyway.
    if ($externalDB =~ /^AFFY_/i) {
      next if $affy{$display_id} && $exdb{$type->db_display_name}; # remove duplicates

      $text = qq{\n  <div class="multicol"> $display_id};
      $affy{$display_id}++;
      $exdb{$type->db_display_name}++;
    }

    # add link to featureview
    ## FIXME - another LRG hack! 
    if ($externalDB eq 'ENS_LRG_gene') {
      my $lrg_url = $self->hub->url({
        type    => 'LRG',
        action  => 'Genome',
        lrg     => $display_id,
      });

      $text .= qq{ [<a href="$lrg_url">view all locations</a>]};
    } else {
      my $link_name = $fv_type eq 'OligoFeature' ? $display_id : $primary_id;
      my $link_type = $fv_type eq 'OligoFeature' ? $fv_type    : "${fv_type}_$externalDB";

      my $k_url = $self->hub->url({
        type   => 'Location',
        action => 'Genome',
        id     => $link_name,
        ftype  => $link_type
      });
      $text .= qq{  [<a href="$k_url">view all locations</a>]} unless ($xref_type =~ /^ALT/ || $externalDB eq 'ENA_FEATURE_GENE' || $externalDB eq 'ENA_FEATURE_TRANSCRIPT' || $externalDB eq 'ENA_FEATURE_PROTEIN');
    }

    $text .= '</div>' if $join_links;

    my $label = $type->db_display_name || $externalDB;
    $label    = 'LRG' if $externalDB eq 'ENS_LRG_gene'; ## FIXME Yet another LRG hack!

    push @{$object->__data->{'links'}{$type->type}}, [ $label, $text ];
  }
}

sub species_stats {
  my $self = shift;
  my $sd = $self->hub->species_defs;
  my $html;
  my $db_adaptor = $self->hub->database('core');
  my $meta_container = $db_adaptor->get_MetaContainer();
  my $genome_container = $db_adaptor->get_GenomeContainer();

  #deal with databases that don't have species_stats
  return $html if $genome_container->is_empty;

  $html = '<h3>Summary</h3>';

  my $cols = [
    { key => 'name', title => '', width => '30%', align => 'left' },
    { key => 'stat', title => '', width => '70%', align => 'left' },
  ];
  my $options = {'header' => 'no', 'rows' => ['bg3', 'bg1']};

  ## SUMMARY STATS
  my $summary = $self->new_table($cols, [], $options);

  my( $a_id ) = ( @{$meta_container->list_value_by_key('assembly.name')},
                    @{$meta_container->list_value_by_key('assembly.default')});
  if ($a_id) {
    # look for long name and accession num
    if (my ($long) = @{$meta_container->list_value_by_key('assembly.long_name')}) {
      $a_id .= " ($long)";
    }
    if (my ($acc) = @{$meta_container->list_value_by_key('assembly.accession')}) {
      my $assembly_url = $self->hub->get_ExtURL('ENA_FEATURE', $acc);
      $a_id .= qq {, INSDC Assembly <a href="$assembly_url">$acc</a>};
    }
  }
  $summary->add_row({
      'name' => '<b>Assembly</b>',
      'stat' => $a_id.', '.$sd->ASSEMBLY_DATE
  });
  $summary->add_row({
      'name' => '<b>Database version</b>',
      'stat' => $sd->ENSEMBL_VERSION.'.'.$sd->SPECIES_RELEASE_VERSION
  });
  my $header = glossary_helptip($self->hub, 'Golden Path Length', 'Golden path length');
  $summary->add_row({
      'name' => "<b>$header</b>",
      'stat' => $self->thousandify($genome_container->get_ref_length())
  });
  $summary->add_row({
      'name' => '<b>Genebuild by</b>',
      'stat' => $sd->ANNOTATION_PROVIDER_NAME
  });
  my @A         = @{$meta_container->list_value_by_key('genebuild.method')};
  my $method  = ucfirst($A[0]) || '';
  $method     =~ s/_/ /g;
  $summary->add_row({
      'name' => '<b>Genebuild method</b>',
      'stat' => $method
  });
## EG - ENSEMBL-4575 hide some stats and show provider link(s)

  # $summary->add_row({
  #     'name' => '<b>Genebuild started</b>',
  #     'stat' => $sd->GENEBUILD_START
  # });
  # $summary->add_row({
  #     'name' => '<b>Genebuild released</b>',
  #     'stat' => $sd->GENEBUILD_RELEASE
  # });
  # $summary->add_row({
  #     'name' => '<b>Genebuild last updated/patched</b>',
  #     'stat' => $sd->GENEBUILD_LATEST
  # });
  # my $gencode = $sd->GENCODE_VERSION;
  # if ($gencode) {
  #   $summary->add_row({
  #     'name' => '<b>Gencode version</b>',
  #     'stat' => $gencode,
  #   });
  # }

  
  # data source

  if (my $names = $sd->ASSEMBLY_PROVIDER_NAME) {
    
    my $urls = $sd->ASSEMBLY_PROVIDER_URL;

    $names = [$names] if ref $names ne 'ARRAY';
    $urls  = [$urls]  if ref $urls  ne 'ARRAY';

    my @providers;
    foreach my $name (@$names){
      my $url = shift @$urls;
      push @providers, $url ? qq{<a href="$url">$name</a>} : $name;
    } 

    $summary->add_row({
      'name' => '<b>Data source</b>',
      'stat' => join '<br />', @providers,
    });
  }
##

  $html .= $summary->render;

  ## GENE COUNTS
  my $has_alt = $genome_container->get_alt_coding_count();
  if($has_alt) {
    $html .= $self->_add_gene_counts($genome_container,$sd,$cols,$options,' (Primary assembly)','');
    $html .= $self->_add_gene_counts($genome_container,$sd,$cols,$options,' (Alternative sequence)','a');
  } else {
    $html .= $self->_add_gene_counts($genome_container,$sd,$cols,$options,'','');
  }
  
  ## OTHER STATS
  my $rows = [];
  ## Prediction transcripts
  my $analysis_adaptor = $db_adaptor->get_AnalysisAdaptor();
  my $attribute_adaptor = $db_adaptor->get_AttributeAdaptor();
  my @analyses = @{ $analysis_adaptor->
                      fetch_all_by_feature_class('PredictionTranscript') };
  foreach my $analysis (@analyses) {
    my $logic_name = $analysis->logic_name;
    my $stat = $genome_container->fetch_by_statistic(
                                      'PredictionTranscript',$logic_name); 
    push @$rows, {
      'name' => "<b>".$stat->name."</b>",
      'stat' => $self->thousandify($stat->value),
    } if $stat and $stat->name;
  }
  ## Variants
  if ($self->hub->database('variation')) {
    my @other_stats = qw(SNPCount StructuralVariation);
    foreach my $name (@other_stats) {
      my $stat = $genome_container->fetch_by_statistic($name);
      push @$rows, {
        'name' => '<b>'.$stat->name.'</b>',
        'stat' => $self->thousandify($stat->value)
      } if $stat and $stat->name;
    }
  }
  if (scalar(@$rows)) {
    $html .= '<h3>Other</h3>';
    my $other = $self->new_table($cols, $rows, $options);
    $html .= $other->render;
  }

  return $html;
}

1;
