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

package EnsEMBL::Web::Component::Summary;

use strict;
use previous qw(species_stats);

use EnsEMBL::Web::Utils::FormatText qw(helptip glossary_helptip get_glossary_entry);

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

  my $location    = sprintf '%s:%s-%s', $object->seq_region_name, $object->seq_region_start, $object->seq_region_end;

## EG - don't do Ensembl specific synonym stuff (not applicable and v.slow)
  #my @SYNONYM_PATTERNS  = qw(%HGNC% %ZFIN%);
  #my (@syn_matches, $syns_html, $about_count);
  #push @syn_matches,@{$object->get_database_matches($_)} for @SYNONYM_PATTERNS;
  #

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
    '<a href="%s" class="constant mobile-nolink dynamic-link">%s: %s-%s</a> %s.',
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
  my $gencode_desc    = qq(The GENCODE set is the gene set for human and mouse. <a href="/Help/Glossary?id=500" class="popup">GENCODE Basic</a> is a subset of representative transcripts (splice variants).);
  my $gene_html       = '';
  my $transc_table;

  if ($gene) {
    my $version     = $object->version ? ".".$object->version : "";
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
      foreach my $attrib_type (qw(CDS_start_NF CDS_end_NF gencode_basic TSL appris is_canonical)) {
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
       { key => 'protein',sort => 'html_numeric',label => 'Protein', title => 'Protein length in amino acids' },
       { key => 'translation',sort => 'html',    title => 'Translation ID', 'hidden' => 1 },
       { key => 'biotype',    sort => 'html',    title => 'Biotype', align => 'left' },
    );

    push @columns, { key => 'ccds', sort => 'html', title => 'CCDS' } if $species =~ /^Homo_sapiens|Mus_musculus/;
    
    my @rows;
   
## EG matches need to support mysql LIKE instead of regex
    my %extra_links = (
      uniprot => { match => "UniProt/S%", name => "UniProt", order => 0 },
      refseq => { match => "RefSeq%", name => "RefSeq", order => 1 },
    );
##
    my %any_extras;
 
    foreach (map { $_->[2] } sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map { [ $_->external_name, $_->stable_id, $_ ] } @$transcripts) {
      my $transcript_length = $_->length;
      my $version           = $_->version ? ".".$_->version : "";
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
        if (my $incomplete = $self->get_CDS_text($trans_attribs->{$tsi})) {
          push @flags, $incomplete;
        }
        if ($trans_attribs->{$tsi}{'TSL'}) {
          my $tsl = uc($trans_attribs->{$tsi}{'TSL'} =~ s/^tsl([^\s]+).*$/$1/gr);#/
	  push @flags, helptip("TSL:$tsl", get_glossary_entry($hub, "TSL:$tsl").get_glossary_entry($hub, 'TSL'));
        }
        if ($trans_attribs->{$tsi}{'is_canonical'}) {
          push @flags, helptip("Ensembl Canonical", get_glossary_entry($hub, "Ensembl canonical"));
        }
      }

      if ($trans_gencode->{$tsi}) {
        if ($trans_gencode->{$tsi}{'gencode_basic'}) {
	  push @flags, helptip('GENCODE basic', $gencode_desc);
        }
      }
      if ($trans_attribs->{$tsi}{'appris'}) {
        my ($code, $key) = @{$trans_attribs->{$tsi}{'appris'}};
        my $short_code = $code ? ' '.uc($code) : '';
	  push @flags, helptip("APPRIS$short_code", get_glossary_entry($hub, "APPRIS: $key").get_glossary_entry($hub, 'APPRIS'));
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
        name        => { value => $_->display_xref ? $_->display_xref->display_id : '-', class => 'bold' },
        transcript  => sprintf('<a href="%s">%s%s</a>', $url, $tsi, $version),
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
      data_table_config => { bPaginate => 'false', asStripClasses => [ '', '' ], oSearch => { sSearch => '', bRegex => 'false', bSmart => 'false' } },
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

  my $url = $hub->get_ExtURL($dbname, $primary_id) if $dbname and $primary_id;

  return $url ? ($url, $primary_id) : ()
}
##

1;
