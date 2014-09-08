=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use base qw(EnsEMBL::Web::ImageConfig::MultiSpecies);


sub init {
  my $self = shift;
  
  $self->set_parameters({
    sortable_tracks => 1,  # allow the user to reorder tracks
    opt_lines       => 1,  # register lines
    spritelib       => { default => $self->species_defs->ENSEMBL_WEBROOT . '/htdocs/img/sprites' },
  });
  my $sp_img_48 = $self->species_defs->ENSEMBL_WEBROOT . '/../public-plugins/ensembl/htdocs/i/species/48'; # XXX make configurable
  if(-e $sp_img_48) {
    $self->set_parameters({ spritelib => {
      %{$self->get_parameter('spritelib')||{}},
      species => $sp_img_48,
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
  $self->load_configured_das;
  $self->image_resize = 1;
    
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
  
  $_->set('display', 'off') for grep $_->id =~ /^chr_band_/, $self->get_node('decorations')->nodes; # Turn off chromosome bands by default
}

sub multi {
  my ($self, $methods, $chr, $pos, $total, @slices) = @_;
  my $sp              = $self->{'species'};
  my $multi_hash      = $self->species_defs->multi_hash;
  my $primary_species = $self->hub->species;
  my $p               = $pos == $total && $total > 2 ? 2 : 1;
  my ($i, %alignments, @strands);
  
  foreach my $db (@{$self->species_defs->compara_like_databases || []}) {
    next unless exists $multi_hash->{$db};

## EG   
    my $intra_species_alignments = $self->hub->intra_species_alignments($db, $sp, $chr);

    foreach (values %{$multi_hash->{$db}{'ALIGNMENTS'}}, @$intra_species_alignments) {
##
      next unless $methods->{$_->{'type'}};
      next unless $_->{'class'} =~ /pairwise_alignment/;
      next unless $_->{'species'}{$sp} || $_->{'species'}{"$sp--$chr"};
      
      my %align = %$_; # Make a copy for modification
      
      $i = $p;
      
      foreach (@slices) {
        if ($align{'species'}{$_->{'species'} eq $sp ? $_->{'species_check'} : $_->{'species'}} && !($_->{'species_check'} eq $primary_species && $sp eq $primary_species)) {
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
  
  if ($pos == 1) {
    @strands = $total == 2 ? qw(r) : scalar keys %alignments == 2 ? qw(f r) : [keys %alignments]->[0] == 1 ? qw(f) : qw(r); # Primary species
  } elsif ($pos == $total) {
    @strands = qw(f);   # Last species - show alignments on forward strand.
  } elsif ($pos == 2) {
    @strands = qw(r);   # First species where $total > 2
  } else {
    @strands = qw(r f); # Secondary species in the middle of the image
  }
  
  # Double up for non primary species in the middle of the image
  $alignments{2} = $alignments{1} if $pos != 1 && scalar @strands == 2 && scalar keys %alignments == 1;
  
  my $decorations = $self->get_node('decorations');
  
  foreach (sort keys %alignments) {
    my $strand = shift @strands;
    
    foreach my $align (sort { $a->{'type'} cmp $b->{'type'} } @{$alignments{$_}}) {
      my ($other_species) = grep $_ ne $sp, keys %{$align->{'species'}};
      
      $decorations->before(
        $self->create_track("$align->{'id'}:$align->{'type'}:$_", $align->{'name'}, {
          glyphset                   => '_alignment_pairwise',
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
          menu                       => 'no'
        })
      );
    }
  }
}

1;
