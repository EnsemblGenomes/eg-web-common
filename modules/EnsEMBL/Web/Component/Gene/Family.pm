package EnsEMBL::Web::Component::Gene::Family;

sub jalview_link {
  my ($self, $family, $type, $refs, $cdb) = @_;
  my $count = @$refs;
  my $ckey = ($cdb =~ /pan/) ? '_pan_compara' : '';
  my $url   = $self->hub->url({ function => "Alignments$ckey", family => $family });
### EG : we dont have cigar lines for this view
#  return qq(<p class="space-below">$count $type members of this family <a href="$url">JalView</a></p>);
  return qq(<p class="space-below">$count $type members of this family</p>);
}

1;
