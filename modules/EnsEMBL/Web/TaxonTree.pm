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

package EnsEMBL::Web::TaxonTree;

# Minimal taxon tree implementation, based on Ensembl::Web::Tree

use base qw(EnsEMBL::Web::DOM::Node::Element::Generic);
use Data::Dumper;
use JSON;

sub new {
  my ($class, $dom, $args) = @_;
  my $self = $class->SUPER::new($dom);
  
  $self->{'id'}              = 'aaaa'; # taxon id
  $self->{'production_name'} = '';
  $self->{'display_name'}    = '';
  $self->{'is_species'}      = 0;
  $self->{'tree_ids'}        = {}; # A complete list of unique identifiers in the tree, and their nodes
  $self->{$_}                = $args->{$_} for keys %{$args || {}}; # Overwrites the values above
  
  $self->{'tree_ids'}{$self->{'id'}} = $self;
  
  return $self;
}

sub id              { return $_[0]->{'id'} }
sub taxon_id        { return $_[0]->{'taxon_id'} }
sub production_name { return $_[0]->{'production_name'} }
sub display_name    { return $_[0]->{'display_name'} }
sub is_species      { return $_[0]->{'is_species'} }
sub tree_ids        { return $_[0]->{'tree_ids'} }
sub is_leaf         { return !$_[0]->has_child_nodes }

sub get_node {
  my ($self, $id) = @_;
  return $self->tree_ids->{$id};
}

sub create_node {
  ### Node is always created as a "root" node - needs to be appended to another node to make it part of another tree.
  my ($self, $args) = @_;
  return $self->get_node($args->{id}) if (exists $self->tree_ids->{$args->{id}});
  $args->{tree_ids} = $self->tree_ids;
  return EnsEMBL::Web::TaxonTree->new($self->dom, $args);
}

sub get_species {
  my $self = shift;
  my @nodes;
  push @nodes, $self if $self->is_leaf && $self->is_species && @_ && shift;
  push @nodes, $_->get_species(1) for @{$self->child_nodes};
  return @nodes;
}

sub species_count {
  my $self = shift;
  my @leaves = $self->get_species;
  return scalar @leaves;
}

sub prune {
  my ($self, $keep_species) = @_;
  foreach my $n (@{$self->child_nodes}) {       
    if ($n->is_leaf && !$keep_species->{$n->production_name}) {
      $n->remove;
    } else {
      $n->prune($keep_species);
    }
  } 
}

sub collapse {
  my ($self) = @_;
  foreach my $n (@{$self->child_nodes}) {
    if ($n->get_species) {
      $n->collapse;
    } elsif (!$n->is_species) {
      $n->remove;
    }
  } 
}

sub to_dynatree_js_variable {
  my ($self, $varname, $selectedKeys) = @_;
  $varname ||= 'taxonTreeData';  
  $selectedKeys ||= [];
  my %selectedKeyHash = map {$_ => 1} @$selectedKeys;
  my ($root) = @{$self->child_nodes};  
  my $json = to_json($root->_to_dynatree(\%selectedKeyHash), {pretty => 1});
  return "$varname = \n$json;\n"; 
}

sub _to_dynatree {
  my ($self, $selectedKeyHash) = @_;
  
  # JSON NOTE: \"1" and \"0" convert to javascript true and false
  
  my @children;
  push @children, $_->_to_dynatree($selectedKeyHash) for (@{$self->child_nodes});
   
  my $has_selected_child;
  foreach my $child (@children) {
    if ($child->{select} or $child->{expand}) {
      $has_selected_child = 1;
      last;
    }
  }
  
  my $hashref = {
    key   => $self->production_name,
    title => $self->display_name . ($self->is_species ? '' : " (" . $self->species_count . ")"),
  };
  $hashref->{children} = \@children if @children;
  $hashref->{isFolder} = \"1"       if @children;
  $hashref->{select}   = \"1"       if $selectedKeyHash->{$self->production_name};
  $hashref->{expand}   = \"1"       if $has_selected_child;

  return $hashref;
}

sub dump {
  my ($self, $depth) = @_;
  foreach my $n (@{$self->child_nodes}) {
    print " " x $depth;
    print $n->display_name;# . " [" . $n->id . "]";
    if (!$n->is_species) {
      print " (" . $n->species_count . ")";
    } 
    print "\n";    
    $n->dump($depth + 1);
  }
}

1;
