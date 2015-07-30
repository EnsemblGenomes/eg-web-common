
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

package EnsEMBL::Web::Component::Ontology;

use strict;

use Data::Dumper;

use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Constants;
use EnsEMBL::Web::Document::Image::Ontology;

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $oid          = $hub->param('oid');
  my $go           = $hub->param('go');
  my $tab          = $hub->param('tab');

  my %clusters = $species_defs->multiX('ONTOLOGIES');

  return "<p>Ontology database not found.</p>" unless %clusters;

  my $root = $clusters{$oid}->{root};

  if ((ref $object) !~ /Gene/) {
    return $self->non_coding_error unless $object->translation_object;
  }

  my $ochart = $object->get_ontology_chart($clusters{$oid}->{db}, $clusters{$oid}->{root}, $go);

  my $terms_found = scalar(grep {$ochart->{$_}->{selected}} keys %$ochart);

  my $html = '<div class="tabPanel" id="ontologyTabs">';

  if ($go) {
    $html .= qq{<div class="oTab" id="tabImage"> Ancestry chart of $go </div>};
  }
  else {
    $html .= qq{<div class="oTab" id="tabTable"> Annotated terms </div>};
    $html .= '<div class="oTab" id="tabImage"> Ancestry chart </div>';
  }

  $html .= '</div> <div id="tabImageContent" class="tabContent" style="display:none;"> ' . $self->ontology_chart($ochart, $clusters{$oid}->{db}, $root) . '</div>';

  $html .= '<div id="tabTableContent" class="tabContent" style="display:none;"> ' . $self->ontology_table($ochart) . '</div>' unless $go;

  $html = sprintf '<div class="js_panel"><input type="hidden" class="panel_type" value="Ontology"/>%s</div>', $html;
  #$html .= '<p>No ontology terms have been annotated to this entity.</p>' unless $terms_found;
  return $html;
}

sub ontology_table {
  my ($self, $chart) = @_;

  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $oid          = $hub->param('oid');
  my $go           = $hub->param('go');

  my $html = '';    #<p><h3>The following ontology terms have been annotated to this entry:</h3></p>';

  my $columns = [{key => 'ancestor_chart', title => 'Chart', width => '5%', align => 'centre'}, {key => 'go', title => 'Accession', width => '5%', align => 'left'}, {key => 'description', title => 'Term', width => '20%', align => 'left'}, {key => 'evidence', title => 'Evidence', width => '3%', align => 'center'}, {key => 'source', title => 'Annotation Source', width => '24%', align => 'center'}, {key => 'goslim_goa_acc', title => 'GOSlim Accessions', width => '5%', align => 'centre'}, {key => 'goslim_goa_title', title => 'GOSlim Terms', width => '20%', align => 'centre'},];

  my %clusters = $species_defs->multiX('ONTOLOGIES');

  my $olink = $clusters{$oid}->{db};

  if (my $settings = EnsEMBL::Web::Constants::ONTOLOGY_SETTINGS->{$olink}) {
    if ($settings->{url}) {
      $olink = sprintf qq{<a href="%s">%s</a>}, $settings->{url}, $settings->{name} || $olink;
    }
    else {
      $olink = $settings->{name} if ($settings->{name});
    }
  }

  my $go_database = $self->hub->get_databases('go')->{'go'};
  my @terms = grep {$chart->{$_}->{selected}} keys %$chart;
  if ($clusters{$oid}->{db} eq 'GO') {

    # In case of GO ontology try and get GO slim terms
    foreach (@terms) {
      my $query = qq(        
           SELECT t.accession, t.name,c.distance
           FROM closure c join term t on c.parent_term_id= t.term_id
           where child_term_id = (SELECT term_id FROM term where accession='$_')
           and parent_term_id in (SELECT term_id FROM term t where subsets like '%goslim_generic%')
           order by distance         
           );
      my $result = $go_database->dbc->db_handle->selectall_arrayref($query);
      foreach my $r (@$result) {
        my ($accession, $name, $distance) = @{$r};
        $chart->{$_}->{goslim}->{$accession}->{'name'}     = $name;
        $chart->{$_}->{goslim}->{$accession}->{'distance'} = $distance;
      }
    }
  }
  $html .= sprintf qq{<h3>The following terms describe the <i>%s</i> of this entry in %s</h3>}, $clusters{$oid}->{description}, $olink;

  my $table = $self->new_table(
    $columns,
    [],
    {
      code              => 1,
      data_table        => 1,
      id                => 'ont_table',
      toggleable        => 0,
      class             => '',
      data_table_config => {iDisplayLength => 10}
    },
  );

  $self->process_data($table, $chart, $clusters{$oid}->{db}, $oid);
  $html .= $table->render;

  return '<p>No ontology terms have been annotated to this entity.</p>' unless @terms;
  return $html;
}

