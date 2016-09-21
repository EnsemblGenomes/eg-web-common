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

package EnsEMBL::Web::ImageConfigExtension::UserTracks;

### An Extension to EnsEMBL::Web::ImageConfig
### Methods to load tracks from custom data/files/urls etc

package EnsEMBL::Web::ImageConfig;

use strict;
use warnings;
no warnings qw(uninitialized);

sub _add_flat_file_track {
  my ($self, $menu, $sub_type, $key, $name, $description, $options) = @_;

  my ($strand, $renderers, $default) = $self->_user_track_settings($options->{'style'}, $options->{'format'});

  #$options->{'display'} = $self->check_threshold($options->{'display'});

  my $track = $self->create_track_node($key, $name, {
    display         => 'off',
    strand          => $strand,
    external        => 'external',
    glyphset        => 'flat_file',
    colourset       => 'userdata',
## EG    
    caption         => $options->{caption} || $name,
##
    sub_type        => $sub_type,
    renderers       => $renderers,
    default_display => $default,
    description     => $description,
    %$options
  });

  $menu->append_child($track) if $track;
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
    renderers => $renderers,
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

  my $track = $self->create_track_node($key, $sname, {
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
  $self->_add_flat_file_track($menu, 'url', $args{'key'}, $source->{'source_name'}, $description, {
     url             => $source->{'source_url'},
     format          => $source->{'format'} || 'bed',
     display         => $source->{'display'} || 'normal',
     description     => $description,
     external_link   => $source->{'external_link'}
  });
}

sub _add_bedgraph_track {
  my ($self,%args) = @_;
  my $menu = $args{'menu'};
  my $source = $args{'source'};
  my $description = $source->{'description'} || 
     sprintf('Data retrieved from an external webserver. This data and comes from URL: %s', encode_entities($source->{'source_url'}));
  $self->_add_flat_file_track($menu, 'url', $args{'key'}, $source->{'source_name'}, $description, {
    url           => $source->{'source_url'},
    format        => 'BEDGRAPH',
    style         => 'wiggle',
    display       => $source->{'display'} || 'signal',
    description   => $description,
    external_link => $source->{'external_link'},
  });
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
    {
      url         => $source->{'source_url'},
      format      => 'gff3',
      display     => $args{display} || 'off',
      description => $args{description},
      type        => 'url'
    }
  );
}

1;
