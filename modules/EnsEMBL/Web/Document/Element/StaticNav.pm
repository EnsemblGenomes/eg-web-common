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

# $Id: StaticNav.pm,v 1.3 2013-11-27 14:59:59 jh15 Exp $

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
  my $here        = $ENV{'SCRIPT_NAME'};
  (my $pathstring = $here) =~ s/^\///; ## Remove leading slash
  my @path        = split '/', $pathstring;
  my $img_url     = $self->img_url;
  my $config      = $self->hub->session->get_data(type => 'nav', code => 'static') || {};
  (my $dir        = $here) =~ s/^\/(.+\/)*(.+)\.(.+)$/$1/;                                 ## Strip filename from current location - we just want directory
  my $this_tree   = $dir eq 'info/' ? $tree : $self->walk_tree($tree, $dir, \@path, 1);    ## Recurse into tree until you find current location
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
  
  ## ----- IN-PAGE NAVIGATION ------------

  ## Read the current file and parse out h2 headings with ids
  my $content    = EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $here);
  my $doc        = HTML::TreeBuilder->new_from_content($content);
  my @headers    = $doc->find('h2');
  my @id_headers = grep $_->attr('id'), @headers; ## Check the headers have id attribs we can link to
  
  ## Create submenu from these headers
  if (scalar @id_headers) {
    my $last = $id_headers[-1];
    
    $in_page .= sprintf('
      <div class="subheader">On this page</div>
      <ul class="local_context" style="border-width:0">
        %s
      </ul>',
      join('', map sprintf('<li class="%s"><img src="%sleaf.gif"><a href="#%s">%s</a></li>', $_ eq $last ? 'last' : 'top_level', $img_url, $_->attr('id'), $_->as_text), @id_headers)
    );
  }
  
  ## OPTIONAL 'RELATED CONTENT' SECTION ---------------
  
  if ($this_tree->{'_rel'}) {
    my $content = EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $this_tree->{'_rel'});
    
    if ($content) {
      my @links = split '\n', $content;
      my $last  = $links[-1];
      
      $related .= sprintf('
        <div class="subheader">Related content</div>
        <ul class="local_context" style="border-width:0">
          %s
        </ul>',
        join('', map sprintf('<li class="%s"><img src="%sleaf.gif">%s</li>', $_ eq $last ? 'last' : 'top_level', $img_url, $_), @links)
      );
    }
  }
  
  ## SEARCH -------------------------------------------
## EG doc search 
  if (-e $SiteDefs::DOCSEARCH_INDEX_DIR) {
    my $form = EnsEMBL::Web::Form->new({'action' => '/info/search/index.html', 'method' => 'get', 'skip_validation' => 1, 'class' => [ 'search-form', 'clear' ]});
  
    # search input box & submit button
    my $field = $form->add_field({
      inline   => 1,
      elements => [{
        type       => 'string',
        value      => 'Search documentation&#8230;',
        is_encoded => 1,
        id         => 'q',
        size       => '20',
        name       => 'q',
        class      => [ 'query', 'input', 'inactive' ]
      }, {
        type  => 'submit',
        value => 'Go'
      }]
    });
    
    $search = sprintf('
      <div class="js_panel" style="margin:16px 0 0 8px">
        <input type="hidden" class="panel_type" value="SearchBox" />
        %s
      </div>
    ', $form->render);
  }
##  

  return qq{
    <input type="hidden" class="panel_type" value="LocalContext" />
    <div class="header">In this section</div>
    <ul class="local_context">
      $menu
    </ul>
    $in_page
    $related
    $search
  };
}


1;
