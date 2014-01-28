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

# $Id: Image.pm,v 1.7 2012-07-27 12:51:45 nl2 Exp $

package EnsEMBL::Web::Document::Image;

sub render {
  my ($self, $format) = @_;

  return unless $self->drawable_container;

  if ($format) {
    print $self->drawable_container->render($format);
    return;
  }

  my $html    = $self->introduction;
  my $image   = new EnsEMBL::Web::TmpFile::Image;
  my $content = $self->drawable_container->render('png');
  my $caption_style  = 'image-caption';

  $image->content($content);
  $image->save;
  
  my ($top_toolbar, $bottom_toolbar) = $self->has_toolbars ? $self->render_toolbar($image->height) : ();
  
  if ($self->button eq 'form') {
    my $image_html = $self->render_image_button($image);
    my $inputs;
    
    $self->{'hidden'}{'total_height'} = $image->height;
    
    $image_html .= sprintf '<div class="%s">%s</div>', $caption_style, $self->caption if $self->caption;
    
    foreach (keys %{$self->{'hidden'}}) {
      $inputs .= sprintf(
        '<input type="hidden" name="%s" id="%s%s" value="%s" />', 
        $_, 
        $_, 
        $self->{'hidden_extra'} || $self->{'counter'}, 
        $self->{'hidden'}{$_}
      );
    }
    
    $html .= sprintf(
      $self->centred ? 
        '<div class="autocenter_wrapper"><form style="width:%spx" class="autocenter" action="%s" method="get"><div>%s</div><div class="autocenter">%s</div></form></div>' : 
        '<form style="width:%spx" action="%s" method="get"><div>%s</div>%s%s%s</form>',
      $image->width,
      $self->{'URL'},
      $inputs,
      $top_toolbar,
      $image_html,
      $bottom_toolbar,
    );
    
    $self->{'counter'}++;
  } elsif ($self->button eq 'yes') {
    $html .= $self->render_image_button($image);
    $html .= sprintf '<div class="%s">%s</div>', $caption_style, $self->caption if $self->caption;
  } elsif ($self->button eq 'drag') {
    my $img = $self->render_image_tag($image);

    # continue with tag html
    # This has to have a vertical padding of 0px as it is used in a number of places
    # butted up to another container - if you need a vertical padding of 10px add it
    # outside this module
    
    my $export;
    
    if ($self->{'export'}) {
      my @formats = (
        { f => 'pdf',     label => 'PDF' },
        { f => 'svg',     label => 'SVG' },
        { f => 'eps',     label => 'PostScript' },
      );
      ## PNG renderer will crash if image too tall!
      unless ($image->height > 32000) {
        push @formats, { f => 'png-10',  label => 'PNG (x10)' };
      }
      push @formats, (
        { f => 'png-5',   label => 'PNG (x5)' },
        { f => 'png-2',   label => 'PNG (x2)' },
        { f => 'png',     label => 'PNG' },
        { f => 'png-0.5', label => 'PNG (x0.5)' },
        { f => 'gff',     label => 'text (GFF)', text => 1 }
      );
      
      my $url = $ENV{'REQUEST_URI'};
      $url =~ s/;$//;
      $url .= ($url =~ /\?/ ? ';' : '?') . 'export=';
      
      for (@formats) {
        my $href = $url . $_->{'f'};
        
        if ($_->{'text'}) {
          next if $self->{'export'} =~ /no_text/;
          
          $export .= qq{<div><a href="$href" style="width:9em" rel="external">Export as $_->{'label'}</a></div>};
        } else {
          $export .= qq{<div><a href="$href;download=1" style="width:9em" rel="external">Export as $_->{'label'}</a><a class="view" href="$href" rel="external">[view]</a></div>};
        }
      }
      
      $export = qq{
        <div class="$self->{'export'}" style="width:$image->{'width'}px; white-space: nowrap;"><a class="print_hide" href="${url}pdf">Export image</a></div>
        <div class="iexport_menu">$export</div>
      };
    }
    
    my $wrapper = sprintf('
      %s
      <div class="drag_select" style="margin:%s;">
        %s
        %s
        %s
        %s
      </div>
      %s',
      $top_toolbar,
      $self->centred ? '0px auto' : '0px',
      $img,
      $self->imagemap eq 'yes' ? $self->render_image_map($image) : '',
      $self->moveable_tracks($image),
      $self->hover_labels,
      $bottom_toolbar,
    );

    my $template = $self->centred ? '
      <div class="image_container" style="width:%spx;text-align:center">
        <div style="text-align:center;margin:auto">
          %s
          %s
        </div>
      </div>
    ' : '
      <div class="image_container" style="width:%spx">
        %s
        %s
      </div>
        %s
    ';
 
    $html .= sprintf $template, $image->width, $wrapper, $self->caption ? sprintf '<div class="%s">%s</div>', $caption_style, $self->caption : '';
  
  } else {
    $html .= join('',
      $self->render_image_tag($image),
      $self->imagemap eq 'yes' ? $self->render_image_map($image) : '',
      $self->moveable_tracks($image),
      $self->hover_labels,
      $self->caption ? sprintf('<div class="%s">%s</div>', $caption_style, $self->caption) : ''
    );
  }

  $html .= $self->tailnote;
  
  if ($self->{'image_configs'}[0]) {
    $html .= qq(<input type="hidden" class="image_config" value="$self->{'image_configs'}[0]{'type'}" />);
    $html .= '<span class="hidden drop_upload"></span>' if $self->{'image_configs'}[0]->get_node('user_data');
  }
  
  $self->{'width'} = $image->width;
  $self->hub->species_defs->timer_push('Image->render ending', undef, 'draw');
  
  return $html;
}

1;