sub ontology_chart {
  my ($self, $chart, $oname, $root) = @_;

  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;
  my $oid          = $hub->param('oid');
  my $go           = $hub->param('go');

  my %clusters = $species_defs->multiX('ONTOLOGIES');

  my $ontology_term_adaptor = $hub->get_databases('go')->{'go'}->get_GOTermAdaptor;

  my $ontovis = EnsEMBL::Web::Document::Image::Ontology->new($hub, undef, {'_ontology_term_adaptor' => $ontology_term_adaptor},);

  my $oMap = EnsEMBL::Web::Constants::ONTOLOGY_SETTINGS;
  my @hss = $oMap->{$oname} ? @{$oMap->{$oname}->{subsets} || []} : ();

  $ontovis->highlighted_subsets(@hss);

  my $subsets = $species_defs->get_config($object->species, 'ONTOLOGY_SUBSETS');
  my $hss = {};
  foreach my $ss (@{$subsets || []}) {
    $hss->{$ss}->{color} = $species_defs->colour('goimage', $ss) || 'grey';
    $hss->{$ss}->{label} = $species_defs->colour('goimage', $ss, 'text') || $ss;
  }

  $ontovis->highlight_subsets($hss);

  my $cmap = {
    'background'    => $species_defs->colour('goimage', 'image_background'),
    'border'        => $species_defs->colour('goimage', 'node_all_border'),
    'selected_node' => $species_defs->colour('goimage', 'node_select_background'),
  };

  foreach my $rel (@{$clusters{$oid}->{relations} || []}) {
    $cmap->{relations}->{$rel} = $species_defs->colour('goimage', $rel) || 'black';
  }

  $ontovis->colours($cmap);

  my $extlinks = $oMap->{$oname} ? $oMap->{$oname}->{extlinks} : {};

  my $bm_filter = $oMap->{$oname} ? $oMap->{$oname}->{biomart_filter} : '';
  if ($bm_filter && $species_defs->GENOMIC_UNIT && $species_defs->GENOMIC_UNIT !~ /bacteria|parasite/) {
    my $vschema = sprintf qq{%s_mart_%s}, $species_defs->GENOMIC_UNIT, $SiteDefs::SITE_RELEASE_VERSION;
    my (@species) = split /_/, $object->species;
    my $attr_prefix = lc(substr($species[0], 0, 1) . $species[1] . "_eg_gene");

    if (my $bds = $species_defs->get_config($self->object->species, 'BIOMART_DATASET')) {
      $attr_prefix = "${bds}_gene";
    }

    my $biomart_link = sprintf qq{/biomart/martview?VIRTUALSCHEMANAME=%s&ATTRIBUTES=%s.default.feature_page.ensembl_gene_id|%s.default.feature_page.ensembl_transcript_id&FILTERS=%s.default.filters.%s.\\"###ID###\\"&VISIBLEPANEL=resultspanel}, $vschema, $attr_prefix, $attr_prefix, $attr_prefix, $bm_filter;
    $extlinks->{'Search BioMart'} = $biomart_link;
    $extlinks->{'Search BioMart'} = $biomart_link;
  }

  $ontovis->node_links($extlinks);

  my $html = $ontovis->render($chart, $root, $go, $self->image_width);
  return $html;
}

sub process_data {
  my ($self, $table, $data_hash, $extdb, $oid) = @_;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species      = $hub->species;
  my $species_path = $hub->species_defs->species_path($species);

  foreach my $go (sort keys %$data_hash) {
    next unless $data_hash->{$go}->{selected};

    my $row = {};
    my $ghash = $data_hash->{$go} || {};

    #      warn Dumper $ghash;
    $ghash->{evidence} = join ' , ', map {$_->[1]} grep {$_->[0] eq 'Evidence'} @{$ghash->{notes} || []};
    $ghash->{source}   = join ' , ', map {$_->[1]} grep {$_->[0] eq 'Source'} @{$ghash->{notes}   || []};

    my $go_link = $hub->get_ExtURL_link($go, $extdb, $go);

    my $info_text_html;
    my $info_text_url;
    my $info_text_gene;
    my $info_text_species;
    my $info_text_common_name;
    my $info_text_type;

    if (my $info_text = $ghash->{'info'}) {

      # create URL
      if ($info_text =~ /from ([a-z]+[ _][a-z]+) (gene|translation) (\S+)/i) {
        $info_text_gene        = $3;
        $info_text_type        = $2;
        $info_text_common_name = ucfirst $1;
      }
      else {
        warn "regex parse failure in EnsEMBL::Web::Component::Gene::go()";    # parse error
      }

      $info_text_species = $species;
      (my $species = $info_text_common_name) =~ s/ /_/g;
      my $type       = $info_text_type eq 'gene'        ? 'Gene'           : 'Transcript';
      my $action     = $info_text_type eq 'translation' ? 'ProteinSummary' : 'Summary';
      my $param_type = $info_text_type eq 'translation' ? 'p'              : substr($info_text_type, 0, 1);

      my $info_text_url = $hub->url(
        {
          species     => $species,
          type        => $type,
          action      => $action,
          $param_type => $info_text_gene,
          __clear     => 1,
        }
      );
      $info_text_html = "[from $info_text_common_name <a href='$info_text_url'>$info_text_gene</a>]";
    }
    else {
      $info_text_html = '';
    }

    my $goslim_goa_acc  = '';
    my $goslim_goa_desc = '';

    my $goslim_goa_hash = $ghash->{goslim} || {};
    foreach (keys %$goslim_goa_hash) {
      $goslim_goa_acc .= $hub->get_ExtURL_link($_, 'GOSLIM_GOA', $_) . "<br/>";
      $goslim_goa_desc .= $goslim_goa_hash->{$_}->{'name'} . "<br/>";
    }

    $row->{'go'}               = $go_link;
    $row->{'description'}      = $ghash->{'name'};
    $row->{'evidence'}         = $ghash->{'evidence'};
    $row->{'source'}           = join ', ', grep {$_} ($info_text_html, $ghash->{source});
    $row->{'goslim_goa_acc'}   = $goslim_goa_acc;
    $row->{'goslim_goa_title'} = $goslim_goa_desc;

    my $url = $hub->url(
      {
        type   => 'Gene',
        action => 'Ontology/' . $oid,
        oid    => $oid,
        go     => $go,
        tab    => 'i'
      }
    );
    $row->{'ancestor_chart'} = "<a href='$url'><img src=\"/img/ontology.png\" title=\"Ancestor chart\" /></a>";

    #EG EOF

    $table->add_row($row);
    foreach my $e (@{$ghash->{'extensions'} || []}) {
      $table->add_row($e);
    }
  }

  return $table;
}

1;
