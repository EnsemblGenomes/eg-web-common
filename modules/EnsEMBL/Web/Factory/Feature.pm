package EnsEMBL::Web::Factory::Feature;

use strict;
use warnings;
no warnings 'uninitialized';

sub _create_Gene {
  ### Fetches all the genes for a given identifier (usually only one, but could be multiple
  ### Args: db
  ### Returns: hashref containing a Data::Bio::Gene object
  
  my ($self, $db) = @_;
## EG
  #my $genes       = $self->_generic_create('Gene', $self->param('id') =~ /^ENS/ ? 'fetch_by_stable_id' : 'fetch_all_by_external_name', $db);
  my $genes;
  eval { $genes = $self->_generic_create('Gene', 'fetch_by_stable_id', $db) };
  eval { $genes = $self->_generic_create('Gene', 'fetch_all_by_external_name', $db) } if !$genes;
 
  return { Gene => EnsEMBL::Web::Data::Bio::Gene->new($self->hub, @{$genes || []}) };
## 
}

1;
