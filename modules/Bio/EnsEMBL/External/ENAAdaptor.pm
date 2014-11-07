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


=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=cut

package Bio::EnsEMBL::External::ENAAdaptor;

use strict;
use DBI;
use Data::Dumper qw( Dumper );
use Time::Local;

use vars qw(@ISA);

use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::DBSQL::DBConnection;

@ISA = qw( Bio::EnsEMBL::DBSQL::BaseAdaptor );
#@ISA = qw( Bio::EnsEMBL::DBSQL::DBAdaptor );

## EG
# Make compatible with with Bio::Root::Storable non-binary mode

#=head2 new
# 
#  Arg [1]   :
#  Function  :
#  Returntype:
#  Exceptions:
#  Caller    :
#  Example   :
# 
#=cut
#                                                                           
#
sub new {
  my $caller = shift;
#warn "DB - @_";
  my $connection = Bio::EnsEMBL::DBSQL::DBConnection->new(@_);
  my $self = $caller->SUPER::new($connection);
  $self->{'disconnect_flag'} = 1;
  return $self;
}
 

#----------------------------------------------------------------------

sub species {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_species} = $arg );
  $self->{_species};
}

#----------------------------------------------------------------------

=head2 ticket

  Arg [1]   : string ticket (optional)
  Function  : Get/get the blast ticket attribute
  Returntype: string ticket
  Exceptions: 
  Caller    : 
  Example   : 

=cut

sub ticket{
  my $key = "_ticket";
  my $self = shift;
  if( @_ ){ $self->{$key} = shift }
  return $self->{$key};
}



# -----------------------------------------------------------------------
# Functions needed for Sequence Search functionality
sub create_job {
  my ($self, $ticket) = @_;
  my $sql = qq( INSERT INTO journal SET job_id='$ticket', create_time=CURRENT_TIMESTAMP );
#  warn "$sql";
  my $sth = $self->prepare($sql);
  my $result = $sth->execute();
  return $result;
#  warn "$result";
#  return $self->last_inserted_id($result);
}

sub update_status {
  my ($self, $ticket, $status) = @_;
  my $sql = qq( UPDATE journal SET status = '$status' WHERE job_id = '$ticket' );
#  warn "$sql";
  my $sth = $self->prepare($sql);
  my $result = $sth->execute();
  return $result;
}

sub update_progress {
  my ($self, $ticket, $progress) = @_;
  my $sql = qq( UPDATE journal SET progress = '$progress' WHERE job_id = '$ticket' );
#  warn "$sql";
  my $sth = $self->prepare($sql);
  my $result = $sth->execute();
  return $result;
}

sub store_alignments {
  my ($self, $ticket, $result) = @_;

  my $sql = qq(
    INSERT INTO alignment SET
     job_id= ?, source = ?, species = ?, qset = ?, location = ?, qstart = ?, qend = ?, identity = ?, evalue = ?, result = ?, region =? , tstart = ?, tend =? 
  );
#  warn "$sql";
  my $sth = $self->prepare($sql);



  foreach my $a (@$result) {
    $sth->execute($ticket, $a->{DataSource}, $a->{Species}, $a->{QuerySetName}, $a->{Location}, $a->{queryStart}, $a->{queryEnd},  $a->{Identity}, $a->{EValue}, $a->{Description}, $a->{Accession}, $a->{targetStart}, $a->{targetEnd} );
  }

  
  return;
}

sub fetch_alignments {
  my ($self, $ticket, $column, $order, $from, $size) = @_;

  my $sql = qq( SELECT (a.qend-a.qstart+1) as qlen, abs(a.tend-a.tstart) + 1 as tlen, a.* 
 FROM alignment a WHERE job_id = ? );

  if ($column) {
      $sql .= qq{ ORDER BY $column $order };
  } else {
      $sql .= qq{ ORDER BY evalue, identity DESC };
  }
  if ($size) {
      $sql .= qq{ LIMIT $from, $size };
  }
#  warn "SQL:$sql ($ticket) \n";

  my $sth = $self->prepare($sql);
  $sth->execute($ticket);

  return  $sth->fetchall_arrayref();
}

sub fetch_state {
  my ($self, $ticket) = @_;

  my $sql = qq( SELECT * FROM journal WHERE job_id = ? );
#  warn "SQL:$sql\n";
  my $sth = $self->prepare($sql);
  $sth->execute($ticket);

  return  $sth->fetchall_arrayref();

}

sub update_state {
  my ($self, $ticket, $status, $progress) = @_;

  my $sql = qq{ SELECT count(*) FROM alignment WHERE job_id = ? };
  my $sth = $self->prepare($sql);
  $sth->execute($ticket);
  my ($counter) = $sth->fetchrow_array;
  $sth->finish;

  $sql = qq( UPDATE journal SET status = ?, progress = ?, counter = ? WHERE job_id = ?);
#  warn "$sql";
  my $sth = $self->prepare($sql);
  my $result = $sth->execute($status, $progress, $counter, $ticket);
  return $result;
}


1;
