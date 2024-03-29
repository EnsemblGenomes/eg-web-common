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

package EnsEMBL::Web::Document::HTML::Compara;

## Provides content for compara documeentation - see /info/genome/compara/analyses.html
## Base class - does not itself output content

use strict;

use Math::Round;
use EnsEMBL::Web::Document::Table;
use Bio::EnsEMBL::Compara::Utils::SpeciesTree;
use Data::Dumper;

use base qw(EnsEMBL::Web::Document::HTML);

sub _link {
  my ($self,$text,$url)=@_;
  return sprintf(qq{<a href="%s">%s</a>},$url,$text);
}

sub species_table {
    my ($self, $data, $species) = @_;

    my $html = '';
    my $sdata = $data->{$species} || {};

    return $html unless $sdata;

#    warn Dumper $sdata;

    my $total = 0;
    map { $total += $sdata->{'counts'}->{$_} } sort keys %{$sdata->{'counts'}||{}};
    my $synteny_count = $sdata->{'counts'}->{'SYNTENY'} || 0;
    my $genomic_count = $total - $synteny_count;

    if ($genomic_count) {
	    my @rows;
	    my $sp1 = $data->{$species}->{'display_name'};
	    my $loc = $data->{$species}->{'sample_loc'} || '';

      my $lookup = $self->hub->species_defs->prodnames_to_urls_lookup;

	    foreach my $sp (sort {$data->{$a}->{'display_name'} cmp $data->{$b}->{'display_name'}} keys %{$sdata->{'align'}||{}}) {
	      my $sp2 = $data->{$sp}->{'display_name'};
	      foreach my $align (grep {$_ !~ /SYNTENY/} sort keys %{$sdata->{'align'}->{$sp}||{}}) {
		      my ($aid, $stats) = @{$sdata->{'align'}->{$sp}->{$align}||[]};
		      my $elink =  $self->hub->url({ 'species' => $species, 'type' => 'Location', 'action'=>'Compara_Alignments/Image', 'r'=>$loc, 'align' => $aid});
		      push @rows, {
		        'species' => $loc ? $self->_link("<em>$sp1</em> : <em>$sp2</em>", $elink) : $sp2,
		        'type' => $align . ($stats ? qq{ | <a href="/mlss.html?mlss=$aid">stats</a>} : '')
		      };
	      }    	
	    }

	    my $style = 'position:absolute; z-index:10; width:40% !important;';

	    my $table    = EnsEMBL::Web::Document::Table->new([
	              {key=>'species',title=>'Species'},
	              {key=>'type',title=>'Type',align=>'right'}
							  ],
							  \@rows,
							  {
							      data_table=>0,id=>$species . '_aligns',toggleable=>1,
							      exportable=>0,
							      header=>'no',
							      class=>sprintf('all_species_tables no_col_toggle hide'),
							      style=>$style,
							  },
	    );

	    my $shtml = sprintf qq{
<p>
 <div class="js_panel">

  <img src="/i/24/info.png" alt="" class="homepage-link" />Genomic alignments [%d] 
[<a rel="%s_aligns" class="toggle no_img closed" href="#" title="expand"><span class="closed"><small>Show</small>&raquo;</span><span class="open">&laquo;<small>Hide</small></span></a>%s]
 </div>
</p>}, $genomic_count, $species, $table->render;
        $html .= $shtml;
    }

    if ($synteny_count) {
	    my @rows;
	    my $sp1 = $data->{$species}->{'display_name'};
	    my $loc = $data->{$species}->{'sample_loc'} || '';

	    foreach my $sp (sort {$data->{$a}->{'display_name'} cmp $data->{$b}->{'display_name'}} keys %{$sdata->{'align'}||{}}) {
	      my $sp2 = $data->{$sp}->{'display_name'};
	      foreach my $align (grep {$_ =~ /SYNTENY/} sort keys %{$sdata->{'align'}->{$sp}||{}}) {
		      my ($aid, $stats) = @{$sdata->{'align'}->{$sp}->{$align}||[]};
		      push @rows, {
		        'species' => $loc ? $self->_link("<em>$sp1</em> : <em>$sp2</em>", $self->hub->url({ 'species' => $species, 'type' => 'Location', 'action'=>'Synteny', 'r'=>$loc, 'otherspecies' => ucfirst($sp)})) : $sp2,
 		        'type' => $stats ? qq{ | <a href="/mlss.html?mlss=$aid">stats</a>} : ''
		      };
	      }    	
	    }

	    my $style = 'position:absolute; z-index:1; width:40% !important;';

	    my $table    = EnsEMBL::Web::Document::Table->new([
	              {key=>'species',title=>'Species'},
	              {key=>'type',title=>'Type',align=>'right'}
							  ],
							  \@rows,
							  {
							      data_table=>0,id=>$species . '_synteny',toggleable=>1,
							      exportable=>0,
							      header=>'no',
							      class=>sprintf('all_species_tables no_col_toggle hide'),
							      style=>$style,
							  },
	    );


	    my $shtml = sprintf qq{
<p>
 <div class="js_panel">

  <img src="/i/24/info.png" alt="" class="homepage-link" />Syntenies [%d] 
[<a rel="%s_synteny" class="toggle no_img closed" href="#" title="expand"><span class="closed"><small>Show</small>&raquo;</span><span class="open">&laquo;<small>Hide</small></span></a>%s]
 </div>
</p>}, $synteny_count, $species, $table->render;
        $html .= $shtml;
  }

  return $html;
}

