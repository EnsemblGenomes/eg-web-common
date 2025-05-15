=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ImageConfigExtension::Tracks;

### An Extension to EnsEMBL::Web::ImageConfig
### Methods to load default tracks

package EnsEMBL::Web::ImageConfig;

use strict;
use warnings;
no warnings qw(uninitialized);

use previous qw (add_genes);

our $pretty_method = {
  BLASTZ_NET          => 'BlastZ',
  LASTZ_NET           => 'LastZ',
  TRANSLATED_BLAT_NET => 'Translated Blat',
  SYNTENY             => 'Synteny',
  ATAC                => 'ATAC',
};

sub add_genes {
  my $self = shift;

  $self->PREV::add_genes(@_);

  # If this is an alignslice track in a large-scale CACTUS_DB alignment
  # view, disable selected tracks in order to reduce load times.
  if ($self->type eq 'alignsliceviewbottom') {

    my $align_id = exists $self->hub->referer->{'params'}{'align'}
                 ? $self->hub->referer->{'params'}{'align'}[0]
                 : $self->hub->get_alignment_id
                 ;

    if ($align_id) {
      my $align_details = $self->species_defs->multi_hash->{'DATABASE_COMPARA'}->{'ALIGNMENTS'}->{$align_id};
      if ($align_details->{'type'} eq 'CACTUS_DB' && exists $align_details->{'as_track_threshold_data'}) {
        my $location_param = $self->hub->referer->{'params'}{'r'}[0];

        my $location_length;
        if ($location_param =~ /^[\w\.\-]+:(\d+)\-(\d+)$/) {  # region pattern from MetaKeyFormat datacheck
          $location_length = abs($2 - $1) + 1;
        } else {
          $location_length = 1;  # This should never happen, but if it does, we revert to default behaviour.
        }

        my $as_track_thresholds = $align_details->{'as_track_threshold_data'};
        if (exists $as_track_thresholds->{'transcript'} && $location_length >= $as_track_thresholds->{'transcript'}) {

          # At large scales, disable transcript tracks.
          $self->modify_configs(['transcript'], { 'display' => 'off' });

          if (exists $as_track_thresholds->{'sequence'} && $location_length >= $as_track_thresholds->{'sequence'}) {
            # At larger scales still, disable sequence tracks.
            $self->modify_configs(['sequence'], { 'display' => 'off' });
          }
        }
      }
    }
  }
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
      next if $self->get_node("${type}_$_");
      next if $type ne ($data->{$_}{'type'} || 'feature'); # Don't separate by db in this case

      $self->_add_track($menu, $key, "${type}_$_", $data->{$_}, {
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
    glyphset    => 'repeat',
    depth       => 0.5,
    bump_width  => 0,
    strand      => 'r',
  );

  $menu->append_child($self->create_track_node("repeat_$key", 'All repeats', {
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
      $self->_add_track($menu, $key, "repeat_${key}_$key_2", $data->{$key_2}, {
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
        $menu->append_child($self->create_track_node('repeat_' . $key . '_' . $key_2 . '_' . $key_3, $n, {
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
