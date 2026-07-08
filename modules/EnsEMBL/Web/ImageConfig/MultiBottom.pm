=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ImageConfig::MultiBottom;

use strict;

use parent qw(EnsEMBL::Web::ImageConfig::MultiSpecies);

sub init_cacheable {
  ## @override
  my $self = shift;

  $self->SUPER::init_cacheable(@_);

  $self->set_parameters({
    image_resizeable  => 1,
    sortable_tracks   => 1,  # allow the user to reorder tracks
    opt_lines         => 1,  # register lines
    spritelib         => { default => $self->species_defs->ENSEMBL_WEBROOT . '/htdocs/img/sprites' },
  });

  my $sp_img = $self->species_defs->SPECIES_IMAGE_DIR;
  if(-e $sp_img) {
    $self->set_parameters({ spritelib => {
      %{$self->get_parameter('spritelib')||{}},
      species => $sp_img,
    }});
  }

  # Add menus in the order you want them for this display
  $self->create_menus(qw(
    sequence
    marker
    transcript
    prediction
    dna_align_cdna
    dna_align_est
    dna_align_rna
    dna_align_other
    protein_align
    rnaseq
    simple
    misc_feature
    variation
    somatic
    functional
    oligo
    repeat
    user_data
    decorations
    information
  ));

  # Add in additional tracks
  $self->load_tracks;

  $self->add_tracks('sequence',
    [ 'contig', 'Contigs',  'contig',   { display => 'normal', strand => 'r', description => 'Track showing underlying assembly contigs' }],
    [ 'seq',    'Sequence', 'sequence', { display => 'normal', strand => 'b', description => 'Track showing sequence in both directions. Only displayed at 1Kb and below.', colourset => 'seq', threshold => 1, depth => 1 }],
  );

  $self->add_tracks('decorations',
    [ 'scalebar',  '', 'scalebar',      { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',         { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable',     { display => 'normal', strand => 'b', menu => 'no' }],
    [ 'nav',       '', 'navigation',    { display => 'normal', strand => 'b', menu => 'no' }],
## EG ENSEMBL-2967 - add species label     
    [ 'title',     '', 'species_title', { display => 'normal', strand => 'b', menu => 'no' }],
##    
  );
  
  $_->set_data('display', 'off') for grep $_->id =~ /^chr_band_/, $self->get_node('decorations')->nodes; # Turn off chromosome bands by default
}

sub multi {
  my ($self, $methods, $chr, $pos, $total,$all_slices, @slices) = @_;
  my $prodname        = $self->hub->species_defs->get_config($self->{'species'}, 'SPECIES_PRODUCTION_NAME');
  my $multi_hash      = $self->species_defs->multi_hash;
  my $p               = $pos == $total && $total > 2 ? 2 : 1;
  my ($i, %alignments, @strands);
  my $slice_summary = join(' ',map {
    join(':',$_->[0],$_->[1]->seq_region_name,$_->[1]->start,$_->[1]->end)
  } map { [$_->{'species'},$_->{'slice'}] } @$all_slices);

  my $intra_species_key = "$prodname--$chr";
  foreach my $db (@{$self->species_defs->compara_like_databases || []}) {
    next unless exists $multi_hash->{$db};

    my @all_alignments = (
      values %{$multi_hash->{$db}{'ALIGNMENTS'} || {}},
      @{$self->hub->intra_species_alignments($db, $prodname, $chr)}
    );

    foreach (@all_alignments) {

      next unless $methods->{$_->{'type'}};
      next unless $_->{'class'} =~ /pairwise_alignment/;
      next unless $_->{'species'}{$prodname} || $_->{'species'}{$intra_species_key};

      my %align = %$_; # Make a copy for modification

      my $align_species_size = scalar keys %{$align{'species'}};

      $i = $p;
      foreach (@slices) {
        my ($check_species, $check_chr) = split('--', $_->{'species_check'});
        my $check_prodname  = $self->species_defs->get_config($check_species, 'SPECIES_PRODUCTION_NAME');
        my $check_key       = $check_chr ? $check_prodname.'--'.$check_chr : $check_prodname;

        my $match_found = 0;
        if ($check_prodname eq $prodname) {

          if ($align{'species'}{$check_key}
                &&
                (
                  ($align_species_size == 2 && $check_key ne $intra_species_key)
                  ||
                  ($align_species_size == 1 && $check_key eq $intra_species_key)
                )
             ) {
            $match_found = 1;
          }
        } else {
          if ($align{'species'}{$check_prodname}) {
            $match_found = 1;
          }
        }

        if ($match_found) {
          $align{'order'} = $i;
          $align{'ori'}   = $_->{'strand'};
          $align{'gene'}  = $_->{'g'};
          last;
        }
        $i++;
      }

      next unless $align{'order'};
      $align{'db'} = lc substr $db, 9;
      push @{$alignments{$align{'order'}}}, \%align;
      $self->set_parameter('homologue', $align{'homologue'});
    }
  }

  if (scalar keys %alignments) {

    %alignments = %{$self->select_alignment_based_on_hierarchy(\%alignments)};

    if ($pos == 1) {
      @strands = $total == 2 ? qw(r) : scalar keys %alignments == 2 ? qw(f r) : [keys %alignments]->[0] == 1 ? qw(f) : qw(r);
    } elsif ($pos == $total) {
      @strands = qw(f);
    } elsif ($pos == 2) {
      @strands = qw(r);
    } else {
      @strands = qw(r f);
    }

    $alignments{2} = $alignments{1} if $pos != 1 && scalar @strands == 2 && scalar keys %alignments == 1;

    my $decorations = $self->get_node('decorations');

    foreach (sort keys %alignments) {
      my $strand = shift @strands;

      foreach my $align (sort { $a->{'type'} cmp $b->{'type'} } @{$alignments{$_}}) {
        my ($other_species) = grep $_ ne $prodname, keys %{$align->{'species'}};

        my $glyphset = $align->{'type'} =~ /CACTUS_HAL/ ? 'cactus_hal' : '_alignment_pairwise';

        $decorations->before(
          $self->create_track("$align->{'id'}:$align->{'type'}:$_", $align->{'name'}, {
            glyphset                   => $glyphset,
            colourset                  => 'pairwise',
            name                       => $align->{'name'},
            species                    => [split '--', $other_species]->[0],
            strand                     => $strand,
            display                    => $methods->{$align->{'type'}},
            db                         => $align->{'db'},
            type                       => $align->{'type'},
            ori                        => $align->{'ori'},
            method_link_species_set_id => $align->{'id'},
            target                     => $align->{'target_name'},
            join                       => 1,
            menu                       => 'no',
            slice_summary              => $slice_summary,
            flip_vertical              => 1,
          })
        );
      }
    }
  }

  $self->add_tracks('information',
    [ 'gene_legend', 'Gene Legend','gene_legend', {  display => 'normal', strand => 'r', accumulate => 'yes' }],
    [ 'variation_legend', 'Variant Legend','variation_legend', {  display => 'normal', strand => 'r', accumulate => 'yes' }],
    [ 'fg_regulatory_features_legend',   'Reg. Features Legend', 'fg_regulatory_features_legend',   { display => 'normal', strand => 'r', colourset => 'fg_regulatory_features'   }],
    [ 'fg_methylation_legend', 'Methylation Legend', 'fg_methylation_legend', { strand => 'r' } ],
    [ 'structural_variation_legend', 'Structural Variant Legend', 'structural_variation_legend', { strand => 'r' } ],
  );
  $self->modify_configs(
    [ 'gene_legend', 'variation_legend','fg_regulatory_features_legend', 'fg_methylation_legend', 'structural_variation_legend' ],
    { accumulate => 'yes' }
  );
}

1;
