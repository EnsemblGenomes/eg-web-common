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

# $Id: Genome.pm,v 1.12 2014-01-15 10:36:13 jh15 Exp $

package EnsEMBL::Web::Component::Location::Genome;

use EnsEMBL::Web::Data::Bio::Gene;
use List::MoreUtils qw/ uniq /;

sub _configure_Gene_table {
  my ($self, $feature_type, $feature_set) = @_;
  my $rows = [];
 
  my $header = 'Gene Information';
  my $count  = scalar @{$feature_set->[0]};
  if ($self->hub->param('ftype') eq 'Domain') {
    ## Override default header
    my $domain_id = $self->hub->param('id');
    my $plural    = $count > 1 ? 'genes' : 'gene';
    $header       = "Domain $domain_id maps to $count $plural:";
  } elsif ( !( scalar ($self->hub->species_defs->ENSEMBL_CHROMOSOMES || []) && $self->hub->species_defs->MAX_CHR_LENGTH ) ) {
    ## No karyotype image
    my ( $go_link );
    my $id = $self->hub->param('id');
     
    #add extra description only for GO (gene ontologies) which is determined by param gotype in url
    my $go = $self->hub->param('gotype');
    if ( $go ) {
      my $adaptor = $self->hub->get_databases('go')->{'go'}->get_OntologyTermAdaptor;
      my $go_hash = $adaptor->fetch_by_accession($id);
      my $go_name = $go_hash->{name};
      $go_link    = $self->hub->get_ExtURL_link($id, $go, $id)." ".$go_name; #get_ExtURL_link will return a text if $go is not valid
    }
 
    my $assoc_name = $self->hub->param('name');
    unless ( $assoc_name ) {
      $assoc_name .= $go_link ? $go_link : $id;
    }
 
    if ( $assoc_name ) {
      my $plural = $count > 1 ? 'Genes' : 'Gene';
      $header = "$plural associated with $assoc_name";
    }
  }

  my $column_order = [qw(names loc extname)];

  my ($data, $extras) = @$feature_set;
  foreach my $feature ($self->_sort_features_by_coords($data)) {
    my $row = {
	  'extname' => {'value' => $feature->{'extname'}},
	  'names'   => {'value' => $self->_names_link($feature, $feature_type)},
	  'loc'     => {'value' => $self->_location_link($feature)},
    };
    $self->add_extras($row, $feature, $extras);
    push @$rows, $row;
  }
  # EG:
  return {'header' => $header, 'column_order' => $column_order, 'rows' => $rows, 'table_style' => {data_table_config => {iDisplayLength => 25}}} if $self->hub->param('ftype') eq 'Domain';
  # EG
}

sub content {
  my $self = shift;
  my $id   = $self->hub->param('id'); 
  my $features = {};

  my $html;
  my $chromosomes  = $self->hub->species_defs->ENSEMBL_CHROMOSOMES || [];
  if (!scalar @$chromosomes) {
    $html = $self->_info('Unassembled genome', '<p>This genome has yet to be assembled into chromosomes</p>');
  }

  #configure two Vega tracks in one
  my $config = $self->hub->get_imageconfig('Vkaryotype');
  if ($config->get_node('Vannotation_status_left') & $config->get_node('Vannotation_status_right')) {
    $config->get_node('Vannotation_status_left')->set('display', $config->get_node('Vannotation_status_right')->get('display'));
  }

  # if ($self->hub->param('ftype') eq 'Gene') {
  #   my $dba = Bio::EnsEMBL::Registry->get_DBAdaptor( $self->hub->species, 'core' ) || die("Can't connect to database");
  #   my $sa = $dba->get_SliceAdaptor();

  #   my $obs;
  #   my %attr_types;

  #   foreach my $chr (@$chromosomes) {
  #     my $slice = $sa->fetch_by_region( 'chromosome', $chr );

  #     # get some attributes of the slice
  #     foreach my $gene ( @{ $slice->get_all_Genes } ) {
  #       my $attr = $gene->get_all_Attributes('PHIbase_mutant');
        
  #       if (@$attr > 0) {  
  #         my @values = grep { $_ && $_->value() ne 'unaffected_pathogenicity'} @$attr;
  #         if (scalar @values > 0) {
  #           $attr_types{$gene->stable_id} = $values[0]->{'value'};
  #           push @$obs, $gene;
  #         }
  #       }
  #     }

  #     my $genes = EnsEMBL::Web::Data::Bio::Gene->new($self->hub, @$obs);
  #     my $features = $genes->convert_to_drawing_parameters;
  #     my $extra_columns = [{'key' => 'description', 'title' => 'Description'}];

  #     $html = $self->_render_genes($features, $config, \%attr_types);
  #   }
  # } else {
    if ($id) {
      my $object = $self->builder->create_objects('Feature', 'lazy');
      if ($object && $object->can('convert_to_drawing_parameters')) {
        $features = $object->convert_to_drawing_parameters;
      }
    }
    $html = $self->_render_features($id, $features, $config);
  # }

  return $html;
}

1;