sub table {
  my ($self, $species) = @_;
    
  my $hub  = $self->hub;
  my $methods = ['SYNTENY', 'TRANSLATED_BLAT_NET','BLASTZ_NET', 'LASTZ_NET', 'ATAC'];
  my $data = get_compara_alignments($hub->database('compara'), $methods);

  my $thtml = qq{<table id="genomic_align_table" class="no_col_toggle ss autocenter" style="width: 100%" cellpadding="0" cellspacing="0">};

  my $lookup = $hub->species_defs->prodnames_to_urls_lookup;
  foreach my $sp (keys %$data) {
	  $data->{$sp}->{'name'} = $sp;
    my $sp_url = $lookup->{$sp};
    $data->{$sp}->{'url'} = $sp_url;
	  $data->{$sp}->{'display_name'} = $hub->species_defs->get_config($sp_url, 'SPECIES_DISPLAY_NAME');
	  my $loc = $hub->species_defs->get_config($sp_url, 'SAMPLE_DATA') || {};

	  $data->{$sp}->{'sample_loc'} = $loc->{LOCATION_PARAM};
	  (my $short_name = ucfirst($sp_url)) =~ s/([A-Z])[a-z]+_([a-z]{3})([a-z]+)?/$1.$2/; ## e.g. H.sap
	  $data->{$sp}->{'short_name'}     = $short_name;
	  my $chash = {};
	  map { map {$chash->{$_}++} keys %{$data->{$sp}->{'align'}->{$_} || {}} } keys %{$data->{$sp}->{'align'}||{}};
	  $data->{$sp}->{'counts'} = $chash; 
  }


  if ($species) {
	  return $self->species_table($data, $species);
  }

  my ($i, $j) = (0, 0);
  foreach my $species (sort {$data->{$a}->{'display_name'} cmp $data->{$b}->{'display_name'}} keys %$data) {
	  my $ybg = $i++ % 2 ? 'bg1' : 'bg2';

	  my $sdata = $data->{$species};

	  my $ghtml = sprintf qq{
<table id="%s_aligns" class="no_col_toggle ss toggle_table hide toggleable autocenter all_species_tables" style="width: 100%;" cellpadding="0" cellspacing="0">

}, $sdata->{'name'};
	  $j = $i;
	  my $adata = $sdata->{'align'};
	  foreach my $ss (sort keys %{$adata || {}}) {
      my $xbg = $j++ % 2 ? 'bg1' : 'bg2';
      my $astr = qq{<table cellpadding="0" cellspacing="2" style="width:100%">};
      foreach my $a (sort keys %{$adata->{$ss} || {}}) {
		    my ($aid, $stats) = @{$adata->{$ss}->{$a} || []};
		    my $sample_location = '&nbsp;';
        my $species_url     = $sdata->{'url'};
		    if ($sdata->{'sample_loc'}) {
		      if ($a =~ /SYNTENY/) {
			      $sample_location = sprintf qq{<a href="/%s/Location/Synteny?r=%s;otherspecies=%s">example</a>},$species_url,$sdata->{'sample_loc'}, $data->{$ss}{'url'};
		      } else {
			      $sample_location = sprintf qq{<a href="/%s/Location/Compara_Alignments/Image?align=%s;r=%s">example</a>},$species_url,$aid,$sdata->{'sample_loc'};
		      }
		    }
		    $astr .= sprintf qq{<tr>
<td style="padding:0px 10px 0px 0px;text-align:right;">&nbsp;</td>
<td style="padding:0px 10px 0px 0px;text-align:right;widht:20px">$a |</td>
<td style="padding:0px 10px 0px 0px;text-align:left;width:60px;">%s</td>
<td style="padding:0px 10px 0px 0px;text-align:left;width:40px;">%s</td><tr>},
$sample_location,
$stats ? qq{<a href="/info/genome/compara/mlss.html?mlss=$aid">stats</a>} : '&nbsp;';
	    }
	    $astr .= qq{</table>};
	    $ghtml .= sprintf qq{<tr class="%s"><td>%s</td><td>%s</td></tr>}, $xbg, $data->{$ss}->{'display_name'} || $ss, $astr;
	  }

	  $ghtml .= qq{</table>};
	  my $total = 0;
	  map { $total += $sdata->{'counts'}->{$_} } sort keys %{$sdata->{'counts'}||{}};
	  my $synteny_count = $sdata->{'counts'}->{'SYNTENY'} || 0;
	  my $genomic_count = $total - $synteny_count;

	  my $synteny_str = $synteny_count > 1 ? 'syntenies' : 'synteny';
	  my $chtml = sprintf qq {
<span style="text-align:left">%s</span> &nbsp; <span style="text-align:left">%s</span>}, $genomic_count ? ("$genomic_count alignment".($genomic_count > 1 ? 's':'')): "&nbsp;", $synteny_count ? "$synteny_count $synteny_str" : "&nbsp;";

	  my $sphtml = sprintf qq{
<tr class="%s">
  <td>

    <a title="Click to show/hide" rel="%s_aligns" class="toggle no_img closed" href="#">
      <span class="open closed" style="width:50%;float:left;">
        <strong><em>%s</em></strong>
      </span>
    </a>

    %s

    %s
  </td>
</tr>}, $ybg, $sdata->{'name'}, $sdata->{'display_name'}, $chtml, $ghtml;
	  $thtml .= $sphtml;
  }
    
  $thtml .= qq{</table>};

  my $html = sprintf qq{
<div id="GenomicAlignmentsTab" class="js_panel">
<input type="hidden" class="panel_type" value="Content"/>
<div class="info-box">
  <p>
    <a rel="all_species_tables" href="#" class="closed toggle" title="Expand all tables">
       <span class="closed">Toggle All</span>
       <span class="open">Toggle All</span>
    </a> or click a species names to expand/collapse its alignment list
  </p> 
  %s
</div>
</div>
}, $thtml;

  return $html;
}

