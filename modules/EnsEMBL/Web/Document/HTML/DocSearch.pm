package EnsEMBL::Web::Document::HTML::DocSearch;
use strict;

use EnsEMBL::Web::Hub;
use Lucy::Simple;
use URI::Escape;
use Data::Page;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self  = shift;
  my $hub   = EnsEMBL::Web::Hub->new;
  my $query = $hub->param('q');
  my $page = $hub->param('page') || 1;
  my $page_size = 10;
  my $index_dir = $SiteDefs::DOCSEARCH_INDEX_DIR;
  
  return $self->error('The search index is not configured') if !$index_dir;
  return $self->error('The search index does not exist') if !-d $index_dir; 
  return "<p>Please enter a query term</p>" if !$query;
    
  my $index = Lucy::Simple->new( path => $index_dir, language => 'en' );
  my $offset = $page_size * ($page - 1);
  my $hit_count = $index->search(
    query      => $query,
    offset     => $offset,
    num_wanted => $page_size,
  );
  
  return "<p>Your query <strong>$query</strong> did not match any documents</p>" if !$hit_count;
  
  my $pager = Data::Page->new();
  $pager->total_entries($hit_count);
  $pager->entries_per_page($page_size);
  $pager->current_page($page);
  
  my $html = "<h2>Your search for '$query' returned $hit_count results.</h2>";
  
  if  ($hit_count > $page_size) { 
    $html .= sprintf "<h3>Showing results %s-%s</h3>", $pager->first, $pager->last;
  }
  
  while ( my $hit = $index->next ) {
    my $title = $hit->{title} || $hit->{url};
    my $snippet = $self->highlight($self->snippet($hit->{body}, 200), $query) || 'no description available';
    my $display_url = $self->highlight($hit->{url}, $query);
    $html .= qq{
      <div class="hit">
        <a href="/info/$hit->{url}" class="name"><strong>$title</strong></a>
        <br /><a href="/info/$hit->{url}" class="url">/info/$display_url</a>
        <br/ >$snippet
      </div>
    };
  }
  
  $html = qq{<div class="searchresults" style="margin-left:0">$html</div>};
   
  $html .= $self->render_pagination($query, $hit_count, $pager);
  
  return $html;
}

sub render_pagination {
  my ($self, $query, $hit_count, $pager) = @_;

  return if !$query or $hit_count <= 10;

  my $html;
  
  if ( $pager->previous_page) {
    $html .= sprintf( '<a class="prev" href="?q=%s;page=%s">< Prev</a> ', uri_escape($query), $pager->previous_page  );
  }
  
  foreach my $i (1..$pager->last_page) {
    if( $i == $pager->current_page ) {
      $html .= sprintf( '<span class="current">%s</span> ', $i );
    } elsif( $i < 5 || ($pager->last_page - $i) < 4 || abs($i - $pager->current_page + 1) < 4 ) {
      $html .= sprintf( '<a href="?q=%s;page=%s">%s</a>', uri_escape($query), $i, $i );
    } else {
      $html .= '..';
    }
  }
  
  $html =~ s/\.\.+/ ... /g;
  
  if ($pager->next_page) {
    $html .= sprintf( '<a class="next" href="?q=%s;page=%s">Next ></a> ', uri_escape($query), $pager->next_page);
  }
  
  return qq{<h4><div class="paginate">$html</div></h4>};
}

sub snippet {
  my ($self, $snippet, $len) = @_; 
  if ($len and length($snippet) > $len) {
    $snippet = substr($snippet, 0, $len);
    $snippet =~ s/\W+[\w]*$//; # take it back to last whole word
    $snippet .= " <strong>...</strong>";
  }
  return $snippet;
}

sub highlight {
  my ($self, $string, $q) = @_;
  $q =~ s/('|"|\(|\)|\|\+|-|\*)//g; # remove lucene operator chars
  my @terms = grep {$_ and $_ !~ /^AND|OR|NOT$/i} split /\s/, $q; # ignore lucene operator words
  $string =~ s/(\Q$_\E)/<em><strong>$1<\/strong><\/em>/ig foreach @terms;
  return $string;
}

sub error {
  my ($self, $message) = @_;
  return qq{<div class="error" style="padding:0 10px;"><p>Error: $message</p></div>};
}

1;
