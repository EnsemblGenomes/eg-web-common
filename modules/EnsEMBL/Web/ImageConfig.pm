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

package EnsEMBL::Web::ImageConfig;

use strict;
use previous qw(menus);

sub add_alignments {
  my ($self, $key, $hashref, $species) = @_;
  
  return unless grep $self->get_node($_), qw(multiple_align pairwise_tblat pairwise_blastz pairwise_other conservation);
  
  my $species_defs = $self->species_defs;
  
  return if $species_defs->ENSEMBL_SITETYPE eq 'Pre';
  
  my $alignments = {};
  my $self_label = $species_defs->species_label($species, 'no_formatting');
  my $static     = $species_defs->ENSEMBL_SITETYPE eq 'Vega' ? '/info/data/comparative_analysis.html' : '/info/genome/compara/analyses.html';
 
  foreach my $row (values %{$hashref->{'ALIGNMENTS'}}) {
    next unless $row->{'species'}{$species};
   
    if ($row->{'class'} =~ /pairwise_alignment/) {
      my ($other_species) = grep { !/^$species$|ancestral_sequences$/ } keys %{$row->{'species'}};
         $other_species ||= $species if scalar keys %{$row->{'species'}} == 1;
      my $other_label     = $species_defs->species_label($other_species, 'no_formatting');



      my ($menu_key, $description, $type);
      
      if ($row->{'type'} =~ /(B?)LASTZ_(\w+)/) {
        next if $2 eq 'PATCH';
        
        $menu_key    = 'pairwise_blastz';
        $type        = sprintf '%sLASTz %s', $1, lc $2;
        $description = "$type pairwise alignments";
      } elsif ($row->{'type'} =~ /TRANSLATED_BLAT/) {
        $type        = '';
        $menu_key    = 'pairwise_tblat';
        $description = 'Trans. BLAT net pairwise alignments';
      } else {
        $type        = ucfirst lc $row->{'type'};
        $type        =~ s/\W/ /g;
        $menu_key    = 'pairwise_other';
        $description = 'Pairwise alignments';
      }
      
      $description  = qq{<a href="$static" class="cp-external">$description</a> between $self_label and $other_label"};
      $description .= " $1" if $row->{'name'} =~ /\((on.+)\)/;

      $alignments->{$menu_key}{$row->{'id'}} = {
        db                         => $key,
        glyphset                   => '_alignment_pairwise',
        name                       => $other_label . ($type ?  " - $type" : ''),
## EG ENSEMBL-2967       
        caption                    => $species_defs->abbreviated_species_label($other_species),
##        
        type                       => $row->{'type'},
        species                    => $other_species,
        method_link_species_set_id => $row->{'id'},
        description                => $description,
        order                      => $other_label,
        colourset                  => 'pairwise',
        strand                     => 'r',
        display                    => 'off',
        renderers                  => [ 'off', 'Off', 'compact', 'Compact', 'normal', 'Normal' ],
      };
    } else {
      my $n_species = grep { $_ ne 'ancestral_sequences' } keys %{$row->{'species'}};
      
      my %options = (
        db                         => $key,
        glyphset                   => '_alignment_multiple',
        short_name                 => $row->{'name'},
        type                       => $row->{'type'},
        species_set_id             => $row->{'species_set_id'},
        method_link_species_set_id => $row->{'id'},
        class                      => $row->{'class'},
        colourset                  => 'multiple',
        strand                     => 'f',
      );
      
      if ($row->{'conservation_score'}) {
        my ($program) = $hashref->{'CONSERVATION_SCORES'}{$row->{'conservation_score'}}{'type'} =~ /(.+)_CONSERVATION_SCORE/;
        
        $options{'description'} = qq{<a href="/info/genome/compara/analyses.html#conservation">$program conservation scores</a> based on the $row->{'name'}};
        
        $alignments->{'conservation'}{"$row->{'id'}_scores"} = {
          %options,
          conservation_score => $row->{'conservation_score'},
          name               => "Conservation score for $row->{'name'}",
          caption            => "$n_species way $program scores",
          order              => sprintf('%12d::%s::%s', 1e12-$n_species*10, $row->{'type'}, $row->{'name'}),
          display            => 'off',
          renderers          => [ 'off', 'Off', 'tiling', 'Tiling array' ],
        };
        
        $alignments->{'conservation'}{"$row->{'id'}_constrained"} = {
          %options,
          constrained_element => $row->{'constrained_element'},
          name                => "Constrained elements for $row->{'name'}",
          caption             => "$n_species way $program elements",
          order               => sprintf('%12d::%s::%s', 1e12-$n_species*10+1, $row->{'type'}, $row->{'name'}),
          display             => 'off',
          renderers           => [ 'off', 'Off', 'compact', 'On' ],
        };
      }
      
      $alignments->{'multiple_align'}{$row->{'id'}} = {
        %options,
        name        => $row->{'name'},
        caption     => $row->{'name'},
        order       => sprintf('%12d::%s::%s', 1e12-$n_species*10-1, $row->{'type'}, $row->{'name'}),
        display     => 'off',
        renderers   => [ 'off', 'Off', 'compact', 'On' ],
        description => qq{<a href="/info/genome/compara/analyses.html#conservation">$n_species way whole-genome multiple alignments</a>.; } . 
                       join('; ', sort map { $species_defs->species_label($_, 'no_formatting') } grep { $_ ne 'ancestral_sequences' } keys %{$row->{'species'}}),
      };
    } 
  }
  
  foreach my $menu_key (keys %$alignments) {
    my $menu = $self->get_node($menu_key);
    next unless $menu;
    
    foreach my $key_2 (sort { $alignments->{$menu_key}{$a}{'order'} cmp  $alignments->{$menu_key}{$b}{'order'} } keys %{$alignments->{$menu_key}}) {
      my $row = $alignments->{$menu_key}{$key_2};
      $menu->append($self->create_track("alignment_${key}_$key_2", $row->{'caption'}, $row));
    }
  }
}

sub _add_bigwig_track {
  my ($self, %args) = @_;
  
  my $renderers = $args{'source'}{'renderers'} || [
    'off',     'Off',
    'tiling',  'Wiggle plot',
## EG    
    'gradient', 'Gradient',
    'pvalue',   'P-value',
##    
  ];
 
  my $options = {
    external => 'external',
    sub_type => 'bigwig',
    colour   => $args{'menu'}{'colour'} || $args{'source'}{'colour'} || 'red',
  };
  
  $options->{viewLimits} = $args{viewLimits} || $args{source}->{viewLimits};

  $self->_add_file_format_track(
    format    => 'BigWig', 
    renderers =>  $renderers,
    options   => $options,
    %args
  );
}

sub load_configured_mw    { shift->load_file_format('mw');    }

sub _add_mw_track {
  my ($self, %args) = @_;

  my $renderers = $args{'source'}{'renderers'} || [
    'off',     'Off',
    'tiling',  'On',
  ];
 
  my $options = {
    external => 'external',
    sub_type => 'mw',
    strand      => $args{source}{strand} || 'f'
  };

  foreach my $arg (sort keys %{$args{source}}) {
      $options->{$arg} = $args{source}->{$arg};
  }
  
  $self->_add_file_format_track(
    format    => 'MW', 
    renderers =>  $renderers,
    options   => $options,
    %args
  );
}


sub menus {
  my $self  = shift;
  my $menus = $self->PREV::menus(@_);
  my $add   = {
    
    # used to organise fungi/protists external tracks
    chromatin_binding      => 'Chromatin binding',      
    pb_intron_branch_point => 'Intron Branch Point',    
    polya_sites            => 'Polyadenylation sites',  
    replication_profiling  => 'Replication Profiling',  
    regulatory_elements    => 'Regulatory Elements',    
    tss                    => 'Transcription Start Sites',
    transcriptome          => 'Transcriptome',          
    nucleosome             => 'Nucleosome Positioning', 
    polymerase             => 'Polymerase Usage',       
    dna_methylation        => 'DNA Methylation',        
    histone_mod            => 'Histone Modification', 
    
    # used to organise plants external tracks
    wheat_alignment        => 'Wheat SNPs and alignments',
    wheat_assembly         => [ 'Wheat Assemblies and SNPs',           'wheat_alignment' ],
    wheat_transcriptomics  => [ 'Wheat transcriptomics',               'wheat_alignment' ],
    wheat_ests             => [ 'Wheat UniGene and ESTs',              'wheat_alignment' ],
    rnaseq_cultivar        => [ 'RNASeq study of nine cultivars',      'mrna_prot' ],
    rnaseq_tissue          => [ 'RNASeq study of eight growth stages', 'mrna_prot' ],
    resequencing           => [ 'Resequencing', 'functional' ], 

  };

  # EG ENSEMBL-3655 change terminology for Barley community
  if ($self->hub->species =~ /Hordeum_vulgare/i ) {
    $add->{prediction} = [ 'Low-confidence genes', 'gene_transcript' ];
  }

  return { %$menus, %$add };
}

## Add the density display for the variation tracks
sub _add_msa_track {
  my ($self, %args) = @_;
  my ($menu, $source) = ($args{'menu'}, $args{'source'});

  $menu ||= $self->get_node('user_data');

  return unless $menu;

  my $time  =  $source->{'timestamp'};
  my $key   =  $args{'key'} || 'msa_' . $time . '_' . md5_hex($self->{'species'} . ':' . $source->{'source_url'});
  my $sname =  $source->{'source_name'} ||  $source->{'name'};

  my $track = $self->create_track($key, $sname, {
      display     => 'off',
      glyphset    => 'msa',
      sources     => undef,
      strand      => 'f',
      depth       => 0.5,
      bump_width  => 0,
      renderers   => [off => 'Off', normal => 'Normal'],
      format      => $source->{'format'},
      data => $source->{'data'},
      fasta => $source->{'fasta'},
      id => $key,
      caption     => $source->{'caption'} || $sname,
      url         => $source->{'source_url'} || $source->{url},
      description => $source->{'description'} || sprintf('Data retrieved from a MSA file on an external webserver. This data is attached to the %s, and comes from URL: %s', encode_entities($source->{'source_type'}), encode_entities($source->{'source_url'} || $source->{'url'})),
  });

  $menu->append($track) if $track;
}

sub load_configured_msa {
  my $self = shift;

  # get the internal sources from config
  my $internal_sources = $self->sd_call('ENSEMBL_INTERNAL_MSA_SOURCES') || {};

  foreach my $source_name (sort keys %$internal_sources) {
    # get the target menu 
    my $menu_name = $internal_sources->{$source_name};
    if (my $menu = $self->get_node($menu_name)) {
      if (my $source  = $self->sd_call($source_name)) {
	  $source->{key} = $source_name;
	  $self->_add_msa_track($menu, $source);
      }
    }
  }
}

sub _add_vcf_track {
  my ($self, %args) = @_;
  my ($menu, $source) = ($args{'menu'}, $args{'source'});

  $menu ||= $self->get_node('user_data');
  return unless $menu;

  my $time = $source->{'timestamp'};

  my $key = $args{'key'} || 'vcf_' . $time . '_' . md5_hex($self->{'species'} . ':' . $source->{'source_url'});

  my $sname =  $source->{'source_name'} ||  $source->{'name'};

  my $track = $self->create_track($key, $sname, {
      display     => 'off',
      glyphset    => 'vcf',
      sources     => undef,
      strand      => $source->{strand} || 'f',
      depth       => 0.5,
      bump_width  => 0,
      format      => $source->{'format'},
      colourset   => 'variation',
      renderers   => [off => 'Off', histogram => 'Density', compact => 'Compact'],
      caption     => $source->{'caption'} || $sname,
      url         => $source->{'source_url'} || $source->{url},
      description => $source->{'description'} || sprintf('Data retrieved from a VCF file on an external webserver. This data is attached to the %s, and comes from URL: %s', encode_entities($source->{'source_type'}), encode_entities($source->{'source_url'} || $source->{'url'})),
  });

  $menu->append($track) if $track;
}

# adds variation tracks the old, hacky way
sub add_sequence_variations_default {
  my ($self, $key, $hashref, $options) = @_;
  my $menu = $self->get_node('variation');

## EG - ENSEMBL-3525 need to use old node name 'sequence_variations' instead of 'variants' (not sure why)
  my $sequence_variation = ($menu->get_node('sequence_variations')) ? $menu->get_node('sequence_variations') : $self->create_submenu('sequence_variations', 'Sequence variants');

  #if (!$menu->get_node('sequence_variations')) {
    my $title = 'Sequence variants (all sources)';

    $sequence_variation->append($self->create_track("variation_feature_$key", $title, {
      %$options,
      sources     => undef,
      description => 'Sequence variants from all sources',
    }));
  #}
##

  foreach my $key_2 (sort keys %{$hashref->{'source'}{'counts'} || {}}) {
    next unless $hashref->{'source'}{'counts'}{$key_2} > 0;
    next if     $hashref->{'source'}{'somatic'}{$key_2} == 1;
    next if     $key_2 =~ /Inter-homoeologous/;

    # EG/1KG fix for ESP tracks:
    my $vf_track = {};
    $vf_track->{caption} = $key_2 =~ /^ESP$/ ? 'Exome Sequencing Project' : $key_2;
    $vf_track->{sources} = $key_2 =~ /^ESP$/ ? 'NHLBI GO Exome Sequencing Project' : $key_2;

    $sequence_variation->append($self->create_track("variation_feature_${key}_$key_2", $vf_track->{caption}." variations", {
      %$options,
      caption     => $vf_track->{caption},
      sources     => [ $vf_track->{sources} ],
      description => $hashref->{'source'}{'descriptions'}{$key_2},
    }));
    # EG/1KG
  }
  
  $menu->append($sequence_variation) if (!$menu->get_node('variants'));

  # add in variation sets
  if ($hashref->{'variation_set'}{'rows'} > 0 ) {
    my $variation_sets = $self->create_submenu('variation_sets', 'Variation sets');
    
    $menu->append($variation_sets);
    
    foreach my $toplevel_set (
      sort { !!scalar @{$a->{'subsets'}} <=> !!scalar @{$b->{'subsets'}} } 
      sort { $a->{'name'} =~ /^failed/i  <=> $b->{'name'} =~ /^failed/i  } 
      sort { $a->{'name'} cmp $b->{'name'} } 
      values %{$hashref->{'variation_set'}{'supersets'}}
    ) {
      my $name          = $toplevel_set->{'name'};
      my $caption       = $name . (scalar @{$toplevel_set->{'subsets'}} ? ' (all data)' : '');
      my $key           = $toplevel_set->{'short_name'};
      my $set_variation = scalar @{$toplevel_set->{'subsets'}} ? $self->create_submenu("set_variation_$key", $name) : $variation_sets;
      
      $set_variation->append($self->create_track("variation_set_$key", $caption, {
        %$options,
        caption     => $caption,
        sources     => undef,
        sets        => [ $key ],
        set_name    => $name,
        description => $toplevel_set->{'description'},
      }));
      
      # add in sub sets
      if (scalar @{$toplevel_set->{'subsets'}}) {
        foreach my $subset_id (sort @{$toplevel_set->{'subsets'}}) {
          my $sub_set             = $hashref->{'variation_set'}{'subsets'}{$subset_id};
          my $sub_set_name        = $sub_set->{'name'}; 
          my $sub_set_description = $sub_set->{'description'};
          my $sub_set_key         = $sub_set->{'short_name'};
          
          $set_variation->append($self->create_track("variation_set_$sub_set_key", $sub_set_name, {
            %$options,
            caption     => $sub_set_name,
            sources     => undef,
            sets        => [ $sub_set_key ],
            set_name    => $sub_set_name,
            description => $sub_set_description
          }));
        }
       
        $variation_sets->append($set_variation);
      }
    }
  }
}

sub load_configured_bed    { my $result = shift->load_file_format('bed'); }
sub load_configured_bedgraph    { my $result = shift->load_file_format('bedgraph');  }
sub _add_bed_track {
  my ($self,%args) = @_;
  my $menu = $args{'menu'};
  my $source = $args{'source'};
  my $description = $source->{'description'} || 
     sprintf('Data retrieved from an external webserver. This data and comes from URL: %s', encode_entities($source->{'source_url'}));
  $self->_add_flat_file_track($menu, 'url', $args{'key'}, $source->{'source_name'},
     $description,
     url             => $source->{'source_url'},
     format          => $source->{'format'} || 'bed',
     display         => $source->{'display'} || 'normal',
     description     => $description,
     external_link   => $source->{'external_link'},
  );
}
sub _add_bedgraph_track {
   my ($self,%args) = @_;
   my $menu = $args{'menu'};
   my $source = $args{'source'};
   my $description = $source->{'description'} || 
     sprintf('Data retrieved from an external webserver. This data and comes from URL: %s', encode_entities($source->{'source_url'}));
   $self->_add_flat_file_track($menu, 'url', $args{'key'}, $source->{'source_name'},
      $description,
      url           => $source->{'source_url'},
      format        => 'BEDGRAPH',
      style         => 'wiggle',
      display       => $source->{'display'} || 'tiling',
      description   => $description,
      external_link => $source->{'external_link'},
   );
}

sub load_user_tracks {
  my $self = shift;
  my $menu = $self->get_node('user_data');
  
  return unless $menu;
  
  my $hub      = $self->hub;
  my $session  = $hub->session;
  my $user     = $hub->user;
  my $das      = $hub->get_all_das;
  my $trackhubs = $self->get_parameter('trackhubs') == 1;
  my (%url_sources, %upload_sources);

  $self->_load_url_feature($menu);

  foreach my $source (sort { ($a->caption || $a->label) cmp ($b->caption || $b->label) } values %$das) {
    my $node = $self->get_node('das_' . $source->logic_name);

    next if     $node && $node->get('node_type') eq 'track';
    next unless $source->is_on($self->{'type'});
    
    $self->add_das_tracks('user_data', $source);
  }

  ## Data attached via URL

  foreach my $entry ($session->get_data(type => 'url')) {
    next if $entry->{'no_attach'};
    next unless $entry->{'species'} eq $self->{'species'};

    $url_sources{"url_$entry->{'code'}"} = {
      source_type => 'session',
      source_name => $entry->{'name'} || $entry->{'url'},
      source_url  => $entry->{'url'},
      species     => $entry->{'species'},
      format      => $entry->{'format'},
      style       => $entry->{'style'},
      colour      => $entry->{'colour'},
      display     => $entry->{'display'},
      timestamp   => $entry->{'timestamp'} || time,
      strand      => $entry->{strand},
      caption     => $entry->{caption},
      viewLimits  => $entry->{viewLimits},

    };
  }
  
  ## Data uploaded but not saved
  foreach my $entry ($session->get_data(type => 'upload')) {
    next unless $entry->{'species'} eq $self->{'species'};
   
    if ($entry->{'analyses'}) {
      foreach my $analysis (split /, /, $entry->{'analyses'}) {
        $upload_sources{$analysis} = {
          source_name => $entry->{'name'},
          source_type => 'session',
          assembly    => $entry->{'assembly'},
          style       => $entry->{'style'},
        };
        
        $self->_compare_assemblies($entry, $session);
      }
    } elsif ($entry->{'species'} eq $self->{'species'} && !$entry->{'nonpositional'}) {
      my ($strand, $renderers) = $self->_user_track_settings($entry->{'style'}, $entry->{'format'});
      $strand = $entry->{'strand'} if $entry->{'strand'};
      
      $menu->append($self->create_track("upload_$entry->{'code'}", $entry->{'name'}, {
        external    => 'user',
        glyphset    => '_flat_file',
        colourset   => 'classes',
        sub_type    => 'tmp',
        file        => $entry->{'file'},
        format      => $entry->{'format'},
        caption     => $entry->{'name'},
        renderers   => $renderers,
        description => 'Data that has been temporarily uploaded to the web server.',
        display     => 'normal', # turn on just uploaded user track by default ensembl-2124
        strand      => $strand,
      }));
    }
  }
  
  ## Data saved by the user  
  if ($user) {
    my @groups = $user->get_groups;

    ## URL attached data
    foreach my $entry (grep $_->species eq $self->{'species'}, $user->get_records('urls'), map $user->get_group_records($_, 'urls'), @groups) {
      $url_sources{'url_' . $entry->code} = {
        source_name => $entry->name || $entry->url,
        source_type => 'user', 
        source_url  => $entry->url,
        species     => $entry->species,
        format      => $entry->format,
        style       => $entry->style,
        colour      => $entry->colour,
        display     => 'off',
        timestamp   => $entry->timestamp,
      };
    }
    
    ## Uploads that have been saved to the userdata database
    foreach my $entry (grep $_->species eq $self->{'species'}, $user->get_records('uploads'), map $user->get_group_records($_, 'uploads'), @groups) {
      my ($name, $assembly) = ($entry->name, $entry->assembly);
      
      foreach my $analysis (split /, /, $entry->analyses) {
        $upload_sources{$analysis} = {
          source_name => $name,
          source_type => 'user',
          assembly    => $assembly,
          style       => $entry->style,
        };
        
        $self->_compare_assemblies($entry, $session);
      }
    }
  }

  ## Now we can add all remote (URL) data sources
  foreach my $code (sort { $url_sources{$a}{'source_name'} cmp $url_sources{$b}{'source_name'} } keys %url_sources) {
    my $add_method = lc "_add_$url_sources{$code}{'format'}_track";
    
    if ($self->can($add_method)) {
      $self->$add_method(
        key      => $code,
        menu     => $menu,
        source   => $url_sources{$code},
        external => 'user'
      );
    } elsif (lc $url_sources{$code}{'format'} eq 'trackhub') {
      $self->_add_trackhub($url_sources{$code}{'source_name'}, $url_sources{$code}{'source_url'}) if $trackhubs;
    } else {
      $self->_add_flat_file_track($menu, 'url', $code, $url_sources{$code}{'source_name'},
        sprintf('
          Data retrieved from an external webserver. This data is attached to the %s, and comes from URL: <a href="%s">%s</a>',
          encode_entities($url_sources{$code}{'source_type'}), 
          encode_entities($url_sources{$code}{'source_url'}),
          encode_entities($url_sources{$code}{'source_url'})
        ),
        url      => $url_sources{$code}{'source_url'},
        format   => $url_sources{$code}{'format'},
        style    => $url_sources{$code}{'style'},
        external => 'user',
      );
    }
  }
  
  ## And finally any saved uploads
  if (keys %upload_sources) {
    my $dbs        = EnsEMBL::Web::DBSQL::DBConnection->new($self->{'species'});
    my $dba        = $dbs->get_DBAdaptor('userdata');
    my $an_adaptor = $dba->get_adaptor('Analysis');
    my @tracks;
    
    foreach my $logic_name (keys %upload_sources) {
      my $analysis = $an_adaptor->fetch_by_logic_name($logic_name);
      
      next unless $analysis;
   
      $analysis->web_data->{'style'} ||= $upload_sources{$logic_name}{'style'};
     
      my ($strand, $renderers) = $self->_user_track_settings($analysis->web_data->{'style'}, $analysis->program_version);
      my $source_name = encode_entities($upload_sources{$logic_name}{'source_name'});
      my $description = encode_entities($analysis->description) || "User data from dataset $source_name";
      my $caption     = encode_entities($analysis->display_label);
         $caption     = "$source_name: $caption" unless $caption eq $upload_sources{$logic_name}{'source_name'};
         $strand      = $upload_sources{$logic_name}{'strand'} if $upload_sources{$logic_name}{'strand'};
      
      push @tracks, [ $logic_name, $caption, {
        external    => 'user',
        glyphset    => '_user_data',
        colourset   => 'classes',
        sub_type    => $upload_sources{$logic_name}{'source_type'} eq 'user' ? 'user' : 'tmp',
        renderers   => $renderers,
        source_name => $source_name,
        logic_name  => $logic_name,
        caption     => $caption,
        data_type   => $analysis->module,
        description => $description,
        display     => 'off',
        style       => $analysis->web_data,
        format      => $analysis->program_version,
        strand      => $strand,
      }];
    }
   
    $menu->append($self->create_track(@$_)) for sort { lc $a->[2]{'source_name'} cmp lc $b->[2]{'source_name'} || lc $a->[1] cmp lc $b->[1] } @tracks;
  }
 
  $ENV{'CACHE_TAGS'}{'user_data'} = sprintf 'USER_DATA[%s]', md5_hex(join '|', map $_->id, $menu->nodes) if $menu->has_child_nodes;
}

sub _add_flat_file_track {
  my ($self, $menu, $sub_type, $key, $name, $description, %options) = @_;
  $menu ||= $self->get_node('user_data');
  
  return unless $menu;
 
  my ($strand, $renderers) = $self->_user_track_settings($options{'style'}, $options{'format'});
  
  my $track = $self->create_track($key, $name, {
    display     => 'off',
    strand      => $strand,
    external    => 'external',
    glyphset    => '_flat_file',
    colourset   => 'classes',
## EG    
    caption     => $options{caption} || $name,
##
    sub_type    => $sub_type,
    renderers   => $renderers,
    description => $description,
    %options
  });
  
  $menu->append($track) if $track;
}

sub _user_track_settings {
  my ($self, $style, $format) = @_;
  my ($strand, @user_renderers);
      
  if (lc($format) eq 'pairwise') {
    $strand         = 'f';
    @user_renderers = ('off', 'Off', 'interaction', 'Pairwise interaction',
                        'interaction_label', 'Pairwise interaction with labels');
  }
  elsif ($style =~ /^(wiggle|WIG)$/) {
    $strand         = 'r';
## EG
    @user_renderers = ('off', 'Off', 'tiling', 'Wiggle plot', 'gradient', 'Gradient', 'pvalue', 'P-value');
##
  }
  elsif (uc $format =~ /BED/) {
    $strand = 'b';
    @user_renderers = @{$self->{'alignment_renderers'}};
    splice @user_renderers, 6, 0, 'as_transcript_nolabel', 'Structure', 'as_transcript_label', 'Structure with labels';
  }
  else {
    $strand         = (uc($format) eq 'VEP_INPUT' || uc($format) eq 'VCF') ? 'f' : 'b';
    @user_renderers = (@{$self->{'alignment_renderers'}}, 'difference', 'Differences');
  }

  return ($strand, \@user_renderers);
}

sub _add_file_format_track {
  my ($self, %args) = @_;
  my $menu = $args{'menu'} || $self->get_node('user_data');
  
  return unless $menu;
  
  %args = $self->_add_trackhub_extras_options(%args) if $args{'source'}{'trackhub'};
  
  my $type    = lc $args{'format'};
  my $article = $args{'format'} =~ /^[aeiou]/ ? 'an' : 'a';
  my $desc;
  
  if ($args{'internal'}) {
    $desc = "Data served from a $args{'format'} file: $args{'description'}";
  } else {
## EG don't show attachment message for internally configured sources
    my $from = $args{'source'}{'source_type'} =~ /^session|user$/i
      ? sprintf( 'This data is attached to the %s, and comes from URL: %s', encode_entities($args{'source'}{'source_type'}), encode_entities($args{'source'}{'source_url'}) )
      : sprintf( 'This data comes from URL: %s', encode_entities($args{'source'}{'source_url'}) );

    $desc = sprintf(
      'Data retrieved from %s %s file on an external webserver. %s<br />%s',
      $article,
      $args{'format'},
      $args{'description'},
      $from,
    );
##    
  }
  
  my $track = $self->create_track($args{'key'}, $args{'source'}{'source_name'}, {
    display     => 'off',
    strand      => $args{source}{strand} || 'f',
    format      => $args{'format'},
    glyphset    => $type,
    colourset   => $type,
    renderers   => $args{'renderers'},
    caption     => exists($args{'source'}{'caption'}) ? $args{'source'}{'caption'} : $args{'source'}{'source_name'},
    url         => $args{'source'}{'source_url'},
    description => $desc,
    %{$args{'options'}}
  });
  
  $menu->append($track) if $track;
}

sub update_from_url {
  ## Tracks added "manually" in the URL (e.g. via a link)
  
  my ($self, @values) = @_;
  my $hub     = $self->hub;
  my $session = $hub->session;
  my $species = $hub->species;
  
  foreach my $v (@values) {

## EG    
    # first value url, second one query string containing params for image like strand, name and colour
    my @array = split /::/, $v; 
    my %image_param = split /\//, $array[1];
    my $viewLimits = $hub->param('viewLimits');
    my %extra_params = (
      colour     => $image_param{colour},
      strand     => $image_param{strand},
      caption    => $image_param{name},
      viewLimits => $viewLimits,
    );
##

    my $format = $hub->param('format');
    my ($key, $renderer);
    
    if (uc $format eq 'TRACKHUB') {
      $key = $v;
    } else {
      my @split = split /=/, $v;
      
      if (scalar @split > 1) {
        $renderer = pop @split;
        $key      = join '=', @split;
      } else {
        $key      = $split[0];
        $renderer = 'normal';
      }
    }
   
    if ($key =~ /^(\w+)[\.:](.*)$/) {
      my ($type, $p) = ($1, $2);
      
      if ($type eq 'url') {
        my $menu_name   = $hub->param('menu');
        my $all_formats = $hub->species_defs->multi_val('DATA_FORMAT_INFO');
        
        if (!$format) {
          $p = uri_unescape($p);
          
          my @path = split(/\./, $p);
          my $ext  = $path[-1] eq 'gz' ? $path[-2] : $path[-1];
          
          while (my ($name, $info) = each %$all_formats) {
            if ($ext =~ /^$name$/i) {
              $format = $name;
              last;
            }  
          }
          if (!$format) {
            # Didn't match format name - now try checking format extensions
            while (my ($name, $info) = each %$all_formats) {
              if ($ext eq $info->{'ext'}) {
                $format = $name;
                last;
              }  
            }
          }
        }

        my $style = $all_formats->{lc $format}{'display'} eq 'graph' ? 'wiggle' : $format;
        my $code  = join '_', md5_hex("$species:$p"), $session->session_id;
        my $n;
        
        if ($menu_name) {
          $n = $menu_name;
        } else {
          $n = $p =~ /\/([^\/]+)\/*$/ ? $1 : 'un-named';
        }
        
        # Don't add if the URL or menu are the same as an existing track
        if ($session->get_data(type => 'url', code => $code)) {
          $session->add_data(
            type     => 'message',
            function => '_warning',
            code     => "duplicate_url_track_$code",
            message  => "You have already attached the URL $p. No changes have been made for this data source.",
          );
          
          next;
        } elsif (grep $_->{'name'} eq $n, $session->get_data(type => 'url')) {
          $session->add_data(
            type     => 'message',
            function => '_error',
            code     => "duplicate_url_track_$n",
            message  => qq{Sorry, the menu "$n" is already in use. Please change the value of "menu" in your URL and try again.},
          );
          
          next;
        }

        # We then have to create a node in the user_config
        my %ensembl_assemblies = %{$hub->species_defs->assembly_lookup};

        if (uc $format eq 'TRACKHUB') {
          my $info;
          ($n, $info) = $self->_add_trackhub($n, $p,1);
          if ($info->{'error'}) {
            my @errors = @{$info->{'error'}||[]};
            $session->add_data(
              type     => 'message',
              function => '_warning',
              code     => 'trackhub:' . md5_hex($p),
              message  => "There was a problem attaching trackhub $n: @errors",
            );
          }
          else {
            my $assemblies = $info->{'genomes'}
                        || {$hub->species => $hub->species_defs->get_config($hub->species, 'ASSEMBLY_VERSION')};

            foreach (keys %$assemblies) {
              my ($data_species, $assembly) = @{$ensembl_assemblies{$_}||[]};
              if ($assembly) {
                my $data = $session->add_data(
                  type        => 'url',
                  url         => $p,
                  species     => $data_species,
                  code        => join('_', md5_hex($n . $data_species . $assembly . $p), $session->session_id),
                  name        => $n,
                  format      => $format,
                  style       => $style,
                  assembly    => $assembly,
## EG          
                  %extra_params
##                  
                );
              }
            }
          }
        } else {
          $self->_add_flat_file_track(undef, 'url', "url_$code", $n, 
            sprintf('Data retrieved from an external webserver. This data is attached to the %s, and comes from URL: %s', encode_entities($n), encode_entities($p)),
            url   => $p,
            style => $style,
## EG            
            caption => $image_param{name},
            viewLimits => $viewLimits,
##            
          );

          ## Assume the data is for the current assembly
          my $assembly;
          while (my($a, $info) = each (%ensembl_assemblies)) {
            $assembly = $info->[1] if $info->[0] eq $species;
            last if $assembly;
          }
 
          $self->update_track_renderer("url_$code", $renderer);
          $session->set_data(
            type      => 'url',
            url       => $p,
            species   => $species,
            code      => $code,
            name      => $n,
            format    => $format,
            style     => $style,
            assembly  => $assembly,
## EG          
            %extra_params
##           
          );
        }
        # We have to create a URL upload entry in the session
        my $message  = sprintf('Data has been attached to your display from the following URL: %s', encode_entities($p));
        if (uc $format eq 'TRACKHUB') {
          $message .= " Please go to '<b>Configure this page</b>' to choose which tracks to show (we do not turn on tracks automatically in case they overload our server).";
        }
        $session->add_data(
          type     => 'message',
          function => '_info',
          code     => 'url_data:' . md5_hex($p),
          message  => $message,
        );
      } elsif ($type eq 'das') {
        $p = uri_unescape($p);

        my $logic_name = $session->add_das_from_string($p, $self->{'type'}, { display => $renderer });

        if ($logic_name) {
          $session->add_data(
            type     => 'message',
            function => '_info',
            code     => 'das:' . md5_hex($p),
            message  => sprintf('You have attached a DAS source with DSN: %s %s.', encode_entities($p), $self->get_node("das_$logic_name") ? 'to this display' : 'but it cannot be displayed on the specified image')
          );
        }
      }
    } else {
      $self->update_track_renderer($key, $renderer, $hub->param('toggle_tracks'));
    }
  }
  
  if ($self->is_altered) {
    my $tracks = join(', ', @{$self->altered});
    $session->add_data(
      type     => 'message',
      function => '_info',
      code     => 'image_config',
      message  => "The link you followed has made changes to these tracks: $tracks.",
    );
  }
}

sub add_somatic_mutations {
  my ($self, $key, $hashref) = @_;
  my $menu = $self->get_node('somatic');
#EG ENSEMBL-2442 remove this track from config when there are no somatic variants
  my $count = 0;
#EG
  
  return unless $menu;
  
  my $somatic = $self->create_submenu('somatic_mutation', 'Somatic variants');
  my %options = (
    db         => $key,
    glyphset   => '_variation',
    strand     => 'r',
    depth      => 0.5,
    bump_width => 0,
    colourset  => 'variation',
    display    => 'off',
    renderers  => [ 'off', 'Off', 'normal', 'Normal (collapsed for windows over 200kb)', 'compact', 'Collapsed', 'labels', 'Expanded with name (hidden for windows over 10kb)', 'nolabels', 'Expanded without name' ],
  );
  
  # All sources
  $somatic->append($self->create_track("somatic_mutation_all", "Somatic variants (all sources)", {
    %options,
    caption     => 'Somatic variants (all sources)',
    description => 'Somatic variants from all sources'
  }));
  
   
  # Mixed source(s)
  foreach my $key_1 (keys(%{$self->species_defs->databases->{'DATABASE_VARIATION'}{'SOMATIC_MUTATIONS'}})) {
    if ($self->species_defs->databases->{'DATABASE_VARIATION'}{'SOMATIC_MUTATIONS'}{$key_1}{'none'}) {
      (my $k = $key_1) =~ s/\W/_/g;
      $somatic->append($self->create_track("somatic_mutation_$k", "$key_1 somatic variants", {
        %options,
        caption     => "$key_1 somatic variants",
        source      => $key_1,
        description => "Somatic variants from $key_1"
      }));
      $count++; #EG
    }
  }
  
  # Somatic source(s)
  foreach my $key_2 (sort grep { $hashref->{'source'}{'somatic'}{$_} == 1 } keys %{$hashref->{'source'}{'somatic'}}) {
    next unless $hashref->{'source'}{'counts'}{$key_2} > 0;
    
    $somatic->append($self->create_track("somatic_mutation_$key_2", "$key_2 somatic mutations (all)", {
      %options,
      caption     => "$key_2 somatic mutations (all)",
      source      => $key_2,
      description => "All somatic variants from $key_2"
    }));
    
    my $tissue_menu = $self->create_submenu('somatic_mutation_by_tissue', 'Somatic variants by tissue');
    
    ## Add tracks for each tumour site
    my %tumour_sites = %{$self->species_defs->databases->{'DATABASE_VARIATION'}{'SOMATIC_MUTATIONS'}{$key_2} || {}};
    
    foreach my $description (sort  keys %tumour_sites) {
      next if $description eq 'none';
      
      my $phenotype_id           = $tumour_sites{$description};
      my ($source, $type, $site) = split /\:/, $description;
      my $formatted_site         = $site;
      $site                      =~ s/\W/_/g;
      $formatted_site            =~ s/\_/ /g;
      
      $tissue_menu->append($self->create_track("somatic_mutation_${key_2}_$site", "$key_2 somatic mutations in $formatted_site", {
        %options,
        caption     => "$key_2 $formatted_site tumours",
        filter      => $phenotype_id,
        description => $description
      }));    
      $count++; #EG
    }
    
    $somatic->append($tissue_menu);
  }
  
#EG ENSEMBL-2442 remove this track from config when there are no somatic variants
  if($count){
    $menu->append($somatic);
  }
  else {return undef;}
}

sub add_repeat_features {
  my ($self, $key, $hashref) = @_;
  my $menu = $self->get_node('repeat');
  
  return unless $menu && $hashref->{'repeat_feature'}{'rows'} > 0;
  
  my $data    = $hashref->{'repeat_feature'}{'analyses'};
  my %options = (
    glyphset    => '_repeat',
    optimizable => 1,
    depth       => 0.5,
    bump_width  => 0,
    strand      => 'r',
  );
  
  $menu->append($self->create_track("repeat_$key", 'All repeats', {
    db          => $key,
    logic_names => [ undef ], # All logic names
    types       => [ undef ], # All repeat types
    name        => 'All repeats',
    description => 'All repeats',
    colourset   => 'repeat',
    display     => 'off',
    renderers   => [qw(off Off normal On)],
    %options
  }));
  
  my $flag    = keys %$data > 1;
  my $colours = $self->species_defs->colour('repeat');
  
  foreach my $key_2 (sort { $data->{$a}{'name'} cmp $data->{$b}{'name'} } keys %$data) {
    if ($flag) {
      # Add track for each analysis
      $self->generic_add($menu, $key, "repeat_${key}_$key_2", $data->{$key_2}, {
        logic_names => [ $key_2 ], # Restrict to a single supset of logic names
        types       => [ undef  ],
        colours     => $colours,
        description => $data->{$key_2}{'desc'},
        display     => 'off',
        name => exists $data->{$key_2}->{web}->{name} ? $data->{$key_2}->{web}->{name} : $data->{$key_2}->{'name'},
        caption     => $data->{$key_2}->{'name'},
        %options
      });
    }
    
    my $d2 = $data->{$key_2}{'types'};
    
    if (keys %$d2 > 1) {
      foreach my $key_3 (sort keys %$d2) {
        my $n  = $key_3;
           $n .= " ($data->{$key_2}{'name'})" unless $data->{$key_2}{'name'} eq 'Repeats';
         
        # Add track for each repeat_type;        
        $menu->append($self->create_track('repeat_' . $key . '_' . $key_2 . '_' . $key_3, $n, {
          db          => $key,
          logic_names => [ $key_2 ],
          types       => [ $key_3 ],
          name        => $n,
          colours     => $colours,
          description => "$data->{$key_2}{'desc'} ($key_3)",
          display     => 'off',
          renderers   => [qw(off Off normal On)],
          %options
        }));
      }
    }
  }
}

1;
