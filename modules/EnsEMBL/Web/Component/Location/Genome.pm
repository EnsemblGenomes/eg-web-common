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
  if ($self->hub->param('ftype') eq 'Domain') {
    ## Override default header
    my $domain_id = $self->hub->param('id');
    my $count     = scalar @{$feature_set->[0]};
    my $plural    = $count > 1 ? 'genes' : 'gene';
    $header       = "Domain $domain_id maps to $count $plural:";
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

  if ($self->hub->param('ftype') eq 'Gene') {
    my $dba = Bio::EnsEMBL::Registry->get_DBAdaptor( $self->hub->species, 'core' ) || die("Can't connect to database");
    my $sa = $dba->get_SliceAdaptor();

    my $obs;
    my %attr_types;

    foreach my $chr (@$chromosomes) {
      my $slice = $sa->fetch_by_region( 'chromosome', $chr );

      # get some attributes of the slice
      foreach my $gene ( @{ $slice->get_all_Genes } ) {
        my $attr = $gene->get_all_Attributes('PHIbase_mutant');
        
        if (@$attr > 0) {  
          my @values = grep { $_ && $_->value() ne 'unaffected_pathogenicity'} @$attr;
          if (scalar @values > 0) {
            $attr_types{$gene->stable_id} = $values[0]->{'value'};
            push @$obs, $gene;
          }
        }
      }

      my $genes = EnsEMBL::Web::Data::Bio::Gene->new($self->hub, @$obs);
      my $features = $genes->convert_to_drawing_parameters;
      my $extra_columns = [{'key' => 'description', 'title' => 'Description'}];

      $html = $self->_render_genes($features, $config, \%attr_types);
    }
  } else {
    if ($id) {
      my $object = $self->builder->create_objects('Feature', 'lazy');
      if ($object && $object->can('convert_to_drawing_parameters')) {
        $features = $object->convert_to_drawing_parameters;
      }
    }
    $html = $self->_render_features($id, $features, $config);
  }

  return $html;
}

