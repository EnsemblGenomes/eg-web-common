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
  return {'header' => $header, 'column_order' => $column_order, 'rows' => $rows}; 
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

# sub _render_genes {
#   my ($self, $features, $image_config, $attr_types) = @_;

#   my $hub          = $self->hub;
#   my $species      = $hub->species;
#   my $species_defs = $hub->species_defs;
#   my $chromosomes  = $species_defs->ENSEMBL_CHROMOSOMES || [];

#   my @uniq_features =  uniq (sort values %$attr_types);
#   my @uniq_features_uc = map { local $_ = $_; s/_/ /g; ucfirst $_ } @uniq_features;


#   ## Attach the colorizing key before making the image
#   my $chr_colour_key = $self->chr_colour_key;
  
#   $image_config->set_parameter('chr_colour_key', $chr_colour_key) if $image_config;

#   my $html;
#   my $colours = $species_defs->colour('gene');

#   ## Draw features on karyotype, if any
#   if (scalar @$chromosomes && $species_defs->MAX_CHR_LENGTH) {
#     my $image = $self->new_karyotype_image($image_config);
    
#     ## Create pointers to be drawn
#     my $pointers = [];
#     my ($legend_info, $has_gradient);

#     if (scalar @{$features->[0]}) {
#       ## Title for image
#       my $title= 'Location';
#       $title .= ' of ' if @uniq_features_uc;

#       my $last_name = pop(@uniq_features_uc);
#       if (scalar @uniq_features_uc > 0) {
#         $title .= join ', ', @uniq_features_uc;
#         $title .= ' and ';
#       }
#       $title .= $last_name;

#       $html .= "<h3>$title</h3>" if $title;        

#       foreach my $feature (@{$features->[0]}) {
#         my $defaults    = $self->pointer_default('Gene');

#         my $at = $attr_types->{$feature->{label}};
#         my $colour      = $colours->{$at}->{default} || $defaults->[1];
#         my $gradient    = $defaults->[2];
#         my $pointer_ref = $image->add_pointers($hub, {
#           config_name  => 'Vkaryotype',
#           features     => [$feature],
#           feature_type => $feature->{label},
#           color        => $colour,
#           style        => $hub->param('style')  || $defaults->[0],            
#           gradient     => $gradient,
#         });

#         my $name = $attr_types->{$feature->{label}};
#         $legend_info->{$name} = {'colour' => $colour, 'gradient' => $gradient};  
#         push @$pointers, $pointer_ref;
#         $has_gradient++ if $gradient;
#       }
#     }

#     $image->image_name = @$pointers ? "feature-$species" : "karyotype-$species";
#     $image->imagemap   = @$pointers ? 'yes' : 'no';
      
#     $image->set_button('drag', 'title' => 'Click on a chromosome');
#     $image->caption  = 'Click on the image above to jump to a chromosome, or click and drag to select a region';
#     $image->imagemap = 'yes';
#     $image->karyotype($hub, $self->object, $pointers, 'Vkaryotype');
      
#     return if $self->_export_image($image,'no_text');
      
#     $html .= $image->render;
#     $html .= $self->get_chr_legend($chr_colour_key);

#     ## Add colour key if required
#     if ($self->html_format && (scalar(keys %$legend_info) > 1 || $has_gradient)) { 
#       $html .= '<h3>Key</h3>';

#       my $columns = [
#         {'key' => 'ftype',  'title' => 'Feature type'},
#         {'key' => 'colour', 'title' => 'Colour'},
#       ];

#       my $rows;

#       foreach my $type (sort keys %$legend_info) {
#         my $type_name = $type;
#         $type_name =~ s/_/ /g;
#         my $colour = $hub->colourmap->hex_by_name($legend_info->{$type}{'colour'});

#         my @gradient  = @{$legend_info->{$type}{'gradient'}||[]};
#         my $swatch    = '';
#         my $legend    = '';
#         if ($colour eq 'gradient' && @gradient) {
#           $gradient[0] = '20';
#           my @colour_scale = $hub->colourmap->build_linear_gradient(@gradient);
#           my $i = 1;
#           foreach my $step (@colour_scale) {                
#             my $label;
#             if ($i == 1) {
#               $label = sprintf("%.1f", $i);
#             } 
#             elsif ($i == scalar @colour_scale) {
#               $label = '>'.$i/2;
#             }
#             else {
#               $label = $i % 3 ? '' : sprintf("%.1f", ($i/3 + 2));
#             }
#             $swatch .= qq{<div style="background:#$step">$label</div>};
#             $i++;
#           }
#           $legend = sprintf '<div class="swatch-legend">Less significant -log(p-values) &#9668;<span>%s</span>&#9658; More significant -log(p-values)</div>', ' ' x 20;
#         }
#         else {
#           $swatch = qq{<div style="background-color:$colour;" title="$colour"></div>};
#         }
#         push @$rows, {
#               'ftype'  => {'value' => $type_name},
#               'colour' => {'value' => qq(<div class="swatch-wrapper"><div class="swatch">$swatch</div>$legend</div>)},
#         };
#       }
#       my $legend = $self->new_table($columns, $rows); 
#       $html .= $legend->render;
#     }
#   }

#   ## Create HTML tables for features, if any
#   my $default_column_info = {
#     'names'   => {'title' => 'Ensembl ID'},
#     'loc'     => {'title' => 'Genomic location (strand)', 'sort' => 'position_html'},
#     'extname' => {'title' => 'External names'},
#     'length'  => {'title' => 'Length', 'sort' => 'numeric'},
#     'lrg'     => {'title' => 'Name'},
#     'xref'    => {'title' => 'Name(s)'},
#   };

#   $html .= $self->_feature_table('Gene', $features, $default_column_info);

#   return $html;
# }

1;
