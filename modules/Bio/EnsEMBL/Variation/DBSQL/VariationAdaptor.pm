package Bio::EnsEMBL::Variation::DBSQL::VariationAdaptor;

#
# Returns all the studies for variation.
# INPUT PARAMS: var_id
# RETURNS: Arrayref of study ids for the current variation id
#

sub get_study_ids_by_var_id {
    my ($self, $var_id) = @_;

    my $study_id;
    my $sth = $self->prepare(qq{
      SELECT study_id 
        FROM study_variation 
        WHERE variation_id = $var_id
    });
    $sth->execute();
    $sth->bind_columns(\$study_id);

    my @sources;
    while ($sth->fetch()){
      push @sources, $study_id
    }
    $sth->finish();
    return \@sources;
}

1;