sub _render_genes {
  my ($self, $features, $image_config, $attr_types) = @_;

  my $hub          = $self->hub;
  my $species      = $hub->species;
  my $species_defs = $hub->species_defs;
  my $chromosomes  = $species_defs->ENSEMBL_CHROMOSOMES || [];

  my @uniq_features =  uniq (sort values %$attr_types);
  my @uniq_features_uc = map { local $_ = $_; s/_/ /g; ucfirst $_ } @uniq_features;


  ## Attach the colorizing key before making the image
  my $chr_colour_key = $self->chr_colour_key;
  
  $image_config->set_parameter('chr_colour_key', $chr_colour_key) if $image_config;

  my $html;
  my $colours = $species_defs->colour('gene');

  ## Draw features on karyotype, if any
  if (scalar @$chromosomes && $species_defs->MAX_CHR_LENGTH) {
    my $image = $self->new_karyotype_image($image_config);
    
    ## Create pointers to be drawn
    my $pointers = [];
    my ($legend_info, $has_gradient);

    if (scalar @{$features->[0]}) {
      ## Title for image
      my $title= 'Location';
      $title .= ' of ' if @uniq_features_uc;

      my $last_name = pop(@uniq_features_uc);
      if (scalar @uniq_features_uc > 0) {
        $title .= join ', ', @uniq_features_uc;
        $title .= ' and ';
      }
      $title .= $last_name;

      $html .= "<h3>$title</h3>" if $title;        

      foreach my $feature (@{$features->[0]}) {
        my $defaults    = $self->pointer_default('Gene');

        my $at = $attr_types->{$feature->{label}};
        my $colour      = $colours->{$at}->{default} || $defaults->[1];
        my $gradient    = $defaults->[2];
        my $pointer_ref = $image->add_pointers($hub, {
          config_name  => 'Vkaryotype',
          features     => [$feature],
          feature_type => $feature->{label},
          color        => $colour,
          style        => $hub->param('style')  || $defaults->[0],            
          gradient     => $gradient,
        });

        my $name = $attr_types->{$feature->{label}};
        $legend_info->{$name} = {'colour' => $colour, 'gradient' => $gradient};  
        push @$pointers, $pointer_ref;
        $has_gradient++ if $gradient;
      }
    }

    $image->image_name = @$pointers ? "feature-$species" : "karyotype-$species";
    $image->imagemap   = @$pointers ? 'yes' : 'no';
      
    $image->set_button('drag', 'title' => 'Click on a chromosome');
    $image->caption  = 'Click on the image above to jump to a chromosome, or click and drag to select a region';
    $image->imagemap = 'yes';
    $image->karyotype($hub, $self->object, $pointers, 'Vkaryotype');
      
    return if $self->_export_image($image,'no_text');
      
    $html .= $image->render;
    $html .= $self->get_chr_legend($chr_colour_key);

    ## Add colour key if required
    if ($self->html_format && (scalar(keys %$legend_info) > 1 || $has_gradient)) { 
      $html .= '<h3>Key</h3>';

      my $columns = [
        {'key' => 'ftype',  'title' => 'Feature type'},
        {'key' => 'colour', 'title' => 'Colour'},
      ];

      my $rows;

      foreach my $type (sort keys %$legend_info) {
        my $type_name = $type;
        $type_name =~ s/_/ /g;
        my $colour = $hub->colourmap->hex_by_name($legend_info->{$type}{'colour'});

        my @gradient  = @{$legend_info->{$type}{'gradient'}||[]};
        my $swatch    = '';
        my $legend    = '';
        if ($colour eq 'gradient' && @gradient) {
          $gradient[0] = '20';
          my @colour_scale = $hub->colourmap->build_linear_gradient(@gradient);
          my $i = 1;
          foreach my $step (@colour_scale) {                
            my $label;
            if ($i == 1) {
              $label = sprintf("%.1f", $i);
            } 
            elsif ($i == scalar @colour_scale) {
              $label = '>'.$i/2;
            }
            else {
              $label = $i % 3 ? '' : sprintf("%.1f", ($i/3 + 2));
            }
            $swatch .= qq{<div style="background:#$step">$label</div>};
            $i++;
          }
          $legend = sprintf '<div class="swatch-legend">Less significant -log(p-values) &#9668;<span>%s</span>&#9658; More significant -log(p-values)</div>', ' ' x 20;
        }
        else {
          $swatch = qq{<div style="background-color:$colour;" title="$colour"></div>};
        }
        push @$rows, {
              'ftype'  => {'value' => $type_name},
              'colour' => {'value' => qq(<div class="swatch-wrapper"><div class="swatch">$swatch</div>$legend</div>)},
        };
      }
      my $legend = $self->new_table($columns, $rows); 
      $html .= $legend->render;
    }
  }

  ## Create HTML tables for features, if any
  my $default_column_info = {
    'names'   => {'title' => 'Ensembl ID'},
    'loc'     => {'title' => 'Genomic location (strand)', 'sort' => 'position_html'},
    'extname' => {'title' => 'External names'},
    'length'  => {'title' => 'Length', 'sort' => 'numeric'},
    'lrg'     => {'title' => 'Name'},
    'xref'    => {'title' => 'Name(s)'},
  };

  $html .= $self->_feature_table('Gene', $features, $default_column_info);

  return $html;
}

