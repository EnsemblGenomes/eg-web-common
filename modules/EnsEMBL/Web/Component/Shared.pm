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
# EG:ENSEMBL-2785 add this new URL so that the Transcript info appears at the top of the page for the Karyotype display with Locations tables
        type   => 'Transcript',
        action => 'Similarity/Locations',
# EG:ENSEMBL-2785 end
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
  my $html        = '';
  my $page_type   = ref($self) =~ /::Gene\b/ ? 'gene' : 'transcript';
  my $description = $object->gene_description;
     $description = '' if $description eq 'No description';

  if ($description) {
    my ($edb, $acc);
    
    if ($object->get_db eq 'vega') {
      $edb = 'Vega';
      $acc = $object->Obj->stable_id;
      $description .= sprintf ' <span class="small">%s</span>', $hub->get_ExtURL_link("Source: $edb", $edb . '_' . lc $page_type, $acc);
    } else {
      $description =~ s/EC\s+([-*\d]+\.[-*\d]+\.[-*\d]+\.[-*\d]+)/$self->EC_URL($1)/e;
      $description =~ s/\[\w+:([-\w\/\_]+)\;\w+:([\w\.]+)\]//g;
      ($edb, $acc) = ($1, $2);

      my $l1   =  $hub->get_ExtURL($edb, $acc);
      $l1      =~ s/\&amp\;/\&/g;
      my $t1   = "Source: $edb $acc";
      my $link = $l1 ? qq(<a href="$l1">$t1</a>) : $t1;

      $description .= qq( <span class="small">@{[ $link ]}</span>) if $acc && $acc ne 'content';
    }

    $table->add_row('Description', $description);
  }

  my $location    = $hub->param('r') || sprintf '%s:%s-%s', $object->seq_region_name, $object->seq_region_start, $object->seq_region_end;

  my $site_type         = $hub->species_defs->ENSEMBL_SITETYPE; 
  my @SYNONYM_PATTERNS  = qw(%HGNC% %ZFIN%);
  my (@syn_matches, $syns_html, $counts_summary);
  push @syn_matches,@{$object->get_database_matches($_)} for @SYNONYM_PATTERNS;

  my $gene = $page_type eq 'gene' ? $object->Obj : $object->gene;
  foreach (@{$object->get_similarity_hash(0, $gene)}) {
    next unless $_->{'type'} eq 'PRIMARY_DB_SYNONYM';
    my $id           = $_->display_id; 
    my $synonym     = $self->get_synonyms($id, @syn_matches);
## EG
    next unless $synonym;
##     
    my $url = $hub->url({
      type   => 'Location',
      action => 'Genome',
      r      => $location, 
      id     => $id,
      ftype  => 'Gene',
    });  
    $syns_html .= qq{<p>$synonym [<span class="small"><a href="$url">View all $site_type genes linked to this name</a>.</span>]</p>};
  }


## EG
  if ($syns_html) {
      $table->add_row('Synonyms', $syns_html);
  } else { # check if synonyms are attached  via display xref .. 
      my ($display_name) = $object->display_xref;
      if (my $xref = $object->Obj->display_xref) {
        if (my $sn = $xref->get_all_synonyms) {
            my $syns = join ', ', grep { $_ && ($_ ne $display_name) } @$sn;
            if ($syns) {
              $table->add_row('Synonyms', "$syns",);
            }
        }
      }
  }
