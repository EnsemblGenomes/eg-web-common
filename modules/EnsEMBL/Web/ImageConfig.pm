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
  return $_[0]->{'menus'} ||= {
    # Sequence
    seq_assembly        => 'Sequence and assembly',
    sequence            => [ 'Sequence',          'seq_assembly' ],
    misc_feature        => [ 'Clones',            'seq_assembly' ],
    genome_attribs      => [ 'Genome attributes', 'seq_assembly' ],
    marker              => [ 'Markers',           'seq_assembly' ],
    simple              => [ 'Simple features',   'seq_assembly' ],
    ditag               => [ 'Ditag features',    'seq_assembly' ],
    dna_align_other     => [ 'GRC alignments',    'seq_assembly' ],
    
    # Transcripts/Genes
    gene_transcript     => 'Genes and transcripts',
    transcript          => [ 'Genes',                  'gene_transcript' ],
    prediction          => [ 'Prediction transcripts', 'gene_transcript' ],
    lrg                 => [ 'LRG transcripts',        'gene_transcript' ],
    rnaseq              => [ 'RNASeq models',          'gene_transcript' ],
    
    # Supporting evidence
    splice_sites        => 'Splice sites',
    evidence            => 'Evidence',
    
    # Alignments
    mrna_prot           => 'mRNA and protein alignments',
    dna_align_cdna      => [ 'mRNA alignments',    'mrna_prot' ],
    dna_align_est       => [ 'EST alignments',     'mrna_prot' ],
    protein_align       => [ 'Protein alignments', 'mrna_prot' ],
    protein_feature     => [ 'Protein features',   'mrna_prot' ],
    rnaseq_bam          => [ 'RNASeq study',       'mrna_prot' ],
    dna_align_rna       => 'ncRNA',
    
    # Proteins
    domain              => 'Protein domains',
    gsv_domain          => 'Protein domains',
    feature             => 'Protein features',
    
    # Variations
    variation           => 'Variation',
    somatic             => 'Somatic mutations',    
    ld_population       => 'Population features',
    
    # Regulation
    functional          => 'Regulation',
    
    # Compara
    compara             => 'Comparative genomics',
    pairwise_blastz     => [ 'BLASTz/LASTz alignments',    'compara' ],
    pairwise_other      => [ 'Pairwise alignment',         'compara' ],
    pairwise_tblat      => [ 'Translated blat alignments', 'compara' ],
    multiple_align      => [ 'Multiple alignments',        'compara' ],
    conservation        => [ 'Conservation regions',       'compara' ],
    synteny             => 'Synteny',
    
    # Other features
    repeat              => 'Repeat regions',
    oligo               => 'Oligo probes',
    trans_associated    => 'Transcript features',
    
    # Info/decorations
    information         => 'Information',
    decorations         => 'Additional decorations',
    other               => 'Additional decorations',
    
    # External data
    user_data           => 'Your data',
    external_data       => 'External data',
  };
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

