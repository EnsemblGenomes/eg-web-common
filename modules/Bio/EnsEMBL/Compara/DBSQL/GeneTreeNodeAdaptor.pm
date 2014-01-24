package Bio::EnsEMBL::Compara::DBSQL::GeneTreeNodeAdaptor;

###########################
# stable_id mapping
###########################


=head2 fetch_by_stable_id

  Arg[1]     : string $protein_tree_stable_id
  Example    : $protein_tree = $proteintree_adaptor->fetch_by_stable_id("ENSGT00590000083078");

  Description: Fetches from the database the protein_tree for that stable ID
  Returntype : Bio::EnsEMBL::Compara::GeneTreeNode
  Exceptions : returns undef if $stable_id is not found.
  Caller     :

=cut

sub fetch_by_stable_id {
  my ($self, $stable_id) = @_;

  my $sql = qq(SELECT root_id FROM gene_tree_root WHERE stable_id=? LIMIT 1);
  my $sth = $self->prepare($sql);
  $sth->execute($stable_id);

  my ($root_id) = $sth->fetchrow_array();

  #EG: warning message is added to let the user know if an old GeneTree stable_ids is mapped to new GeneTree stable_ids
  my $history_msg = 0;
  unless($root_id) {
      my $sql_0 = qq(SELECT stable_id_to, contribution FROM stable_id_history WHERE stable_id_from=?);
      my $sth_0 = $self->prepare($sql_0);
      $sth_0->execute($stable_id);
      my ($stable_id_to, $contribution) = $sth_0->fetchrow_array();

      return undef unless (defined $stable_id_to);

      my $sql = qq(SELECT root_id FROM gene_tree_root WHERE stable_id=? LIMIT 1);
      my $sth = $self->prepare($sql);
      $sth->execute($stable_id_to);
      ($root_id) = $sth->fetchrow_array();
      $history_msg = "The former Gene Tree $stable_id has been replaced by Gene Tree $stable_id_to (below).</br>$stable_id contributes $contribution percent of it's members to $stable_id_to.";
  }
  #EG

  return undef unless (defined $root_id);

  my $protein_tree = $self->fetch_node_by_node_id($root_id);

  #EG:
  $protein_tree->history_warn($history_msg) if $history_msg;
  #EG

  return $protein_tree;
}

#EG: history_check method
=head2 history_warn

  Arg[1]     : string $protein_tree_stable_id
  Example    : $msg = $proteintree_adaptor->history_check("ENSGT00590000083078");
  Description: a warning message is returned in the cases where the stable_id has been retired and does not have a replacement
  Returntype : string

=cut

sub history_check {

    my ($self, $stable_id) = @_;
   
    #The former Gene Tree $stable_id has been retired, and does not have a replacement:
    my $sql_0 = qq(SELECT contribution FROM stable_id_history WHERE stable_id_from=? and stable_id_to = '');
    my $sth_0 = $self->prepare($sql_0);
    $sth_0->execute($stable_id);
    my ($contribution) = $sth_0->fetchrow_array();

    return undef unless (defined $contribution);

    $history_msg = "The former Gene Tree $stable_id has been retired, and does not have a replacement. You can <a href='/Search/'>search for genes</a> of interest.";  

    return $history_msg;
}


1;