sub _render_features {
  my ($self, $id, $features, $image_config) = @_;
  my $hub          = $self->hub;
  my $species      = $hub->species;
  my $species_defs = $hub->species_defs;
  my ($html, $total_features, $mapped_features, $unmapped_features, $has_internal_data, $has_userdata);
  my $chromosomes  = $species_defs->ENSEMBL_CHROMOSOMES || [];
  my %chromosome = map {$_ => 1} @$chromosomes;
  while (my ($type, $set) = each (%$features)) {
    foreach my $feature (@{$set->[0]}) {
      $has_internal_data++;
      if ($chromosome{$feature->{'region'}}) {
        $mapped_features++;
      }
      else {
        $unmapped_features++;
      }
      $total_features++;
    }
  }

  if ($id && $total_features < 1) {
    my $ids = ref($id) eq 'ARRAY' ? join(', ', @$id) : $id;
    my $message;
    if ($self->hub->type eq 'Phenotype') {
      $message = 'No mapped variants are available for this phenotype';
    }
    else {
      $message = sprintf('<p>No mapping of %s found</p>', $ids || 'unknown feature');
    }
    return $self->_warning('Not found', $message);
  }

  ## Add in userdata tracks
  my $user_features = $image_config ? $image_config->create_user_features : {};
  while (my ($key, $data) = each (%$user_features)) {
    while (my ($analysis, $track) = each (%$data)) {
      foreach my $feature (@{$track->{'features'}}) {
        $has_userdata++;
        if ($chromosome{$feature->{'chr'}}) {
          $mapped_features++;
        }
        else {
          $unmapped_features++;
        }
        $total_features++;
      }
    }
  }

  ## Attach the colorizing key before making the image
  my $chr_colour_key = $self->chr_colour_key;
  
  $image_config->set_parameter('chr_colour_key', $chr_colour_key) if $image_config;
  
# EG:ENSEMBL-2785 start
  ## Map some user-friendly display names
  my $feature_display_name = {
    'Xref'                => 'External Reference',
    'ProbeFeature'        => 'Oligoprobe',
    'DnaAlignFeature'     => 'Sequence Feature',
    'ProteinAlignFeature' => 'Protein Feature',
  };
  my ($xref_type, $xref_name);
  while (my ($type, $feature_set) = each (%$features)) {    
    if ($type eq 'Xref') {
      my $sample = $feature_set->[0][0];
      $xref_type = $sample->{'label'};
      $xref_name = $sample->{'extname'};
      $xref_name =~ s/ \[#\]//;
      $xref_name =~ s/^ //;
    }
  }

  my $title;
  if ($has_internal_data) { 
    unless ($hub->param('ph')) { ## omit h3 header for phenotypes
      $title = 'Location';
      $title .= 's' if $mapped_features > 1;
      $title .= ' of ';
      my ($data_type, $assoc_name);
      my $ftype = $hub->param('ftype');
      if (grep (/$ftype/, keys %$features)) {
        $data_type = $ftype;
      }
      else {
        my @A = sort keys %$features;
        $data_type = $A[0];
        $assoc_name = $hub->param('name');
        unless ($assoc_name) {
          $assoc_name = $xref_type.' ';
          $assoc_name .= $id;
          $assoc_name .= " ($xref_name)" if $xref_name;
        }
      }

      my %names;
      ## De-camelcase names
      foreach (sort keys %$features) {
        my $pretty = $feature_display_name->{$_} || $self->decamel($_);
        $pretty .= 's' if $mapped_features > 1;
        $names{$_} = $pretty;
      }

      my @feat_names = sort values %names;
      my $last_name = pop(@feat_names);
      if (scalar @feat_names > 0) {
        $title .= join ', ', @feat_names;
        $title .= ' and ';
      }
      $title .= $last_name;
      $title .= " associated with $assoc_name" if $assoc_name;
    }
  }
  elsif ($mapped_features) {
    $title = 'Location of your feature';
    $title .= 's' if $has_userdata > 1;
  }
  $html .= "<h3>$title</h3>" if $title;        
# EG:ENSEMBL-2785 end
  
  ## Draw features on karyotype, if any
  if (scalar @$chromosomes && $species_defs->MAX_CHR_LENGTH) {
    my $image = $self->new_karyotype_image($image_config);
    
# EG:ENSEMBL-2785 Code for building title moved, see above

    ## Create pointers to be drawn
    my $pointers = [];
    my ($legend_info, $has_gradient);

    if ($mapped_features) {

      ## Title for image - a bit messy, but we want it to be human-readable!

# EG:ENSEMBL-2785 Code for building title moved, see above

      ## Create pointers for Ensembl features
      while (my ($feat_type, $set) = each (%$features)) {          
        my $defaults    = $self->pointer_default($feat_type);
        my $colour      = $hub->param('colour') || $defaults->[1];
        my $gradient    = $defaults->[2];
        my $pointer_ref = $image->add_pointers($hub, {
          config_name  => 'Vkaryotype',
          features     => $set->[0],
          feature_type => $feat_type,
          color        => $colour,
          style        => $hub->param('style')  || $defaults->[0],            
          gradient     => $gradient,
        });
        $legend_info->{$feat_type} = {'colour' => $colour, 'gradient' => $gradient};  
        push @$pointers, $pointer_ref;
        $has_gradient++ if $gradient;
      }

      ## Create pointers for userdata
      if (keys %$user_features) {
        push @$pointers, $self->create_user_pointers($image, $user_features);
      } 

    }

    $image->image_name = @$pointers ? "feature-$species" : "karyotype-$species";
    $image->imagemap   = @$pointers ? 'yes' : 'no';
      
    $image->set_button('drag', 'title' => 'Click on a chromosome');
    $image->caption  = 'Click on the image above to jump to a chromosome, or click and drag to select a region';
    $image->imagemap = 'yes';
    $image->karyotype($hub, $self->object, $pointers, 'Vkaryotype');
      
    return if $self->_export_image($image,'no_text');
      
    $html .= $image->render;
    $html .= $self->get_chr_legend($chr_colour_key);

    ## Add colour key if required
    if ($self->html_format && (scalar(keys %$legend_info) > 1 || $has_gradient)) { 
      $html .= '<h3>Key</h3>';

      my $columns = [
        {'key' => 'ftype',  'title' => 'Feature type'},
        {'key' => 'colour', 'title' => 'Colour'},
      ];
      my $rows;

      foreach my $type (sort keys %$legend_info) {
        my $type_name = $feature_display_name->{$type} || $type;
        my $colour    = $legend_info->{$type}{'colour'};
        my @gradient  = @{$legend_info->{$type}{'gradient'}||[]};
        my $swatch    = '';
        my $legend    = '';
        if ($colour eq 'gradient' && @gradient) {
          $gradient[0] = '20';
          my @colour_scale = $hub->colourmap->build_linear_gradient(@gradient);
          my $i = 1;
          foreach my $step (@colour_scale) {                
            my $label;
            if ($i == 1) {
              $label = sprintf("%.1f", $i);
            } 
            elsif ($i == scalar @colour_scale) {
              $label = '>'.$i/2;
            }
            else {
              $label = $i % 3 ? '' : sprintf("%.1f", ($i/3 + 2));
            }
            $swatch .= qq{<div style="background:#$step">$label</div>};
            $i++;
          }
          $legend = sprintf '<div class="swatch-legend">Less significant -log(p-values) &#9668;<span>%s</span>&#9658; More significant -log(p-values)</div>', ' ' x 20;
        }
        else {
          $swatch = qq{<div style="background-color:$colour;" title="$colour"></div>};
        }
        push @$rows, {
              'ftype'  => {'value' => $type_name},
              'colour' => {'value' => qq(<div class="swatch-wrapper"><div class="swatch">$swatch</div>$legend</div>)},
        };
      }
      my $legend = $self->new_table($columns, $rows); 
      $html .= $legend->render;
    }
      
    if ($unmapped_features > 0) {
      my $message;
      if ($mapped_features) {
        my $do    = $unmapped_features > 1 ? 'features do' : 'feature does';
        my $have  = $unmapped_features > 1 ? 'have' : 'has';
        $message = "$unmapped_features $do not map to chromosomal coordinates and therefore $have not been drawn.";
      }
      else {
        $message = 'No features map to chromosomal coordinates.'
      }
      $html .= $self->_info('Undrawn features', "<p>$message</p>");
    }

  } elsif (!scalar @$chromosomes) {
    $html .= $self->_info('Unassembled genome', '<p>This genome has yet to be assembled into chromosomes</p>');
  }

  ## Create HTML tables for features, if any
  my $default_column_info = {
    'names'   => {'title' => 'Ensembl ID'},
    'loc'     => {'title' => 'Genomic location (strand)', 'sort' => 'position_html'},
    'extname' => {'title' => 'External names'},
    'length'  => {'title' => 'Length', 'sort' => 'numeric'},
    'lrg'     => {'title' => 'Name'},
    'xref'    => {'title' => 'Name(s)'},
  };

  while (my ($feat_type, $feature_set) = each (%$features)) {
    $html .= $self->_feature_table($feat_type, $feature_set, $default_column_info);
  }

  ## User tables
  if (keys %$user_features) {
    ## Colour key
    my $table_info  = $self->configure_UserData_key($image_config);
    my $column_info = $default_column_info;
    my $columns     = [];
    my $col;

    foreach $col (@{$table_info->{'column_order'}||[]}) {
      push @$columns, {'key' => $col, 'title' => $column_info->{$col}{'title'}};
    }

    my $table = $self->new_table($columns, $table_info->{'rows'}, { header => 'no' });
    $html .= "<h3>$table_info->{'header'}</h3>";
    $html .= $table->render;

    ## Table(s) of features
    while (my ($k, $v) = each (%$user_features)) {
      while (my ($ftype, $data) = each (%$v)) {
        my $extra_columns = $ftype eq 'Gene' ?
                            [{'key'=>'description', 'title'=>'Description'}]
                            : [
                              {'key' => 'align',    'title' => 'Alignment length'},
                              {'key' => 'ori',      'title' => 'Rel ori'},
                              {'key' => 'id',       'title' => '%id'},
                              {'key' => 'score',    'title' => 'Score'},
                              {'key' => 'p-value',  'title' => 'p-value'},
                              ]; 
        $html .= $self->_feature_table($ftype, [$data->{'features'}, $extra_columns], $default_column_info);
      }
    }

  }

  unless (keys %$features || keys %$user_features) {
    $html .= EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, "/ssi/species/stats_$species.html");
  }

  ## Done!
  return $html;
}
1;
