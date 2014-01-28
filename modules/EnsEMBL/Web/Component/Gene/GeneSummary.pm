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

# $Id: GeneSummary.pm,v 1.20 2013-03-21 14:59:27 nl2 Exp $

package EnsEMBL::Web::Component::Gene::GeneSummary;

use strict;

use EnsEMBL::Web::Document::TwoCol;

use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $table        = new EnsEMBL::Web::Document::TwoCol;
  my $location     = $hub->param('r') || sprintf '%s:%s-%s', $object->seq_region_name, $object->seq_region_start, $object->seq_region_end;
  my $site_type    = $species_defs->ENSEMBL_SITETYPE;
  my $matches      = $object->get_database_matches;
  my @CCDS         = grep $_->dbname eq 'CCDS', @{$object->Obj->get_all_DBLinks};
  my $db           = $object->get_db;
  my $alt_genes    = $self->_matches('alternative_genes', 'Alternative Genes', 'ALT_GENE');
  my $disp_syn     = 0;
  
  my ($display_name, $dbname, $ext_id, $dbname_disp, $info_text) = $object->display_xref;
  my ($prefix, $name, $disp_id_table, $HGNC_table, %syns, %text_info, $syns_html);

  # remove prefix from the URL for Vega External Genes
  if ($hub->species eq 'Mus_musculus' && $object->source eq 'vega_external') {
    ($prefix, $name) = split ':', $display_name;
    $display_name = $name;
  }
  
  my $linked_display_name = $hub->get_ExtURL_link($display_name, $dbname, $ext_id);

  $linked_display_name = $prefix . ':' . $linked_display_name if $prefix;
  $linked_display_name = $display_name if $dbname_disp =~ /^Projected/; # i.e. don't have a hyperlink
  $info_text = '';
  
  $table->add_row('Name', "<p>$linked_display_name ($dbname_disp) $info_text</p>") if $linked_display_name;
  
  $self->_sort_similarity_links(@$matches);
  
  foreach my $link (@{$object->__data->{'links'}{'PRIMARY_DB_SYNONYM'}||[]}) {
    my ($key, $text) = @$link;
    my $id           = [split /\<|\>/, $text]->[4];
    my $synonyms     = $self->get_synonyms($id, @$matches);
    
    $text =~ s/\<div\s*class="multicol"\>|\<\/div\>//g;
    $text =~ s/<br \/>.*$//gism;
    
    if ($id =~ /$display_name/ && $synonyms =~ /\w/) {
      $disp_syn  = 1;
      $syns{$id} = $synonyms;
    }
    
    $text_info{$id} = $text;
    $syns{$id}      = $synonyms if $synonyms =~ /\w/ && $id !~ /$display_name/;
  }
  
  foreach my $k (keys %text_info) {
    my $syn = $syns{$k};
    my $syn_entry;
    
    if ($syn && $disp_syn == 1) {
      my $url = $hub->url({
        type   => 'Location',
        action => 'Genome', 
        r      => $location,
        id     => $display_name,
        ftype  => 'Gene'
      });
      
      $syns_html .= qq{<p>$syn [<span class="small">To view all $site_type genes linked to the name <a href="$url">click here</a>.</span>]</p></dd>};
    }
  }

