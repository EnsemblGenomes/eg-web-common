package Bio::EnsEMBL::ExternalData::VCF::VCFAdaptor;
use strict;


sub new {
  my ($class, $url) = @_;
  my $self = bless {
    _cache => {},
    _url => $url,
  }, $class;

  my @out = `tabix -l $url`;
  if ( $? ) {
      $self->{_error} = "ERROR: Failed to open $url and its index";
      die $self->{_error};
  }

  return $self;
}

1;
