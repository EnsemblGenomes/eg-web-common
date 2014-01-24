package EnsEMBL::Web::Document::Element::Logo;

use strict;

sub content {
  my $self   = shift;
  my $url    = $self->href || $self->home_url;
  my $hub    = $self->hub;
  my $type   = $hub->type;
  my $e_logo = '<img src="/i/e.png" alt="Ensembl Genomes Home" title="Ensembl Genomes Home" class="print_hide" style="width:43px;height:40px" />'; 

  if ($type eq 'Help') {
    return sprintf( '%s%s%s',
      $e_logo, $self->logo_img, $self->logo_print
    );
  } 

  return sprintf( '%s<a href="%s">%s</a>%s%s',
    $self->e_logo, $url, $self->logo_img, $self->logo_print, $self->site_menu
  );
}

sub logo_img {
### a
  my $self = shift;
  return sprintf(
    '<img src="%s%s" alt="%s" title="%s" class="print_hide" style="width:%spx;height:%spx" />',
    $self->img_url, $self->image, $self->alt, $self->alt, $self->width, $self->height
  );
}

sub e_logo {
### a
  my $self = shift;
  my $alt = 'Ensembl Genomes Home';
  return sprintf(
    '<a href="%s"><img src="%s%s" alt="%s" title="%s" class="print_hide" style="width:%spx;height:%spx" /></a>',
    'http://www.ensemblgenomes.org/', $self->img_url, 'e.png', $alt, $alt, 43, 40
  );
}

sub site_menu {
  return q{
    <span class="print_hide">
      <span id="site_menu_button">&#9660;</span>
      <ul id="site_menu" style="display:none">
        <li><a href="http://www.ensemblgenomes.org">Ensembl Genomes</a></li>
        <li><a href="http://bacteria.ensembl.org">Ensembl Bacteria</a></li>
        <li><a href="http://protists.ensembl.org">Ensembl Protists</a></li>
        <li><a href="http://fungi.ensembl.org">Ensembl Fungi</a></li>
        <li><a href="http://plants.ensembl.org">Ensembl Plants</a></li>
        <li><a href="http://metazoa.ensembl.org">Ensembl Metazoa</a></li>
        <li><a href="http://www.ensembl.org">Ensembl (vertebrates)</a></li>
      </ul>
    </span>
  };
}

1;
