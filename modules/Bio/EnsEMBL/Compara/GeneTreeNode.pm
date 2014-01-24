package Bio::EnsEMBL::Compara::GeneTreeNode;

#EG: history_warn method
=head2 history_warn

  Arg[1]     : [optional] string
  Example    : $tree->history_warn("The former Gene Tree EBGT00070000031985 has been replaced by Gene Tree EBGT00650000039016 (below).");
  Description: getter/setter for the warning msg; warning message is added to the top of the page to let the user know if an old GeneTree stable_ids is mapped to new GeneTree stable_ids
  Returntype : string

=cut

sub history_warn {
    my ($self, $history_warn) = @_;

    if (defined($history_warn)) {
	$self->{history_warn} = $history_warn;
    }
    return $self->{history_warn};
}


1;

