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

sub menus {
  my $self  = shift;
  my $menus = $self->PREV::menus(@_);
  my $add   = {
    dna_align_rna          => [ 'RNA alignments', 'mrna_prot' ],

    ms_domain              => 'Mass spectrometry peptides',
    
    # community annotation
    cap                    => [ 'WebApollo gene models', 'gene_transcript' ],

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

sub _add_flat_file_track {
  my ($self, $menu, $sub_type, $key, $name, $description, %options) = @_;

  $menu ||= $self->get_node('user_data');

  return unless $menu;

  my ($strand, $renderers, $default) = $self->_user_track_settings($options{'style'}, $options{'format'});

  my $track = $self->create_track($key, $name, {
    display         => 'off',
    strand          => $strand,
    external        => 'external',
    glyphset        => 'flat_file',
    colourset       => 'userdata',
## EG    
    caption         => $options{caption} || $name,
##
    sub_type        => $sub_type,
    renderers       => $renderers,
    default_display => $default,
    description     => $description,
    %options
  });

  $menu->append($track) if $track;
}

sub add_protein_features {
  my ($self, $key, $hashref) = @_;

  # We have three separate glyphsets in this in this case
  # P_feature, P_domain, P_ms_domain - plus domains get copied onto gsv_domain as well
  my %menus = (
    domain     => [ 'domain',    'P_domain',    'normal' ],
    feature    => [ 'feature',   'P_feature',   'normal' ],
## EG    
    ms_domain  => [ 'ms_domain', 'P_ms_domain', 'normal' ],
##
    alignment  => [ 'alignment', 'P_domain',    'off'    ],
    gsv_domain => [ 'domain',    'gsv_domain',  'normal' ]
  );

  return unless grep $self->get_node($_), keys %menus;

  my ($keys, $data) = $self->_merge($hashref->{'protein_feature'});

  foreach my $menu_code (keys %menus) {
    my $menu = $self->get_node($menu_code);
    
    next unless $menu;
    
    my $type     = $menus{$menu_code}[0];
    my $gset     = $menus{$menu_code}[1];
    my $renderer = $menus{$menu_code}[2];
    
    foreach (@$keys) {
      next if $self->tree->get_node("${type}_$_");
      next if $type ne ($data->{$_}{'type'} || 'feature'); # Don't separate by db in this case
      
      $self->generic_add($menu, $key, "${type}_$_", $data->{$_}, {
        glyphset  => $gset,
        colourset => 'protein_feature',
        display   => $renderer,
        depth     => 1e6,
        strand    => $gset =~ /P_/ ? 'f' : 'b',
      });
    }
  }
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
## EG
        name => exists $data->{$key_2}->{web}->{name} ? $data->{$key_2}->{web}->{name} : $data->{$key_2}->{'name'},
        caption     => $data->{$key_2}->{'name'},
##
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
        $type        = 'TBLAT';
        $menu_key    = 'pairwise_tblat';
        $description = 'Trans. BLAT net pairwise alignments';
      } else {
        $type        = ucfirst lc $row->{'type'};
        $type        =~ s/\W/ /g;
        $menu_key    = 'pairwise_other';
        $description = 'Pairwise alignments';
      }
      
      $description  = qq{<a href="$static" class="cp-external">$description</a> between $self_label and $other_label};
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

sub load_configured_mw       { shift->load_file_format('mw');       }
sub load_configured_msa      { shift->load_file_format('msa');      }
sub load_configured_bed      { shift->load_file_format('bed');      }
sub load_configured_bedgraph { shift->load_file_format('bedgraph'); }
sub load_configured_gff      { shift->load_file_format('gff');      }
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
      display       => $source->{'display'} || 'signal',
      description   => $description,
      external_link => $source->{'external_link'},
   );
}

sub _add_gff_track {
  my ($self, %args) = @_;

  my $source = $args{source};

  $self->_add_flat_file_track($args{menu}, 'url', $args{key}, $source->{'source_name'},
    $args{description} ||
    sprintf('
      Data retrieved from an external webserver. This data is attached to the %s, and comes from URL: <a href="%s">%s</a>',
      encode_entities($source->{'source_type'}), 
      encode_entities($source->{'source_url'}),
      encode_entities($source->{'source_url'})
    ),
    url         => $source->{'source_url'},
    format      => 'gff3',
    display     => $args{display} || 'off',
    description => $args{description},
    type        => 'url'
  );
}

1;
