package EnsEMBL::Web::Component::Gene::SimilarityMatches;

use strict;

# remove after merge of https://github.com/Ensembl/ensembl-webcode/pull/458

sub get_matches_by_transcript {
  my $self          = shift;
  my $transcript    = shift;
  my @dbtypes         = @_;
  my @db_links;

  foreach (@dbtypes) {
    push @db_links, @{ $transcript->get_all_DBLinks(undef, $_) };
  }

  $_->{'transcript'} = $transcript for @db_links;
  
  return @db_links;
}

1;