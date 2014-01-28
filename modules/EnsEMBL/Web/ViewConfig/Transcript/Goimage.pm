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

package EnsEMBL::Web::ViewConfig::Transcript::Goimage;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);
use Data::Dumper;
use URI::Escape qw(uri_escape uri_unescape);

my @core_relations = qw(is_a part_of);

sub get_ontology_id {
  my $self       = shift;

# First we need to get the id of the current ontology
  my $referer      = $self->hub->referer;
  my $params       = $referer->{'params'};
  unless ($params) {
      my ($url, $query_string) = split /\?/, $referer->{absolute_url};
      my @pairs  = split /[&;]/, $query_string;

      foreach (@pairs) {
	  my ($param, $value) = split '=', $_, 2;
	  
	  next unless defined $param;
	  
	  $value = '' unless defined $value;
	  $param = uri_unescape($param);
	  $value = uri_unescape($value);
	  
	  push @{$params->{$param}}, $value unless $param eq 'time'; # don't copy time
      }
  }
  my $oid = $params->{oid} ? $params->{oid}->[0] : 0;
  return $oid;
}

sub init {
  my $self       = shift;

  my $oid = $self->get_ontology_id;

  my %clusters = $self->species_defs->multiX('ONTOLOGIES');
  my %rhash = map {$_ => 0} @{$clusters{$oid}->{relations} || []};
  foreach (@core_relations) {$rhash{$_} = 1};

  my $defaults   = {};
  foreach (keys %rhash) {
      my $name = 'opt_' . lc $_;
      $name    =~ s/\s+/_/g;
      $defaults->{$name} = $rhash{$_} ? 'on' : 'off';
  }
  
  $self->set_defaults($defaults);
  $self->title = 'Ontology graph';
}

sub form {
  my $self       = shift;
  my $hub        = $self->hub;
  
  # Add type selection

  
  my %clusters = $self->species_defs->multiX('ONTOLOGIES');
  my $oid = $self->get_ontology_id;

  my %rhash = map {$_ => 1} @{$clusters{$oid}->{relations} || []};
  foreach (@core_relations) {$rhash{$_} = 0};

  my $fs = $self->add_fieldset('Relations');
  $fs->add_notes({'text' => "<b>is_a</b> and <b>part_of</b> relations define the graph and can not be turned off."});
  if (my @rels =  sort { $a cmp $b } grep { $rhash{$_} } keys %rhash) {
      foreach (@rels) {
	  $self->add_form_element({
	      type  => 'CheckBox',
	      label => $_,
	      name  => 'opt_'.lc($_),
	      value => $rhash{$_} ? 'on' : '',
	      raw   => 1
	      });
      }
  } else {
      $fs->add_notes({'text' => "There are no extra relations in this ontology beside <b>is_a</b> and <b>part_of</b>."});
  }
}


1;
