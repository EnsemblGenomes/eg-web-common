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

package EnsEMBL::Web::DASConfig;

use strict;

use Bio::EnsEMBL::ExternalData::DAS::CoordSystem;
use Bio::EnsEMBL::ExternalData::DAS::SourceParser qw(%GENE_COORDS %PROT_COORDS %SNP_COORDS is_genomic);

# Create a new SourceConfig using a hash reference for parameters.
# Can also use an existing Bio::EnsEMBL::ExternalData::DAS::Source or
# EnsEMBL::Web::DASConfig object.
# Hash should contain:
#   url
#   dsn
#   coords
#   logic_name    (optional, defaults to dsn)
#   label         (optional)
#   caption       (optinal short label)
#   description   (optional)
#   homepage      (optional)
#   maintainer    (optional)
#   on            (views enabled on)
#   category      (menu location)
#   renderer      (optional module name eg. 'S4DAS')

sub new_from_hashref {
  my ( $class, $hash ) = @_;
  
  $hash->{'coords'} = [ map {
    ref $_ ? Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new_from_hashref($_)
           : Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new_from_string($_)
  } @{$hash->{'coords'}||[]} ];

  # Convert old-style type & assembly parameters to single coords
  if (my $type = $hash->{type}) {
    my $c = $GENE_COORDS{$type} || $PROT_COORDS{$type} || $SNP_COORDS{$type};
    if ( $c ) {
      push @{ $hash->{coords} }, $c;
    } else {
      $type =~ s/^ensembl_location_//;
      push @{ $hash->{coords} }, Bio::EnsEMBL::ExternalData::DAS::CoordSystem->new(
        -name    => $type,
        -version => $hash->{assembly},
        -species => $ENV{ENSEMBL_SPECIES},
      );
    }
  }
  
  # Create a Bio::EnsEMBL::ExternalData::DAS::Source object to wrap
  # Valid params: url, dsn, coords, logic_name, label, description, homepage, maintainer
  my %params = map { '-'.uc $_ => $hash->{$_} } keys %{ $hash };
  my $self   = $class->SUPER::new( %params );
  
  bless $self, $class;
  
  # Map "old style" view names to the new:
  my %views = ( geneview   => 'Gene/ExternalData',
## EG @ protview has been resurrected to allow DAS tracks on protein summary
#                protview   => 'Transcript/ExternalData',
## EG
                contigview => 'contigviewbottom');
  if ($hash->{enable} || $hash->{on}) {
    $hash->{on} = [ map { $views{$_} || $_ } @{$hash->{on}||[]},@{$hash->{enable}||[]} ] ;
  }
  
  for my $var ( qw( on category caption renderer )  ) {
    if ( exists $hash->{$var} ) {
      $self->$var( $hash->{$var} );
    }
  }
  
  return $self;
}

=head2 renderer

  Arg [1]    : $rendrer (scalar) (eg. 'TextDAS')
  Description: Get/Setter for the source renderer
  Returntype : scalar
  Status     : test

=cut
sub renderer {
  my $self = shift;
  if ( @_ ) {
    $self->{renderer} = shift;
  }
  return $self->{renderer};
}

sub _guess_views {
  my ( $self ) = @_;
  
  my $positional    = 0;
  my $nonpositional = 0;
  my $snp = 0;

  for my $cs (@{ $self->coord_systems() }) {
    # assume genomic coordinate systems are always positional
    if ( is_genomic($cs) || $cs->name eq 'toplevel' ) {
      $positional = 1;
    }
    # assume gene coordinate systems are always non-positional
    elsif ( $GENE_COORDS{ $cs->name } ) {
      $nonpositional = 1;
    }
    elsif ( $SNP_COORDS{ $cs->name } ) {
      $snp = 1;
    } else {
      $positional = 1;
      $nonpositional = 1;
    }
  }
  my @views = ();

## EG @ added protview
  push @views, qw(
    cytoview
    contigviewtop
    contigviewbottom
    gene_summary
    protview
  ) if $positional;
## EG

  push @views, qw(
    Gene/ExternalData
    Transcript/ExternalData
  ) if $nonpositional;

  push @views, qw(
    Variation/ExternalData
  ) if $snp;
  
  return \@views;
}
1;
