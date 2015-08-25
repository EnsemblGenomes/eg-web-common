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

# $Id: Transcript.pm,v 1.27 2014-01-15 10:36:13 jh15 Exp $

package EnsEMBL::Web::Configuration::Transcript;

use strict;
use Data::Dumper;

use base qw(EnsEMBL::Web::Configuration);

# either - prediction transcript or transcript
# domain - domain only (no transcript)
# history - IDHistory object or transcript
# database:variation - Variation database

sub modify_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $object = $self->object;
  my $species_defs = $hub->species_defs;
  my $protein_variations = $self->get_node('ProtVariations');  
  
  # Zoomable variation image

  # $var_menu->append($self->create_node('Variation_Transcript/Image', 'Variation image',
  #   [qw( variationimage EnsEMBL::Web::Component::Transcript::VariationImage )],
  #   { 'availability' => 'transcript database:variation core' }
  # ));

  my $variation_image = $self->get_node('Variation_Transcript/Image');
  
  $variation_image->set('components', [qw( 
    imagetop EnsEMBL::Web::Component::Transcript::VariationImageTop
    imagenav EnsEMBL::Web::Component::Transcript::VariationImageNav
    image EnsEMBL::Web::Component::Transcript::VariationImage 
  )]);
  
  $variation_image->set('availability', 'transcript database:variation core');

  # Ontology

  my $go_menu = $self->get_node('GO');
  $self->delete_node('Ontology/Image');
  $self->delete_node('Ontology/Table');

  # get all ontologies mapped to this species
  my %olist = map {$_ => 1} @{$species_defs->DISPLAY_ONTOLOGIES ||[]};

  if (%olist) {


     # get all ontologies available in the ontology db
     my %clusters = $species_defs->multiX('ONTOLOGIES');

     # get all the clusters that can generate a graph
     my @clist =  grep { $olist{ $clusters{$_}->{db} }} sort {$clusters{$a}->{db} cmp $clusters{$b}->{db}} keys %clusters; # Find if this ontology has been loaded into ontology db

     foreach my $oid (@clist) {
	 my $cluster = $clusters{$oid};
	 my $dbname = $cluster->{db};

# special case: there are many ontologies loaded into PBO - we only want to display gene_ex
	 if ($dbname eq 'PBO') {
	     next unless $oid eq 'gene_ex';
	 }


	 my $go_hash  = $self->object ? $object->get_ontology_chart($dbname, $cluster->{root}) : {};
	 next unless (%$go_hash);
	 my @c = grep { $go_hash->{$_}->{selected} } keys %$go_hash;
	 my $num = scalar(@c);
	 
	 my $url2 = $hub->url({
	     type    => 'Transcript',
	     action  => 'Ontology/'.$oid,
	     oid     => $oid
			      });

	 (my $desc2 = "$cluster->{db}: $cluster->{description}") =~ s/_/ /g;
	 $go_menu->append($self->create_node('Ontology/'.$oid, "$desc2 ($num)",
					     [qw( go EnsEMBL::Web::Component::Transcript::Ontology )],
					     { 'availability' => 'transcript', 'concise' => $desc2, 'url' =>  $url2 }
			  ));
	 
     }
  }
  
# EG:ENSEMBL-2785 add this new URL so that the Transcript info appears at the top of the page for the Karyotype display with Locations tables
  my $sim_node = $self->get_node('Similarity');
  $sim_node->append($self->create_subnode('Similarity/Locations', '',
    [qw(
       genome  EnsEMBL::Web::Component::Location::Genome
    ) ],
    {  'availability' => 'transcript', 'no_menu_entry' => 1 }
  ));
# EG:ENSEMBL-2785 end
  
}


1;

