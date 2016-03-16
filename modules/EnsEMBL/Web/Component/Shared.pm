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

package EnsEMBL::Web::Component::Shared;

use strict;

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
      $link = $urls->get_url($A, $type);
      my $word = $display_id;
      $word .= " ($primary_id)" if $A eq 'MARKERSYMBOL';

      if ($link) {
## EG - VectorBase hack for KEGG Enzyme acc which contains both pathway and enzyme id
        $link =~ s/%2B/&multi_query=/ if $externalDB eq 'KEGG_Enzyme';
##
        $text = qq{<a href="$link" class="constant">$word</a>};
      } else {
        $text = $word;
      }
    }
    if ($type->isa('Bio::EnsEMBL::IdentityXref')) {
      $text .= ' <span class="small"> [Target %id: ' . $type->target_identity . '; Query %id: ' . $type->query_identity . ']</span>';
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

sub transcript_table {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;  
  my $species     = $hub->species;
  my $table       = $self->new_twocol;
  my $page_type   = ref($self) =~ /::Gene\b/ ? 'gene' : 'transcript';
  my $description = $object->gene_description;
     $description = '' if $description eq 'No description';
  my $show        = $hub->get_cookie_value('toggle_transcripts_table') eq 'open';
  my $button      = sprintf('<a rel="transcripts_table" class="button toggle no_img _slide_toggle set_cookie %s" href="#" title="Click to toggle the transcript table">
    <span class="closed">Show transcript table</span><span class="open">Hide transcript table</span>
    </a>',
    $show ? 'open' : 'closed'
  );
  my $about_count;

  if ($description) {

    my ($url, $xref) = $self->get_gene_display_link($object->gene, $description);

    if ($xref) {
## EG - returns xref as string
#      $xref        = $xref->primary_id;
##
      $description =~ s|$xref|<a href="$url" class="constant">$xref</a>|;
    }

    $table->add_row('Description', $description);
  }

  my $location    = $hub->param('r') || sprintf '%s:%s-%s', $object->seq_region_name, $object->seq_region_start, $object->seq_region_end;

## EG - don't do Ensembl specific synonym stuff (not applicable and v.slow)
  #my @SYNONYM_PATTERNS  = qw(%HGNC% %ZFIN%);
  #my (@syn_matches, $syns_html, $about_count);
  #push @syn_matches,@{$object->get_database_matches($_)} for @SYNONYM_PATTERNS;
 
  # foreach (@{$object->get_similarity_hash(0, $gene)}) {
  #   next unless $_->{'type'} eq 'PRIMARY_DB_SYNONYM';
  #   my $id           = $_->display_id;
  #   my $synonym     = $self->get_synonyms($id, @syn_matches);
  #   next unless $synonym;
  #   $syns_html .= "<p>$synonym</p>";
  # }
##

## EG
  # check if synonyms are attached  via display xref .. 
  my ($display_name) = $object->display_xref;
  if (my $xref = $object->Obj->display_xref) {
    if (my $sn = $xref->get_all_synonyms) {
        my $syns = join ', ', grep { $_ && ($_ ne $display_name) } @$sn;
        if ($syns) {
          $table->add_row('Synonyms', "$syns",);
        }
    }
  }
##

  my $gene = $page_type eq 'gene' ? $object->Obj : $object->gene;
  $self->add_phenotype_link($gene, $table); #function in mobile plugin

  my $seq_region_name  = $object->seq_region_name;
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;

  my $location_html = sprintf(
    '<a href="%s" class="constant mobile-nolink">%s: %s-%s</a> %s.',
    $hub->url({
      type   => 'Location',
      action => 'View',
      r      => $location, 
    }),
    $self->neat_sr_name($object->seq_region_type, $seq_region_name),
    $self->thousandify($seq_region_start),
    $self->thousandify($seq_region_end),
    $object->seq_region_strand < 0 ? ' reverse strand' : 'forward strand'
  );
 
  # alternative (Vega) coordinates
  if ($object->get_db eq 'vega') {
    my $alt_assemblies  = $hub->species_defs->ALTERNATIVE_ASSEMBLIES || [];
    my ($vega_assembly) = map { $_ =~ /VEGA/; $_ } @$alt_assemblies;
    
    # set dnadb to 'vega' so that the assembly mapping is retrieved from there
    my $reg        = 'Bio::EnsEMBL::Registry';
    my $orig_group = $reg->get_DNAAdaptor($species, 'vega')->group;
    
    $reg->add_DNAAdaptor($species, 'vega', $species, 'vega');

    my $alt_slices = $object->vega_projection($vega_assembly); # project feature slice onto Vega assembly
    
    # link to Vega if there is an ungapped mapping of whole gene
    if (scalar @$alt_slices == 1 && $alt_slices->[0]->length == $object->feature_length) {
      my $l = $alt_slices->[0]->seq_region_name . ':' . $alt_slices->[0]->start . '-' . $alt_slices->[0]->end;
      
      $location_html .= ' [<span class="small">This corresponds to ';
      $location_html .= sprintf(
        '<a href="%s" target="external" class="constant">%s-%s</a>',
        $hub->ExtURL->get_url('VEGA_CONTIGVIEW', $l),
        $self->thousandify($alt_slices->[0]->start),
        $self->thousandify($alt_slices->[0]->end)
      );
      
      $location_html .= " in $vega_assembly coordinates</span>]";
    } else {
      $location_html .= sprintf qq{ [<span class="small">There is no ungapped mapping of this %s onto the $vega_assembly assembly</span>]}, lc $object->type_name;
    }
    
    $reg->add_DNAAdaptor($species, 'vega', $species, $orig_group); # set dnadb back to the original group
  }

  $location_html = "<p>$location_html</p>";

  my $insdc_accession = $self->object->insdc_accession if $self->object->can('insdc_accession');
  if ($insdc_accession) {
    $location_html .= "<p>$insdc_accession</p>";
  }

  if ($page_type eq 'gene') {
    # Haplotype/PAR locations
    my $alt_locs = $object->get_alternative_locations;

    if (@$alt_locs) {
      $location_html .= '
        <p> This gene is mapped to the following HAP/PARs:</p>
        <ul>';
      
      foreach my $loc (@$alt_locs) {
        my ($altchr, $altstart, $altend, $altseqregion) = @$loc;
        
        $location_html .= sprintf('
          <li><a href="/%s/Location/View?l=%s:%s-%s" class="constant mobile-nolink">%s : %s-%s</a></li>', 
          $species, $altchr, $altstart, $altend, $altchr,
          $self->thousandify($altstart),
          $self->thousandify($altend)
        );
      }
      
      $location_html .= '
        </ul>';
    }
  }

  my $gene = $object->gene;

  #text for tooltips
  my $gencode_desc    = "The GENCODE set is the gene set for human and mouse. GENCODE Basic is a subset of representative transcripts (splice variants).";
  my $trans_5_3_desc  = "5' and 3' truncations in transcript evidence prevent annotation of the start and the end of the CDS.";
  my $trans_5_desc    = "5' truncation in transcript evidence prevents annotation of the start of the CDS.";
  my $trans_3_desc    = "3' truncation in transcript evidence prevents annotation of the end of the CDS.";
  my $gene_html       = '';
  my $transc_table;

  if ($gene) {
    my $transcript  = $page_type eq 'transcript' ? $object->stable_id : $hub->param('t');
    my $transcripts = $gene->get_all_Transcripts;
    my $count       = @$transcripts;
    my $plural      = 'transcripts';
    my $splices     = 'splice variants';
    my $action      = $hub->action;
    my %biotype_rows;

    my $trans_attribs = {};
    my $trans_gencode = {};

    foreach my $trans (@$transcripts) {
      foreach my $attrib_type (qw(CDS_start_NF CDS_end_NF gencode_basic TSL appris)) {
        (my $attrib) = @{$trans->get_all_Attributes($attrib_type)};
        next unless $attrib;
        if($attrib_type eq 'gencode_basic' && $attrib->value) {
          $trans_gencode->{$trans->stable_id}{$attrib_type} = $attrib->value;
        } elsif ($attrib_type eq 'appris'  && $attrib->value) {
          ## There should only be one APPRIS code per transcript
          my $short_code = $attrib->value;
          ## Manually shorten the full attrib values to save space
          $short_code =~ s/ernative//;
          $short_code =~ s/rincipal//;
          $trans_attribs->{$trans->stable_id}{'appris'} = [$short_code, $attrib->value]; 
          last;
        } else {
          $trans_attribs->{$trans->stable_id}{$attrib_type} = $attrib->value if ($attrib && $attrib->value);
        }
      }
    }
    my %url_params = (
      type   => 'Transcript',
      action => $page_type eq 'gene' || $action eq 'ProteinSummary' ? 'Summary' : $action
    );
    
    if ($count == 1) { 
      $plural =~ s/s$//;
      $splices =~ s/s$//;
    }   
    
    if ($page_type eq 'transcript') {
      my $gene_id  = $gene->stable_id;
      my $gene_url = $hub->url({
        type   => 'Gene',
        action => 'Summary',
        g      => $gene_id
      });
      $gene_html .= sprintf('<p>This transcript is a product of gene <a href="%s">%s</a> %s',
        $gene_url,
        $gene_id,
        $button
      );
    }

    ## Link to other haplotype genes
    my $alt_link = $object->get_alt_allele_link;
    if ($alt_link) {
      if ($page_type eq 'gene') {
        $location_html .= "<p>$alt_link</p>";
      }
    }   

    my @columns = (
       { key => 'name',       sort => 'string',  title => 'Name'          },
       { key => 'transcript', sort => 'html',    title => 'Transcript ID' },
       { key => 'bp_length',  sort => 'numeric', label => 'bp', title => 'Length in base pairs'},
       { key => 'protein',    sort => 'html',    label => 'Protein', title => 'Protein length in amino acids' },
       { key => 'translation',sort => 'html',    title => 'Translation ID', 'hidden' => 1 },
       { key => 'biotype',    sort => 'html',    title => 'Biotype', align => 'left' },
    );

    push @columns, { key => 'ccds', sort => 'html', title => 'CCDS' } if $species =~ /^Homo_sapiens|Mus_musculus/;
    
    my @rows;
   
    my %extra_links = (
      uniprot => { match => "^UniProt/[SWISSPROT|SPTREMBL]", name => "UniProt", order => 0 },
      refseq => { match => "^RefSeq", name => "RefSeq", order => 1 },
    );
    my %any_extras;
 
    foreach (map { $_->[2] } sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map { [ $_->external_name, $_->stable_id, $_ ] } @$transcripts) {
      my $transcript_length = $_->length;
      my $tsi               = $_->stable_id;
      my $protein           = '';
      my $translation_id    = '';
      my $protein_url       = '';
      my $protein_length    = '-';
      my $ccds              = '-';
      my %extras;
      my $cds_tag           = '-';
      my $gencode_set       = '-';
      my $url               = $hub->url({ %url_params, t => $tsi });
      my (@flags, @evidence);
      
      if (my $translation = $_->translation) {
        $protein_url    = $hub->url({ type => 'Transcript', action => 'ProteinSummary', t => $tsi });
        $translation_id = $translation->stable_id;
        $protein_length = $translation->length;
      }

## EG - faster to use the API for filtering
      if (my @CCDS = @{ $_->get_all_DBLinks('CCDS') }) { 
##        
        my %T = map { $_->primary_id => 1 } @CCDS;
        @CCDS = sort keys %T;
        $ccds = join ', ', map $hub->get_ExtURL_link($_, 'CCDS', $_), @CCDS;
      }
      foreach my $k (keys %extra_links) {
## EG - faster to use the API for filtering        
        if(my @links = grep {$_->status ne 'PRED' } @{ $_->get_all_DBLinks($extra_links{$k}->{'match'}) }) {
##          
          my %T = map { $_->primary_id => $_->dbname } @links;
          my $cell = '';
          my $i = 0;
          foreach my $u (map $hub->get_ExtURL_link($_,$T{$_},$_), sort keys %T) {
            $cell .= "$u ";
            if($i++==2 || $k ne 'uniprot') { $cell .= "<br/>"; $i = 0; }
          }
          $any_extras{$k} = 1;
          $extras{$k} = $cell;
        }
      }
      if ($trans_attribs->{$tsi}) {
        if ($trans_attribs->{$tsi}{'CDS_start_NF'}) {
          if ($trans_attribs->{$tsi}{'CDS_end_NF'}) {
            push @flags, $self->helptip("CDS 5' and 3' incomplete", $trans_5_3_desc);
          }
          else {
            push @flags, $self->helptip("CDS 5' incomplete", $trans_5_desc);
          }
        }
        elsif ($trans_attribs->{$tsi}{'CDS_end_NF'}) {
         push @flags, $self->helptip("CDS 3' incomplete", $trans_3_desc);
        }
        if ($trans_attribs->{$tsi}{'TSL'}) {
          my $tsl = uc($trans_attribs->{$tsi}{'TSL'} =~ s/^tsl([^\s]+).*$/$1/gr); #/
          push @flags, $self->helptip("TSL:$tsl", $self->get_glossary_entry("TSL:$tsl").$self->get_glossary_entry('TSL'));
        }
      }

      if ($trans_gencode->{$tsi}) {
        if ($trans_gencode->{$tsi}{'gencode_basic'}) {
          push @flags, $self->helptip('GENCODE basic', $gencode_desc);
        }
      }
      if ($trans_attribs->{$tsi}{'appris'}) {
        my ($code, $key) = @{$trans_attribs->{$tsi}{'appris'}};
        my $short_code = $code ? ' '.uc($code) : '';
          push @flags, $self->helptip("APPRIS$short_code", $self->get_glossary_entry("APPRIS: $key").$self->get_glossary_entry('APPRIS'));
      }

      (my $biotype_text = $_->biotype) =~ s/_/ /g;
      if ($biotype_text =~ /rna/i) {
        $biotype_text =~ s/rna/RNA/;
      }
      else {
        $biotype_text = ucfirst($biotype_text);
      } 

      $extras{$_} ||= '-' for(keys %extra_links);
      my $row = {
        name        => { value => $_->display_xref ? $_->display_xref->display_id : 'Novel', class => 'bold' },
        transcript  => sprintf('<a href="%s">%s</a>', $url, $tsi),
        bp_length   => $transcript_length,
        protein     => $protein_url ? sprintf '<a href="%s" title="View protein">%saa</a>', $protein_url, $protein_length : 'No protein',
        translation => $protein_url ? sprintf '<a href="%s" title="View protein">%s</a>', $protein_url, $translation_id : '-',
        biotype     => $self->colour_biotype($biotype_text, $_),
        ccds        => $ccds,
        %extras,
        has_ccds    => $ccds eq '-' ? 0 : 1,
        cds_tag     => $cds_tag,
        gencode_set => $gencode_set,
        options     => { class => $count == 1 || $tsi eq $transcript ? 'active' : '' },
        flags       => join('',map { $_ =~ /<img/ ? $_ : "<span class='ts_flag'>$_</span>" } @flags),
        evidence    => join('', @evidence),
      };
      
      $biotype_text = '.' if $biotype_text eq 'Protein coding';
      $biotype_rows{$biotype_text} = [] unless exists $biotype_rows{$biotype_text};
      push @{$biotype_rows{$biotype_text}}, $row;
    }
    foreach my $k (sort { $extra_links{$a}->{'order'} cmp
                          $extra_links{$b}->{'order'} } keys %any_extras) {
      my $x = $extra_links{$k};
      push @columns, { key => $k, sort => 'html', title => $x->{'name'}};
    }
    push @columns, { key => 'flags', sort => 'html', title => 'Flags' };

    ## Additionally, sort by CCDS status and length
    while (my ($k,$v) = each (%biotype_rows)) {
      my @subsorted = sort {$b->{'has_ccds'} cmp $a->{'has_ccds'}
                            || $b->{'bp_length'} <=> $a->{'bp_length'}} @$v;
      $biotype_rows{$k} = \@subsorted;
    }

    # Add rows to transcript table
    push @rows, @{$biotype_rows{$_}} for sort keys %biotype_rows; 
    
    @columns = $self->table_removecolumn(@columns); # implemented in mobile plugin
    
    $transc_table = $self->new_table(\@columns, \@rows, {
      data_table        => 1,
      data_table_config => { asStripClasses => [ '', '' ], oSearch => { sSearch => '', bRegex => 'false', bSmart => 'false' } },
      toggleable        => 1,
      class             => 'fixed_width' . ($show ? '' : ' hide'),
      id                => 'transcripts_table',
      exportable        => 1
    });
  
    if($page_type eq 'gene') {        
      $gene_html      .= $button;
    } 
    
    $about_count = $self->about_feature; # getting about this gene or transcript feature counts
    
  }

  $table->add_row('Location', $location_html);

  $table->add_row( $page_type eq 'gene' ? 'About this gene' : 'About this transcript',$about_count) if $about_count;
  $table->add_row($page_type eq 'gene' ? 'Transcripts' : 'Gene', $gene_html) if $gene_html;

  return sprintf '<div class="summary_panel">%s%s</div>', $table->render, $transc_table ? $transc_table->render : '';
}

# return the same columns; implemented in mobile plugin to remove some columns
sub table_removecolumn { 
  my ($self, @columns) = @_;
  
  return @columns;
}

#implemented in mobile plugin (having this as  a separate function so that we dont have to overwrite transcript_table function in the plugin)
sub add_phenotype_link {
  return "";
}

# since counts form left nav is gone, we are adding it in the description  (called in transcript_table function)
sub about_feature {
  my ($self) = @_;  
  
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $avail       = $object->availability;
  my $gene        = $object->gene;
  
  my $page_type   = ref($self) =~ /::Gene\b/ ? 'gene' : 'transcript';
  
  my (@str_array, $counts_summary);
  
  if ($page_type eq 'gene') {
    my $ortholog_url = $hub->url({
      type   => 'Gene',
      action => 'Compara_Ortholog',
      g      => $gene->stable_id
    });
    
    my $paralog_url = $hub->url({
      type   => 'Gene',
      action => 'Compara_Paralog',
      g      => $gene->stable_id
    });
    
    my $protein_url = $hub->url({
      type   => 'Gene',
      action => 'Family',
      g      => $gene->stable_id
    });

    my $phenotype_url = $hub->url({
      type   => 'Gene',
      action => 'Phenotype',
      g      => $gene->stable_id
    });    

    my $splice_url = $hub->url({
      type   => 'Gene',
      action => 'Splice',
      g      => $gene->stable_id
    });        
    
    push @str_array, sprintf('%s %s', 
                        $avail->{has_transcripts}, 
                        $avail->{has_transcripts} eq "1" ? "transcript (<a href='$splice_url'>splice variant</a>)" : "transcripts (<a href='$splice_url'>splice variants)</a>"
                    ) if($avail->{has_transcripts});
    push @str_array, sprintf('%s gene %s', 
                        $avail->{has_alt_alleles}, 
                        $avail->{has_alt_alleles} eq "1" ? "allele" : "alleles"
                    ) if($avail->{has_alt_alleles});
    push @str_array, sprintf('<a href="%s">%s %s</a>', 
                        $ortholog_url, 
                        $avail->{has_orthologs}, 
                        $avail->{has_orthologs} eq "1" ? "orthologue" : "orthologues"
                    ) if($avail->{has_orthologs});
    push @str_array, sprintf('<a href="%s">%s %s</a>',
                        $paralog_url, 
                        $avail->{has_paralogs}, 
                        $avail->{has_paralogs} eq "1" ? "paralogue" : "paralogues"
                    ) if($avail->{has_paralogs});    
    push @str_array, sprintf('is a member of <a href="%s">%s Ensembl protein %s</a>', $protein_url, 
                        $avail->{family_count}, 
                        $avail->{family_count} eq "1" ? "family" : "families"
                    ) if($avail->{family_count});
    push @str_array, sprintf('is associated with <a href="%s">%s %s</a>', 
                        $phenotype_url, 
                        $avail->{has_phenotypes}, 
                        $avail->{has_phenotypes} eq "1" ? "phenotype" : "phenotypes"
                    ) if($avail->{has_phenotypes});
   
    $counts_summary  = sprintf('This gene has %s.',$self->join_with_and(@str_array));  
  }
  
  if ($page_type eq 'transcript') {
    my $exon_url = $hub->url({
      type   => 'Transcript',
      action => 'Exons',
      g      => $gene->stable_id
    }); 
    
    my $similarity_url = $hub->url({
      type   => 'Transcript',
      action => 'Similarity',
      g      => $gene->stable_id
    }); 
    
    my $oligo_url = $hub->url({
      type   => 'Transcript',
      action => 'Oligos',
      g      => $gene->stable_id
    });     

    my $domain_url = $hub->url({
      type   => 'Transcript',
      action => 'Domains',
      g      => $gene->stable_id
    });
    
    my $variation_url = $hub->url({
      type   => 'Transcript',
      action => 'ProtVariations',
      g      => $gene->stable_id
    });     
   
    push @str_array, sprintf('<a href="%s">%s %s</a>', 
                        $exon_url, $avail->{has_exons}, 
                        $avail->{has_exons} eq "1" ? "exon" : "exons"
                      ) if($avail->{has_exons});
                      
    push @str_array, sprintf('is annotated with <a href="%s">%s %s</a>', 
                        $domain_url, $avail->{has_domains}, 
                        $avail->{has_domains} eq "1" ? "domain and feature" : "domains and features"
                      ) if($avail->{has_domains});

    push @str_array, sprintf('is associated with <a href="%s">%s %s</a>', 
                        $variation_url, 
                        $avail->{has_variations}, 
                        $avail->{has_variations} eq "1" ? "variation" : "variations",
                      ) if($avail->{has_variations});    
    
    push @str_array, sprintf('maps to <a href="%s">%s oligo %s</a>',    
                        $oligo_url,
                        $avail->{has_oligos}, 
                        $avail->{has_oligos} eq "1" ? "probe" : "probes"
                      ) if($avail->{has_oligos});
                
    $counts_summary  = sprintf('<p>This transcript has %s.</p>', $self->join_with_and(@str_array));
  }
  
  return $counts_summary;
}

## EG - hacked to avoid using the v.slow $gene->get_all_DBLinks()
##      todo: find a better solution using the API
sub get_gene_display_link {
  ## @param Gene object
  ## @param Gene xref object or description string
  my ($self, $gene, $xref) = @_;
  
  my $hub = $self->hub;
  my $dbname;
  my $primary_id;
  
  if ($xref && !ref $xref) { 
    # description string    
    my $details = { map { split ':', $_, 2 } split ';', $xref =~ s/^.+\[|\]$//gr }; #/
    if ($details->{'Source'} and $details->{'Acc'}) {
      my $dbh     = $hub->database($self->object->get_db)->dbc->db_handle;
      $dbname     = $dbh->selectrow_array('SELECT db_name FROM external_db WHERE db_display_name = ?', undef, $details->{'Source'});
      $primary_id = $details->{'Acc'};
    }
  } else { 
    # xref object
    if ($xref->info_type ne 'PROJECTION') {;
      $dbname     = $xref->dbname;
      $primary_id = $xref->primary_id;
    }
  }

  warn $xref;
  warn "$dbname --- $primary_id";

  my $url = $hub->get_ExtURL($dbname, $primary_id) if $dbname and $primary_id;

  return $url ? ($url, $primary_id) : ()
}
##

1;