## EG
  if ($syns_html) {
      $table->add_row('Synonyms', $syns_html);
  } else { # check if synonyms are attached  via display xref .. 
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
  # add CCDS info
  if (scalar @CCDS) {
    my %temp = map { $_->primary_id, 1 } @CCDS;
    @CCDS = sort keys %temp;
    $table->add_row('CCDS', sprintf('<p>This gene is a member of the %s CCDS set: %s</p>', $species_defs->DISPLAY_NAME, join ', ', map $hub->get_ExtURL_link($_, 'CCDS', $_), @CCDS));
  }
  
  ## LRG info
  
  # first link to direct xrefs (i.e. this gene has an LRG)
  my @lrg_matches = grep {$_->dbname eq 'ENS_LRG_gene'} @$matches;
  my $lrg_html;
  my %xref_lrgs;    # this hash will store LRGs we don't need to re-print
  
  if(scalar @lrg_matches) {
    my $lrg_link;
    
    for my $i(0..$#lrg_matches) {
      my $lrg = $lrg_matches[$i];
      
      my $link = $hub->get_ExtURL_link($lrg->display_id, 'ENS_LRG_gene', $lrg->display_id);
      
      if($i == 0) { # first one
        $lrg_link .= $link;
      }
      elsif($i == $#lrg_matches) { # last one
        $lrg_link .= " and ".$link;
      }
      else { # any other
        $lrg_link .= ", ".$link;
      }
      
      $xref_lrgs{$lrg->display_id} = 1;
    }
    
    $lrg_link =
      $lrg_link." provide".
      (@lrg_matches > 1 ? "" : "s").
      " a stable genomic reference framework ".
      "for describing sequence variations for this gene";
    
    $lrg_html .= $lrg_link;
  }
  
  # now look for lrgs that contain or partially overlap this gene
  foreach my $attrib(@{$object->gene->get_all_Attributes('GeneInLRG')}, @{$object->gene->get_all_Attributes('GeneOverlapLRG')}) {
    next if $xref_lrgs{$attrib->value};
    my $link = $hub->get_ExtURL_link($attrib->value, 'ENS_LRG_gene', $attrib->value);
    $lrg_html .= '<br/>' if $lrg_html;
    $lrg_html .=
      'This gene is '.
      ($attrib->code =~ /overlap/i ? "partially " : " ").
      'overlapped by the stable genomic reference framework '.$link;
  }
  
  # add a row to the table
  $table->add_row('LRG', $lrg_html) if $lrg_html;
  
  # add some Vega info
  if ($db eq 'vega') {
    my $type    = $object->gene_type;
    my $version = $object->version;
    my $c_date  = $object->created_date;
    my $m_date  = $object->mod_date;
    my $author  = $object->get_author_name;
    my $remarks = $object->retrieve_remarks;
 
    $table->add_row('Gene type', qq{<p>$type [<a href="http://vega.sanger.ac.uk/info/about/gene_and_transcript_types.html" target="external">Definition</a>]</p>});
    $table->add_row('Version & date', qq{<p>Version $version</p><p>Modified on $m_date (<span class="small">Created on $c_date</span>)<span></p>});
    $table->add_row('Author', "This transcript was annotated by $author");
    if ( @$remarks ) {
      my $text;
      foreach my $rem (@$remarks) {
	next unless $rem;  #ignore remarks with a value of 0
	$text .= "<p>$rem</p>";
      }
      $table->add_row('Remarks', qq($text));
    }
  } else {
    my $type = $object->gene_type;
    $table->add_row('Gene type', $type) if $type;
  }
  
  eval {
    # add prediction method
    my $label = ($db eq 'vega' || $site_type eq 'Vega' ? 'Curation' : 'Prediction') . ' Method';
    my $text  = "<p>No $label defined in database</p>";
    my $o     = $object->Obj;
  
    if ($o && $o->can('analysis') && $o->analysis && $o->analysis->description) {
      $text = $o->analysis->description;
      $label = $o->analysis->web_data->{'method'} if($o->analysis->web_data->{'method'});
    } elsif ($object->can('gene') && $object->gene->can('analysis') && $object->gene->analysis && $object->gene->analysis->description) {
      $text = $object->gene->analysis->description;
    }
    
    $table->add_row($label, "<p>$text</p>");
  };
  
  $table->add_row('Alternative genes', "<p>$alt_genes</p>") if $alt_genes; # add alternative transcript info
  
  return $table->render;
}

sub get_synonyms {
  my ($self, $match_id, @matches) = @_;
  my ($ids, $syns);
  
  foreach my $m (@matches) {
    my $dbname = $m->db_display_name;
    my $disp_id = $m->display_id;
    
    if ($dbname =~/(HGNC|ZFIN)/ && $disp_id eq $match_id) {
      my $synonyms = $m->get_all_synonyms;
      $ids = '';
      $ids = $ids . ', ' . (ref $_ eq 'ARRAY' ? "@$_" : $_) for @$synonyms;
    }
  }
  
  $ids  =~ s/^\,\s*//;
  $syns = $ids if $ids =~ /^\w/;
  
  return $syns;
}

1;
