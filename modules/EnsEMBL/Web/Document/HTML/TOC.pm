# $Id: TOC.pm,v 1.6 2013-12-05 12:02:37 jh15 Exp $

package EnsEMBL::Web::Document::HTML::TOC;

use strict;

sub render {
  my $self              = shift;
  my $tree              = $self->hub->species_defs->STATIC_INFO;
  (my $location         = $ENV{'SCRIPT_NAME'}) =~ s/index\.html$//;
  my @toplevel_sections = map { ref $tree->{$_} eq 'HASH' ? $_ : () } keys %$tree;
  my %html              = ( left => '', middle => '', right => '' );

  my @section_order = sort {
    $tree->{$a}{'_order'} <=> $tree->{$b}{'_order'} ||
    $tree->{$a}{'_title'} cmp $tree->{$b}{'_title'} ||
    $tree->{$a}           cmp $tree->{$b}
  } @toplevel_sections;
  
  foreach my $dir (grep { !/^_/ && keys %{$tree->{$_}} } @section_order) {
    next if $dir eq 'sitemap.html';
    my $column      = 'left';  
    my $section     = $tree->{$dir};
    if ($dir eq 'genome' || $dir eq 'about') {
      $column = 'middle';
    }
    elsif ($dir eq 'docs' || $dir eq 'data') {
      $column = 'right';
    }
    
    my $title        = $section->{'_title'} || ucfirst $dir;
        # EG:
#       next unless $title =~ /Using this website|Accessing Ensembl Data|About the Ensembl Genomes project|Ensembl Genomes Documentation/;
        # EG
    my @second_level = @{$self->create_links($section, ' class="bold"')};

    $html{$column} .= $self->heading_html($dir,$title);
 
    if (scalar @second_level) {
      $html{$column} .= '<ul>';
  
      foreach my $entry (@second_level) {
        my $link = $entry->{'link'};

        ## One more level!
        my $subsection  = $entry->{'key'};
        my @third_level = @{$self->create_links($subsection)};
        
        if (scalar @third_level) {
          $link .= '<ul>';
          $link .= "<li>$_->{'link'}</li>\n" for @third_level;
          $link .= '</ul>';
        }

        $html{$column} .= "<li>$link</li>\n";
      }      
      
      $html{$column} .= '</ul>';
    }
    
    $html{$column} .= '</div>';
  }

  $html{$_} = sprintf(q(<div class="column-three"><div class="column-padding%s">%s</div></div>), $_ eq 'middle' ? '' : " no-$_-margin", $html{$_}) for grep $html{$_}, keys %html; # no-left-margin, no-right-margin

  return qq(<div class="column-wrapper">
              $html{'left'}
              $html{'middle'}
              $html{'right'}
            </div>);
}

sub create_links {
  my ($self, $level, $attribs) = @_;
  my $links = [];
    
  ## Do we have subpages/dirs, or just metadata?
  my @sublevel = map { ref $level->{$_} eq 'HASH' ? $_ : () } keys %$level;
    
  if (scalar @sublevel) {
    my @sub_order = sort { 
      $level->{$a}{'_order'} <=> $level->{$b}{'_order'} ||
      $level->{$a}{'_title'} cmp $level->{$b}{'_title'} ||
      $level->{$a}           cmp $level->{$b}
    } @sublevel;
    
    foreach my $sub (grep { !/^_/ && keys %{$level->{$_}} } @sub_order) {
      my $pages = $level->{$sub};
      my $path  = $pages->{'_path'} || "$level->{'_path'}$sub";
      my $title = $pages->{'_title'} || ucfirst $sub;
        
      # eg:
      next if $title =~ /^(Changes to Ensembl Mailing List|Api|Core|External_data|Extend|Docs)$/;
      # eg 
      push @$links, { key => $pages, link => qq(<a href="$path" title="$title"$attribs>$title</a>) };
    }
  }

  return $links;
}

1;
