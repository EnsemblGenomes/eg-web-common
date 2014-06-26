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

# $Id: Tabs.pm,v 1.4 2012-12-17 14:18:30 nl2 Exp $

package EnsEMBL::Web::Document::Element::Tabs;

sub init {
  my $self          = shift;
  my $controller    = shift;
  my $builder       = $controller->builder;
  my $object        = $controller->object;
  my $configuration = $controller->configuration;
  my $hub           = $controller->hub;
  my $type          = $hub->type;
  my $species_defs  = $hub->species_defs;  
  my @data;
  
  # add species tab if species selected
  if ($species_defs->valid_species($hub->species)) {
    push (@data, {
      class    => 'species',
      type     => 'Info',
      action   => 'Index',
      caption  => $species_defs->SPECIES_COMMON_NAME,
      dropdown => $species_defs->DISABLE_SPECIES_DROPDOWN ? 0 : 1
    });
  }

  $self->init_history($hub, $builder) if $hub->user;
  $self->init_species_list($hub);
  
  foreach (@{$builder->ordered_objects}) {
    my $o = $builder->object($_);
    push @data, { type => $_, action => $o->default_action, caption => $o->short_caption('global'), dropdown => !!($self->{'history'}{lc $_} || $self->{'bookmarks'}{lc $_} || $_ eq 'Location') } if $o;
  }
 
  push @data, { type => $object->type,        action => $object->default_action,        caption => $object->short_caption('global')       } if $object && !@data;
  push @data, { type => $configuration->type, action => $configuration->default_action, caption => $configuration->{'_data'}->{'default'} } if $type eq 'Location' && !@data;
  
  foreach my $row (@data) {
    next if $row->{'type'} eq 'Location' && $type eq 'LRG';
    
    my $class = $row->{'class'} || lc $row->{'type'};
    
    $self->add_entry({
      type     => $row->{'type'}, 
      caption  => $row->{'caption'},
      url      => $row->{'url'} || $hub->url({ type => $row->{'type'}, action => $row->{'action'} }),
      class    => $class . ($row->{'type'} eq $type ? ' active' : ''),
      dropdown => $row->{'dropdown'} ? $class : '',
      disabled => $row->{'disabled'}
    });
  }
}

sub init_species_list {
  my ($self, $hub) = @_;
  my $species      = $hub->species;
  my $species_defs = $hub->species_defs;
  
  my @valid_species = $species_defs->valid_species;

  $self->{'species_list'} = [ 
    sort { $a->[1] cmp $b->[1] } 
    map  [ $hub->url({ species => $_, type => 'Info', action => 'Index', __clear => 1 }), $species_defs->get_config($_, 'SPECIES_COMMON_NAME') ],
    @valid_species
  ];
  
  my $favourites = $hub->get_favourite_species;
  
  $self->{'favourite_species'} = [ map {[ $hub->url({ species => $_, type => 'Info', action => 'Index', __clear => 1 }), $species_defs->get_config($_, 'SPECIES_COMMON_NAME') ]} @$favourites ] if scalar @$favourites;
}

sub species_list {
  my $self      = shift;

  my $html;
  foreach my $sp (@{$self->{'species_list'}}) {
    $html .= qq{<li><a class="constant" href="$sp->[0]">$sp->[1]</a></li>};
  }
  
  return qq{<div class="dropdown species"><h4>Select a species</h4><ul>$html</ul></div>};
}

sub content {
  my $self  = shift;
  my $count = scalar @{$self->entries};
  
  return '' unless $count;
  
  my ($content, $short_tabs, $long_tabs);
  my @style   = $count > 4 ? () : (' style="display:none"', ' style="display:block"');
  my $history = 0;
  
  foreach my $entry (@{$self->entries}) {
    $entry->{'url'} ||= '#';
    
    my $name         = encode_entities($self->strip_HTML($entry->{'caption'}));
    my ($short_name) = split /\b/, $name;
    my $constant     = $entry->{'constant'} ? ' class="constant"' : '';
    my $short_link   = qq{<a href="$entry->{'url'}" title="$name"$constant>$short_name</a>};
    my $long_link    = qq{<a href="$entry->{'url'}"$constant>$name</a>};
    
    if ($entry->{'disabled'}) {
      my $span = $entry->{'dropdown'} ? qq{<span class="disabled toggle" title="$entry->{'dropdown'}">} : '<span class="disabled">';
      $_ = qq{$span$name</span>} for $short_link, $long_link;
    }
    
    if ($entry->{'dropdown'}) {
      # Location tab always has a dropdown because its history can be changed dynamically by the slider navigation.
      # Hide the toggle arrow if there are no bookmarks or history items for it.
      my @hide = $entry->{'type'} eq 'Location' && !($self->{'history'}{'location'} || $self->{'bookmarks'}{'location'}) ? (' empty', ' style="display:none"') : ();
      $history = 1;
      $_       = qq{<span class="dropdown$hide[0]">$_<a class="toggle" href="#" rel="$entry->{'dropdown'}"$hide[1]>&#9660;</a></span>} for $short_link, $long_link;
    }
    
    $short_tabs .= qq{<li class="$entry->{'class'} short_tab"$style[0]>$short_link</li>};
    $long_tabs  .= qq{<li class="$entry->{'class'} long_tab"$style[1]>$long_link</li>};
    
    $self->active($name) if $entry->{'class'} =~ /\bactive\b/;
  }
  
  $content  = $short_tabs . $long_tabs;
  $content  = qq{<ul class="tabs">$content</ul>} if $content;
  $content .= $self->species_list                if $self->{'species_list'};
  $content .= $self->history                     if $history;
  
  return $content;
}

1;