sub add_sequence_variations {
  my ($self, $key, $hashref) = @_;
  my $menu = $self->get_node('variation');
    
  return unless $menu && $hashref->{'variation_feature'}{'rows'} > 0;

  my %options = (
    db         => $key,
    glyphset   => '_variation',
    strand     => 'r',
    depth      => 0.5,
    bump_width => 0,
    colourset  => 'variation',
    renderers   => [off => 'Off', histogram => 'Density', normal => 'Compact'],   # This is the only change in this function
    display    => 'off'
  );
  
  my $sequence_variation = $self->create_submenu('sequence_variations', 'Sequence variants');
  
  $sequence_variation->append($self->create_track("variation_feature_$key", 'Sequence variants (all sources)', {
    %options,
    sources     => undef,
    description => 'Sequence variants from all sources',
  }));
  
  foreach my $key_2 (sort keys %{$hashref->{'source'}{'counts'} || {}}) {
    next unless $hashref->{'source'}{'counts'}{$key_2} > 0;
    next if     $hashref->{'source'}{'somatic'}{$key_2} == 1;
    
    (my $k = $key_2) =~ s/\W/_/g;

    # EG/1KG fix for ESP tracks:
    my $vf_track = {};
    $vf_track->{caption} = $key_2 =~ /^ESP$/ ? 'Exome Sequencing Project' : $key_2;
    $vf_track->{sources} = $key_2 =~ /^ESP$/ ? 'NHLBI GO Exome Sequencing Project' : $key_2;

    $sequence_variation->append($self->create_track("variation_feature_${key}_$k", $vf_track->{caption}." variations", {
      %options,
      caption     => $vf_track->{caption},  
      sources     => [ $vf_track->{sources} ],     
      description => $hashref->{'source'}{'descriptions'}{$key_2},
    }));
    # EG/1KG
  }
  
  $menu->append($sequence_variation);

  $self->add_track('information', 'variation_legend', 'Variation Legend', 'variation_legend', { strand => 'r' });
  
  # add in variation sets
  if ($hashref->{'variation_set'}{'rows'} > 0) {
    my $variation_sets = $self->create_submenu('variation_sets', 'Variation sets');
    
    $menu->append($variation_sets);
  
    foreach my $toplevel_set (sort { $a->{'name'} cmp $b->{'name'} && (scalar @{$a->{'subsets'}} ? 1 : 0) <=> (scalar @{$b->{'subsets'}} ? 1 : 0) } values %{$hashref->{'variation_set'}{'supersets'}}) {
      my $name          = $toplevel_set->{'name'};
      my $caption       = $name . (scalar @{$toplevel_set->{'subsets'}} ? ' (all data)' : '');
      (my $key = $name) =~ s/\W/_/g;
      
      my $set_variation = scalar @{$toplevel_set->{'subsets'}} ? $self->create_submenu("set_variation_$key", $name) : $variation_sets;
      
      $set_variation->append($self->create_track("variation_set_$key", $caption, {
        %options,
        caption     => $caption,
        sources     => undef,
        sets        => [ $name ],
        set_name    => $name,
        description => $toplevel_set->{'description'},
      }));
  
      # add in sub sets
      if (scalar @{$toplevel_set->{'subsets'}}) {
        foreach my $subset_id (sort @{$toplevel_set->{'subsets'}}) {
          my $sub_set_name        = $hashref->{'variation_set'}{'subsets'}{$subset_id}{'name'}; 
          my $sub_set_description = $hashref->{'variation_set'}{'subsets'}{$subset_id}{'description'};
          (my $sub_set_key = $sub_set_name) =~ s/\W/_/g;
          
          $set_variation->append($self->create_track("variation_set_$sub_set_key", $sub_set_name, {
            %options,
            caption     => $sub_set_name,
            sources     => undef,
            sets        => [ $sub_set_name ],
            set_name    => $sub_set_name,
            description => $sub_set_description
          }));
        }
       
        $variation_sets->append($set_variation);
      }
    }
  }
}

