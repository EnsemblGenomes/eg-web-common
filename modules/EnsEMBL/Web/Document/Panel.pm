package EnsEMBL::Web::Document::Panel;

sub _caption_with_helplink {
    my $self    = shift;
    my $img_url = $self->hub ? $self->img_url : undef;
    my $id      = $self->{'help'};

    my $caption = $self->{'caption'};
    if ( $caption =~ /(Gene|Transcript): (\S+) \((.+?)\)/ ) {
      if ($2 eq $3) {
        $caption =~ s/ \(.+?\)//;
      }
    }

    my $html    = '<h2 class="caption">';
    $html      .= sprintf ' <a href="/Help/View?id=%s" class="popup help-header constant" title="Click for Help">', encode_entities($id) if $id;
    $html      .= $caption;
    $html      .= sprintf ' <img src="%shelp-button.png" style="width:40px;height:20px;padding-left:4px;vertical-align:middle" alt="(e?)" class="print_hide" /></a>', $img_url if $id && $img_url;
    $html      .= '</h2>';

    return $html;
}

1;
