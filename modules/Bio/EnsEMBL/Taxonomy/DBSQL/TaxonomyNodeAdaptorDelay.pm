package Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptorDelay;

use Time::HiRes qw(usleep);

=head2 fetch_by_coredbadaptors

Description : Fetch an array of nodes corresponding to the taxonomy IDs found in the supplied Ensembl DBAdaptors.
Argument    : Bio::EnsEMBL::Taxonomy::DBSQL::DBAdaptor
Return type : Arrayref of Bio::EnsEMBL::Taxonomy::TaxonomyNode
=cut

*Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptor::fetch_by_coredbadaptors = sub {
  my ($self, $core_dbas) = @_;
  my $nodes_by_taxa = {};
  for my $core_dba (@$core_dbas) {
        usleep(10000);
        my $taxid = $core_dba->get_MetaContainer()->get_taxonomy_id();
        if (!defined $taxid) {
	  throw("Could not find taxonomy ID for database " .
			$core_dba->species());
	}
	my $node = $nodes_by_taxa->{$taxid};
	if (!defined $node) {
	  $node = $self->fetch_by_taxon_id($taxid);
	  if (!defined $node) {
		warn "Could not find taxonomy node for " .
		  $core_dba->species() . " with taxonomy ID $taxid";
	  }
	  else {
		$nodes_by_taxa->{$taxid} = $node;
	  }
	}
	if (defined $node) {
	  push @{$node->dba()}, $core_dba;
	}
	$core_dba->dbc()->disconnect_if_idle();
  }
  return [values(%$nodes_by_taxa)];
}; ## end sub fetch_by_coredbadaptors



1;

