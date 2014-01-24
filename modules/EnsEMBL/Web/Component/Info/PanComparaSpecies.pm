# $ Id $
# Remember to update htdocs/ssi/species/pan_compara_species.xml by running this command:
# eg-plugins/common/utils/drupal_import_species.pl -pan

package EnsEMBL::Web::Component::Info::PanComparaSpecies;

use strict;

use EnsEMBL::Web::Controller::SSI;
use XML::Simple;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  my $file = '/ssi/species/pan_compara_species.xml';
  my $xmldoc = EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file);
  return '' unless $xmldoc;
  my $xml = XMLin($xmldoc);
  my @rows;
  foreach my $species (keys %{$xml->{'node'}}){
    my $div = $xml->{'node'}->{$species}->{'division'};
    my $tax = $xml->{'node'}->{$species}->{'taxonomy'};
    my $db_name = $xml->{'node'}->{$species}->{'db_name'};
    my $data = {
      species => $self->hub->get_ExtURL_link($species, uc($div),{'SPECIES' => $db_name}),
      division => $self->hub->get_ExtURL_link($div, uc($div),  {'SPECIES' => 'index.html'}),
      taxonomy => $self->hub->get_ExtURL_link($tax, 'UNIPROT_TAXONOMY', $tax),
    };
    push(@rows, $data);
  }
  my $table = $self->new_table(
    [
      {key=>'species',title=>'Species', sort=>'html'},
      {key=>'division',title=>'Division', sort=>'html'},
      {key=>'taxonomy',title=>'Taxonomy ID', sort=>'html'}
    ],
    \@rows,
    {
      code=>1,data_table=>1,id=>'pan_species_table',toggleable=>0,sorting=>['species asc'],
      class=>sprintf('no_col_toggle %s'),
      data_table_config=>{iDisplayLength=>25},
    },
  );
  return sprintf(qq{<div id="PanComparaSpecies" class="js_panel"><input type="hidden" class="panel_type" value="Content"/>%s</div>},$table->render);
}

1;