sub add_das_tracks {
  my ($self, $menu, $source, $extra) = @_;
  my $node = $self->get_node($menu); 
  
  if (!$node && grep { $menu eq "${_}_external" } @{$self->{'transcript_types'}}) {
    for (@{$self->{'transcript_types'}}) {
      $node = $self->get_node("${_}_external");
      last if $node;
    }
  }
  
  $node ||= $self->get_node('external_data'); 
  
  return unless $node;
  
  my $caption  = $source->caption || $source->label;
  my $desc     = $source->description;
  my $homepage = $source->homepage;
  
  $desc .= sprintf ' [<a href="%s" rel="external">Homepage</a>]', $homepage if $homepage;
  
  my $track = $self->create_track('das_' . $source->logic_name, $source->label, {
    %{$extra || {}},
    external    => 'external',
## EG @ added P_protdas
    glyphset    => $self->{type} eq 'protview' ? 'P_protdas' : '_das',
## EG
    display     => 'off',
    logic_names => [ $source->logic_name ],
    caption     => $caption,
    description => $desc,
    renderers   => [
      'off',      'Off', 
      'nolabels', 'No labels', 
      'normal',   'Normal', 
      'labels',   'Labels'
    ],
  });
  
  if ($track) {
    $node->append($track);
    $self->has_das ||= 1;
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
     url     => $source->{'source_url'},
     format  => $source->{'format'} || 'bed',
     display => $source->{'display'} || 'normal',
     description => $description
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
      url     => $source->{'source_url'},
      format  => 'BEDGRAPH',
      style   => 'wiggle',
      display => $source->{'display'} || 'tiling',
      description => $description
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
  my $datahubs = $self->get_parameter('datahubs') == 1;
  my (%url_sources, %upload_sources);
  
  $self->_load_url_feature($menu);

  foreach my $source (sort { ($a->caption || $a->label) cmp ($b->caption || $b->label) } values %$das) {
    my $node = $self->get_node('das_' . $source->logic_name);

    next if     $node && $node->get('node_type') eq 'track';
    next unless $source->is_on($self->{'type'});
    
    $self->add_das_tracks('user_data', $source);
  }

  # Get the tracks that are temporarily stored - as "files" not in the DB....
  # Firstly "upload data" not yet committed to the database...
  # Then those attached as URLs to either the session or the User
  # Now we deal with the url sources... again flat file
  foreach my $entry ($session->get_data(type => 'url')) {
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
        file        => $entry->{'filename'},
        format      => $entry->{'format'},
        caption     => $entry->{'name'},
        renderers   => $renderers,
        description => 'Data that has been temporarily uploaded to the web server.',
        display     => 'off',
        strand      => $strand,
      }));
    }
  }
  
  if ($user) {
    my @groups = $user->get_groups;

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

  foreach my $code (sort { $url_sources{$a}{'source_name'} cmp $url_sources{$b}{'source_name'} } keys %url_sources) {
    my $add_method = lc "_add_$url_sources{$code}{'format'}_track";
    
    if ($self->can($add_method)) {
      $self->$add_method(
        key      => $code,
        menu     => $menu,
        source   => $url_sources{$code},
        external => 'user'
      );
    } elsif (lc $url_sources{$code}{'format'} eq 'datahub') {
      $self->_add_datahub($url_sources{$code}{'source_name'}, $url_sources{$code}{'source_url'}, $code) if $datahubs;
    } else {
      $self->_add_flat_file_track($menu, 'url', $code, $url_sources{$code}{'source_name'},
        sprintf('
          Data retrieved from an external webserver. This data is attached to the %s, and comes from URL: %s',
          encode_entities($url_sources{$code}{'source_type'}), encode_entities($url_sources{$code}{'source_url'})
        ),
        url      => $url_sources{$code}{'source_url'},
        format   => $url_sources{$code}{'format'},
        style    => $url_sources{$code}{'style'},
        external => 'user',
      );
    }
  }
  
  # We now need to get a userdata adaptor to get the analysis info
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
      
  if ($style =~ /^(wiggle|WIG)$/) {
    $strand         = 'r';
## EG
    @user_renderers = ('off', 'Off', 'tiling', 'Wiggle plot', 'gradient', 'Gradient', 'pvalue', 'P-value');
##
  } else {
    $strand         = uc($format) eq 'VEP_INPUT' ? 'f' : 'b'; 
    @user_renderers = (@{$self->{'alignment_renderers'}}, 'difference', 'Differences');
  }
  
  return ($strand, \@user_renderers);
}

sub _add_file_format_track {
  my ($self, %args) = @_;
  my $menu = $args{'menu'} || $self->get_node('user_data');
  
  return unless $menu;
  
  %args = $self->_add_datahub_extras_options(%args) if $args{'source'}{'datahub'};
  
  my $type    = lc $args{'format'};
  my $article = $args{'format'} =~ /^[aeiou]/ ? 'an' : 'a';
  my $desc;
  
  if ($args{'internal'}) {
    $desc = "Data served from a $args{'format'} file: $args{'description'}";
  } else {
    $desc = sprintf(
      'Data retrieved from %s %s file on an external webserver. %s This data is attached to the %s, and comes from URL: %s',
      $article,
      $args{'format'},
      $args{'description'},
      encode_entities($args{'source'}{'source_type'}), 
      encode_entities($args{'source'}{'source_url'})
    );
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
    my $url_string = $array [0];
    my %image_param = split /\//, $array[1];
    
    my $viewLimits = $hub->param('viewLimits');
##
      
    my $format = $hub->param('format');
    my ($key, $renderer);
    
    if (uc $format eq 'DATAHUB') {
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
        my $all_formats = $hub->species_defs->DATA_FORMAT_INFO;
        
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
        
        # We have to create a URL upload entry in the session
        $session->set_data(
          type    => 'url',
          url     => $p,
          species => $species,
          code    => $code, 
          name    => $n,
          format  => $format,
          style   => $style,
## EG          
          colour     => $image_param{colour},
          strand     => $image_param{strand},
          caption    => $image_param{name},
          viewLimits => $viewLimits,
##
        );
        
        $session->add_data(
          type     => 'message',
          function => '_info',
          code     => 'url_data:' . md5_hex($p),
          message  => sprintf('Data has been attached to your display from the following URL: %s', encode_entities($p))
        );
        
        # We then have to create a node in the user_config
        if (uc $format eq 'DATAHUB') {
          $self->_add_datahub($n, $p);
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
          $self->update_track_renderer("url_$code", $renderer);
        }       
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
  
  if ($self->altered) {
    $session->add_data(
      type     => 'message',
      function => '_info',
      code     => 'image_config',
      message  => 'The link you followed has made changes to the tracks displayed on this page.',
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
1;