##

  my $seq_region_name  = $object->seq_region_name;
  my $seq_region_start = $object->seq_region_start;
  my $seq_region_end   = $object->seq_region_end;

  my $location_html = sprintf(
    '<a href="%s" class="constant">%s: %s-%s</a> %s.',
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
          <li><a href="/%s/Location/View?l=%s:%s-%s" class="constant">%s : %s-%s</a></li>', 
          $species, $altchr, $altstart, $altend, $altchr,
          $self->thousandify($altstart),
          $self->thousandify($altend)
        );
      }
      
      $location_html .= '
        </ul>';

    }
  }


  $table->add_row('Location', $location_html);
  my $gene = $object->gene;

  #text for tooltips
  my $gencode_desc = "The GENCODE set is the gene set for human and mouse. GENCODE Basic is a subset of representative transcripts (splice variants).";
  my $trans_5_3_desc = "5' and 3' truncations in transcript evidence prevent annotation of the start and the end of the CDS.";
  my $trans_5_desc = "5' truncation in transcript evidence prevents annotation of the start of the CDS.";
  my $trans_3_desc = "3' truncation in transcript evidence prevents annotation of the end of the CDS.";
  my $gene_html    = '';

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
      foreach my $attrib_type (qw(CDS_start_NF CDS_end_NF gencode_basic)) {
        (my $attrib) = @{$trans->get_all_Attributes($attrib_type)};
        if($attrib_type eq 'gencode_basic') {
            if ($attrib && $attrib->value) {
              $trans_gencode->{$trans->stable_id}{$attrib_type} = $attrib->value;
            }
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
      $gene_html = qq{This transcript is a product of gene <a href="$gene_url">$gene_id</a><br /><br />$gene_html};
    }
    
    my $show    = $hub->get_cookie_value('toggle_transcripts_table') eq 'open';
    my @columns = (
       { key => 'name',       sort => 'string',  title => 'Name'          },
       { key => 'transcript', sort => 'html',    title => 'Transcript ID' },
       { key => 'bp_length',  sort => 'numeric', title => 'Length'   },
       { key => 'protein',    sort => 'html',    title => 'Protein'    },
       { key => 'biotype',    sort => 'html',    title => 'Biotype'       },
    );

    push @columns, { key => 'ccds', sort => 'html', title => 'CCDS' } if $species =~ /^Homo|Mus/;
    
    my @rows;
   
    my %extra_links = (
      uniprot => { match => "^UniProt", name => "UniProt", order => 0, hidden => 1 },
      refseq => { match => "^RefSeq", name => "RefSeq", order => 1 },
    );
    my %any_extras;
 
    foreach (map { $_->[2] } sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map { [ $_->external_name, $_->stable_id, $_ ] } @$transcripts) {
      my $transcript_length = $_->length;
      my $tsi               = $_->stable_id;
      my $protein           = 'No protein product';
      my $protein_length    = '-';
      my $ccds              = '-';
      my %extras;
      my $cds_tag           = '-';
      my $gencode_set       = '-';
      my $url               = $hub->url({ %url_params, t => $tsi });
      my @flags;
      
      if ($_->translation) {
        $protein = sprintf(
          '(<a href="%s">%s</a>)',
          $hub->url({
            type   => 'Transcript',
            action => 'ProteinSummary',
            t      => $tsi
          }),
          'view'
        );
        
        $protein_length = $_->translation->length;
      }

      my $dblinks = $_->get_all_DBLinks;
      if (my @CCDS = grep { $_->dbname eq 'CCDS' } @$dblinks) { 
        my %T = map { $_->primary_id => 1 } @CCDS;
        @CCDS = sort keys %T;
        $ccds = join ', ', map $hub->get_ExtURL_link($_, 'CCDS', $_), @CCDS;
      }
      foreach my $k (keys %extra_links) {
        if(my @links = grep {$_->status ne 'PRED' } grep { $_->dbname =~ /$extra_links{$k}->{'match'}/i } @$dblinks) {
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
            push @flags,qq(<span class="glossary_mouseover">CDS 5' and 3' incomplete<span class="floating_popup">$trans_5_3_desc</span></span>);
          }
          else {
            push @flags,qq(<span class="glossary_mouseover">CDS 5' incomplete<span class="floating_popup">$trans_5_desc</span></span>);
          }
        }
        elsif ($trans_attribs->{$tsi}{'CDS_end_NF'}) {
         push @flags,qq(<span class="glossary_mouseover">CDS 3' incomplete<span class="floating_popup">$trans_3_desc</span></span>);
        }
      }

      if ($trans_gencode->{$tsi}) {
        if ($trans_gencode->{$tsi}{'gencode_basic'}) {
          push @flags,qq(<span class="glossary_mouseover">GENCODE basic<span class="floating_popup">$gencode_desc</span></span>);
        }
      }
      (my $biotype_text = $_->biotype) =~ s/_/ /g;
      my $merged = '';
      $merged .= " Merged Ensembl/Havana gene." if $_->analysis->logic_name =~ /ensembl_havana/;
      $extras{$_} ||= '-' for(keys %extra_links);
      my $row = {
        name       => { value => $_->display_xref ? $_->display_xref->display_id : 'Novel', class => 'bold' },
        transcript => sprintf('<a href="%s">%s</a>', $url, $tsi),
        bp_length  => $transcript_length,
        protein    => (($protein_length ne '-')?"$protein_length aa ":' ').$protein,
        biotype    => $self->colour_biotype($self->glossary_mouseover($biotype_text,undef,$merged),$_),
        ccds       => $ccds,
        %extras,
        has_ccds   => $ccds eq '-' ? 0 : 1,
        cds_tag    => $cds_tag,
        gencode_set=> $gencode_set,
        options    => { class => $count == 1 || $tsi eq $transcript ? 'active' : '' },
        flags => join('',map { "<span class='ts_flag'>$_</span>" } @flags),
      };
      
      $biotype_text = '.' if $biotype_text eq 'protein coding';
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
    # Add suffixes to lengths (kept numeric till now to aid sorting)
    for (@rows) { 
      $_->{'bp_length'} .= ' bp' if $_->{'bp_length'} =~ /\d/;
    }

    my @hidecols;
    foreach my $id (keys %extra_links) {
      foreach my $i (0..$#columns) {
        if($columns[$i]->{'key'} eq $id and $extra_links{$id}->{'hidden'}) {
          push @hidecols,$i;
          last;
        }
      }
    }

    my $table_2 = $self->new_table(\@columns, \@rows, {
      data_table        => 1,
      data_table_config => { asStripClasses => [ '', '' ], oSearch => { sSearch => '', bRegex => 'false', bSmart => 'false' } },
      toggleable        => 1,
      class             => 'fixed_width' . ($show ? '' : ' hide'),
      id                => 'transcripts_table',
      exportable        => 1,
      hidden_columns    => \@hidecols,
    });

    my $avail       = $object->availability;
    # since counts form left nav is gone, we are adding it in the description  
    if($page_type eq 'gene') {
      my @str_array;
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
    
    if($page_type eq 'transcript') {    
      my @str_array;
      
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

  my $insdc_accession;
  $insdc_accession = $self->object->insdc_accession if $self->object->can('insdc_accession');
  $table->add_row('INSDC coordinates',$insdc_accession) if $insdc_accession;

  $table->add_row( $page_type eq 'gene' ? 'About this gene' : 'About this transcript',$counts_summary) if $counts_summary;
    $table->add_row(
      $page_type eq 'gene' ? 'Transcripts' : 'Gene',
      $gene_html . sprintf(
        ' <a rel="transcripts_table" class="button toggle no_img set_cookie %s" href="#" title="Click to toggle the transcript table">
          <span class="closed">Show transcript table</span><span class="open">Hide transcript table</span>
        </a>',
        $show ? 'open' : 'closed'
      )
    );

    $html = $table->render.$table_2->render;

  } else {
    $html = $table->render;
  }
 
 
  return qq{<div class="summary_panel">$html</div>};
}


1;
