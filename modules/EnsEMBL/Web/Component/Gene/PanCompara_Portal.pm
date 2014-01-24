package EnsEMBL::Web::Component::Gene::PanCompara_Portal;

use base qw(EnsEMBL::Web::Component::Portal);
use strict;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $availability = $self->object->availability;
  my $location     = $hub->url({ type => 'Location',  action => 'Compara' });

  $self->{'buttons'} = [
    { title => 'Gene tree',          img => 'compara_tree',  url => $availability->{'has_gene_tree_pan'}  ? $hub->url({ action => 'Compara_Tree/pan_compara'       }) : '' },
    { title => 'Orthologues',        img => 'pan_compara_ortho', url => $availability->{'has_orthologs_pan'}  ? $hub->url({ action => 'Compara_Ortholog/pan_compara'   }) : '' },
  ];

  my $html  = $self->SUPER::content;

  $html .= qq{<p><a target="_blank" href="http://ensemblgenomes.org/info/species?pan_compara=1">Species list</a> (will open in a new window)</p>};
  $html .= qq{<p>More views of comparative genomics data, such as multiple alignments and synteny, are available on the <a href="$location">Location</a> page for this gene.</p>};

  return $html;
}

1;