sub get_compara_alignments {
  my ($compara_db, $methods) = @_;

  return unless $compara_db;
  
 my $dbh = $compara_db->dbc->db_handle;
 
 my $genome_dbs = $dbh->selectall_arrayref(
          "SELECT ml.type, gd.name, mlss.method_link_species_set_id, ss.species_set_id, 
           mlsst_ref.value AS ref_species, mlsst_blocks.value AS num_blocks
           FROM method_link ml
                JOIN method_link_species_set mlss USING (method_link_id)
                JOIN species_set ss USING (species_set_id)
                JOIN genome_db gd USING (genome_db_id)
                LEFT JOIN method_link_species_set_tag mlsst_ref USING (method_link_species_set_id)
                LEFT JOIN method_link_species_set_tag mlsst_blocks USING (method_link_species_set_id)
           WHERE 
                ml.type IN ('SYNTENY', 'TRANSLATED_BLAT_NET', 'BLASTZ_NET', 'LASTZ_NET', 'ATAC')
                AND mlsst_ref.tag = 'reference_species'
                AND mlsst_blocks.tag = 'num_blocks'
                ORDER BY name", { Slice => {} }
        ); 
        
        
        my $data = {};
        
        if(scalar(@$genome_dbs)){
            foreach my $genome_db(@$genome_dbs){
                if($genome_db->{'ref_species'} ne $genome_db->{'name'}){
                    $data->{$genome_db->{'ref_species'}}->{align}->{$genome_db->{'name'}}->{$genome_db->{'type'}} = [$genome_db->{'method_link_species_set_id'},  $genome_db->{'num_blocks'} ? 1 : 0];
                    $data->{$genome_db->{'name'}}->{align}->{$genome_db->{'ref_species'}}->{$genome_db->{'type'}} = [$genome_db->{'method_link_species_set_id'},  $genome_db->{'num_blocks'} ? 1 : 0];
                }
            }
         }
            
  return $data;
}

1;
