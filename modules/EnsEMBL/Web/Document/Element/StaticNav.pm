=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

package EnsEMBL::Web::Document::Element::StaticNav;

# Container HTML for left sided navigation menu on static pages 

use strict;

use HTML::TreeBuilder;

use EnsEMBL::Web::Controller::SSI;
use EnsEMBL::Web::Form;

use base qw(EnsEMBL::Web::Document::Element::Navigation);

sub content {
  my $self = shift;
  
  ## LH MENU ------------------------------------------
  
  my $tree        = $self->species_defs->STATIC_INFO;
  my $img_url     = $self->img_url;
  my $config      = $self->hub->session->get_data(type => 'nav', code => 'static') || {};
  my $dir         = 'info/';                 
  my $this_tree   = $tree ;
  my @pages       = map { ref $this_tree->{$_} eq 'HASH' ? $_ : () } keys %$this_tree;
  my @page_order  = sort {
    $this_tree->{$a}{'_order'} <=> $this_tree->{$b}{'_order'} ||
    $this_tree->{$a}{'_title'} cmp $this_tree->{$b}{'_title'} ||
    $this_tree->{$a}           cmp $this_tree->{$b}
  } @pages;
  
  my $last_page = $page_order[-1];
  my ($menu, $in_page, $related, $search);
  
  foreach my $page (grep { !/^_/ && keys %{$this_tree->{$_}} } @page_order) {
    my $page_tree = $this_tree->{$page};
    next unless $page_tree->{'_title'};
    
    my $url         = $page_tree->{'_path'};
       $url        .= $page if $page =~ /html$/;

    $url = '/info/sitemap.html' if $page eq 'sitemap.html';

    (my $id         = $url) =~ s/\//_/g;
    my $class       = $page eq $last_page ? 'last' : 'top_level';
    my $state       = $config->{$page};
    my $toggle      = $state ? 'closed' : 'open';
    my $image       = "${img_url}leaf.gif";
    my @children    = grep !/^_/, keys %$page_tree;
    my @child_order = sort {
      $page_tree->{$a}{'_order'} <=> $page_tree->{$b}{'_order'} ||
      $page_tree->{$a}{'_title'} cmp $page_tree->{$b}{'_title'} ||
      $page_tree->{$a}           cmp $page_tree->{$b}
    } @children;
    
    my $submenu;
    
    if (scalar @children) {
      my $last   = $child_order[-1];
        $class  .= ' parent';
        $submenu = '<ul>';
      
      foreach my $child (@child_order) {
        next unless ref $page_tree->{$child} eq 'HASH' && $page_tree->{$child}{'_title'};
        $submenu .= sprintf '<li%s><img src="%s"><a href="%s%s">%s</a></li>', $child eq $last ? ' class="last"' : '', $image, $url, $child, $page_tree->{$child}{'_title'};
      }
      
      $submenu .= '</ul>';
      $image    = "$img_url$toggle.gif";
    }
    
    $menu .= qq{<li class="$class"><img src="$image" class="toggle $id" alt=""><a href="$url"><b>$page_tree->{'_title'}</b></a>$submenu</li>}; 
  }
  
  return qq{
    <input type="hidden" class="panel_type" value="LocalContext" />
    <div class="header">Help topics</div>
    <ul class="local_context">
      $menu
    </ul>
  };
}

1;

