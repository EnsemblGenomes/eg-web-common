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

package EnsEMBL::Web::Document::HTML::SpeciesPage;

### Renders the content of the  "Find a species page" linked to from the SpeciesList module

use strict;
use warnings;
use Data::Dumper;
use HTML::Entities qw(encode_entities);
use EnsEMBL::Web::RegObj;

sub render {

  my ($class, $request) = @_;

  my $species_defs = $ENSEMBL_WEB_REGISTRY->species_defs;
  my $sitename = $species_defs->SITE_NAME;

  # check if we've got static content with species available resources and if so, use it
  # if not, use all the species page with no resources shown (red letters V P G A).
  my $content;
  my $filename = $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-'.$species_defs->GENOMIC_UNIT."/htdocs/info/data/resources.html";

  if (-e $filename) {
    open(my $fh, '<', $filename);
    {
        local $/;
        $content = <$fh>;
    }
    close($fh);
    return $content;
  }

  # taxon order:
  my $species_info = {};

  foreach ($species_defs->valid_species) {
      $species_info->{$_} = {
        key        => $_,
        name       => $species_defs->get_config($_, 'SPECIES_BIO_NAME'),
        common     => $species_defs->get_config($_, 'SPECIES_COMMON_NAME'),
        scientific => $species_defs->get_config($_, 'SPECIES_SCIENTIFIC_NAME'),
        group      => $species_defs->get_config($_, 'SPECIES_GROUP'),
        assembly   => $species_defs->get_config($_, 'ASSEMBLY_NAME')
        };
  }

  my $labels       = $species_defs->TAXON_LABEL; ## sort out labels
  my (@group_order, %label_check);

  foreach my $taxon (@{$species_defs->TAXON_ORDER || []}) {
      my $label = $labels->{$taxon} || $taxon;
      push @group_order, $label unless $label_check{$label}++;
  }

  ## Sort species into desired groups
  my %phylo_tree;
  foreach (keys %$species_info) {
      my $group = $species_info->{$_}->{'group'} ? $labels->{$species_info->{$_}->{'group'}} || $species_info->{$_}->{'group'} : 'no_group';
      push @{$phylo_tree{$group}}, $_;
  }

  ## Output in taxonomic groups, ordered by common name
  my @taxon_species;
  my $taxon_gr;
  my @groups;

  foreach my $group_name (@group_order) {
      my $optgroup     = 0;
      my $species_list = $phylo_tree{$group_name};
      my @sorted_by_common;
      my $gr_name;
      if ($species_list && ref $species_list eq 'ARRAY' && scalar @$species_list) {
	@sorted_by_common = sort { $a cmp $b } @$species_list;
	if ($group_name eq 'no_group') {
	      if (scalar @group_order) {
		  $gr_name = "Other species";
	      }
	} else {
	      $gr_name = encode_entities($group_name);
	}
        push @groups, $gr_name if (!scalar(@groups)) || grep {$_ ne $gr_name } @groups ;
      }
      unshift @sorted_by_common, $gr_name if ($gr_name);
      push @taxon_species, @sorted_by_common;
  }
  # taxon order eof

  my %species;
  my $group = '';

  my $pre_species = $species_defs->get_config('MULTI', 'PRE_SPECIES');
  foreach my $species (@taxon_species) { # (keys %$species_info) {
    $group =  $species if exists $phylo_tree{$species};
    next if exists $phylo_tree{$species};

    my $common = $species_defs->get_config($species, "SPECIES_COMMON_NAME");
    my $info = {
          'dir'     => $species,
          'status'  => 'live',
	  'provider' => $species_defs->get_config($species, "PROVIDER_NAME") || '',
	  'provider_url' => $species_defs->get_config($species, "PROVIDER_URL") || '',
	  'strain' => $species_defs->get_config($species, "SPECIES_STRAIN") || '',
	  'group' => $group,
	  'taxid' => $species_defs->get_config($species, "TAXONOMY_ID") || '',
    };
    $info->{'status'} = 'pre' if($pre_species && exists $pre_species->{$species});

    $species{$common} = $info;
  }
  my $link_style = 'font-size:1.1em;font-weight:bold;text-decoration:none;';

  my $html = qq(
<div class="column-wrapper"><div class="box-left" style="width:auto"><h2>$sitename Species</h2></div>
	       );

  my %groups = map {$species{$_}->{group} => 1} keys %species;
 
  foreach my $gr (@groups) {  # (sort keys %groups) {
      my @species = sort grep { $species{$_}->{'group'} eq $gr } keys %species;
   
      my $total = scalar(@species);
      my $break = int($total / 3);
      $break++ if $total % 3;
      my $colspan = $break * 2;


      $html .= qq{<table style="width:100%">
                    <tr>
                      <td colspan="$colspan" style="width:50%;padding-top:1em">
                       <h3>$gr</h3>
                      </td>
                 };

      ## Reset total to number of cells required for a complete table
      $total = $break * 3;
      my $cell_count = 0;
      for (my $i=0; $i < $total; $i++) {
	  my $col = int($i % 3);
	  if ($col == 0 && $i < ($total - 1)) {
	      $html .= qq(</tr>\n<tr>);
	  }
	  my $row = int($i/3);
	  my $j = $row + $break * $col;
#	  warn "$i * $col * $row * $break => $j \n";

	  my $common = $species[$j];
	  next unless $common;
	  my $info = $species{$common};

	  my $dir = $info->{'dir'};

	  (my $name = $dir) =~ s/_/ /;
	  my $link_text = $common =~ /\./ ? $name : $common;

	  $html .= qq(<td style="width:8%;text-align:right;padding-bottom:1em">);
	  if ($dir) {
	      $html .= qq(<img class="species-img" style="width:40px;height:40px" src="/i/species/48/$dir.png" alt="$name">);
	  }
	  else {
	      $html .= '&nbsp;';
	  }
	  $html .= qq(</td><td style="width:25%;padding:2px;padding-bottom:1em">);

	  if ($dir) {
              $html .= qq(<a href="/$dir/Info/Index/"  style="$link_style">$link_text</a>);
	      $html .= ' (preview - assembly only)' if ($info->{'status'} eq 'pre');
	      unless ($common =~ /\./) {
		      my $provider = $info->{'provider'};
		      my $url  = $info->{'provider_url'};

		      my $strain = $info->{'strain'} ? " $info->{'strain'}" : '';
		      $name .= $strain;

		      if ($provider) {
                          if (ref $provider eq 'ARRAY') {
                              my @urls = ref $url eq 'ARRAY' ? @$url : ($url);
                              my $phtml;

                              foreach my $pr (@$provider) {
                                  my $u = shift @urls;
                                  if ($u) {
                                      $u = "http://$u" unless ($u =~ /http/);
                                      $phtml .= qq{<a href="$u" title="Provider: $pr">$pr</a> &nbsp;};
                                  } else {
                                      $phtml .= qq{$pr &nbsp;};
                                  }
                              }

                              $html .= qq{<br />$phtml | <i>$name</i>};
                          } else {
                              if ($url) {
                                  $url = "http://$url" unless ($url =~ /http/);
                                  $html .= qq{<br /><a href="$url" title="Provider: $provider">$provider</a> | <i>$name</i>};
                              } else {
                                  $html .= qq{<br />$provider | <i>$name</i>};
                              }
                          }
		      } else {
		          $html .= qq{<br /><i>$name</i>};
		      }
	      }
        if($info->{'taxid'}){
          (my $uniprot_url = $species_defs->ENSEMBL_EXTERNAL_URLS->{'UNIPROT_TAXONOMY'}) =~ s/###ID###/$info->{taxid}/;
          $html .= sprintf(' | <a href="%s" title="Taxonomy ID: %s">%s</a>',$uniprot_url, $info->{'taxid'}, $info->{'taxid'});
        }
	  }
	  else {
	      $html .= '&nbsp;';
	  }
	  $html .= '</td>';
          $cell_count++;
      }

      # add empty cells to the row if needed: 
      if($cell_count < 3) {
        for (my $i = $cell_count; $i < 3; $i++) {
	    $html .= qq(<td>&nbsp;</td><td>&nbsp;</td>);
        }
      }

      $html .= qq(
		  </tr>
		  </table>);
  }

  return $html;

}


1;
