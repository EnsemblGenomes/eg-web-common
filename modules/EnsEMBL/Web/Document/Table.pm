# $Id: Table.pm,v 1.1 2012-08-02 12:17:15 it2 Exp $

package EnsEMBL::Web::Document::Table;

sub process {
  my $self        = shift;
  my $columns     = $self->{'columns'};
  my @row_colours = $self->{'options'}{'data_table'} ? () : exists $self->{'options'}{'rows'} ? @{$self->{'options'}{'rows'}} : ('bg1', 'bg2');
  my (@head, @body);
  
  foreach my $col (@$columns) {
    
    # EG - ENSEMBL-1618, Download CSV fix:
    $col->{'title'} =~ s/<.*?>// if exists $col->{'title'};
    $col->{'key'} =~ s/<.*?>// if exists $col->{'key'};
    # EG
    my $label = exists $col->{'title'} ? $col->{'title'} : $col->{'key'};
    my %style = $col->{'style'} ? ref $col->{'style'} eq 'HASH' ? %{$col->{'style'}} : map { s/(^\s+|\s+$)//g; split ':' } split ';', $col->{'style'} : ();
    
    $style{'text-align'} ||= $col->{'align'} if $col->{'align'};
    $style{'width'}      ||= $col->{'width'} if $col->{'width'};
    
    $col->{'style'}  = join ';', map { join ':', $_, $style{$_} } keys %style;
    $col->{'class'} .= ($col->{'class'} ? ' ' : '') . "sort_$col->{'sort'}" if $col->{'sort'};
    $col->{'title'}  = $col->{'help'} if $col->{'help'};
    
    push @{$head[0]}, sprintf '<th%s>%s</th>', join('', map { $col->{$_} ? qq( $_="$col->{$_}") : () } qw(id class title style colspan rowspan)), $label;
  }
  
  $head[1] = ' class="ss_header"';
  
  foreach my $row (@{$self->{'rows'}}) {
    my ($options, @cells) = ref $row eq 'HASH' ? ($row->{'options'}, map $row->{$_->{'key'}}, @$columns) : ({}, @$row);
    my $i = 0;
    
    if (scalar @row_colours) {
      $options->{'class'} .= ($options->{'class'} ? ' ' : '') . $row_colours[0];
      push @row_colours, shift @row_colours
    }
    
    foreach my $cell (@cells) {
      $cell = { value => $cell } unless ref $cell eq 'HASH';
      
      my %style = $cell->{'style'} ? ref $cell->{'style'} eq 'HASH' ? %{$cell->{'style'}} : map { s/(^\s+|\s+$)//g; split ':' } split ';', $cell->{'style'} : ();
      
      $style{'text-align'} ||= $columns->[$i]{'align'} if $columns->[$i]{'align'};
      $style{'width'}      ||= $columns->[$i]{'width'} if $columns->[$i]{'width'};
      
      $cell->{'style'} = join ';', map { join ':', $_, $style{$_} } keys %style;
      
      $cell = sprintf '<td%s>%s</td>', join('', map { $cell->{$_} ? qq( $_="$cell->{$_}") : () } qw(id class title style colspan rowspan)), $cell->{'value'};
      
      $i++;
    }
    
    push @body, [ \@cells, join('', map { $options->{$_} ? qq( $_="$options->{$_}") : () } qw(id class style valign)) ];
  }
  
  return (\@head, \@body);
}
   
1;
