# $Id: Title.pm,v 1.6 2013-11-28 10:33:34 jh15 Exp $

package EnsEMBL::Web::Document::Element::Title;

sub init {
  my $self       = shift;
  my $controller = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  
  if ($controller->request eq 'ssi') {
    # eg:
    my $title = $species_defs->ENSEMBL_SITENAME;
    $title =~ s/Ensembl/Ensembl /;
#   $self->set($controller->content =~ /<title>(.*?)<\/title>/sm ? $1 : 'Untitled: ' . $controller->r->uri);
    $self->set($controller->content =~ /<title>(.*?)<\/title>/sm ? $title : 'Untitled: ' . $controller->r->uri);
    # eg
  } else {
    my $node = $controller->node;
    
    return unless $node;
    
    my $object       = $controller->object;
  # my $hub          = $self->hub;
  # my $species_defs = $hub->species_defs;
    my $caption;
    if ($object) {
      if (ref($object->caption) eq 'ARRAY') {
        $caption = $object->caption->[0];
        $caption .= ' ('.$object->caption->[1].')' if $object->caption->[1];
      }
      else {
        $caption = $object->caption;
      }
    }
    my $title        = $node->data->{'title'} || $node->data->{'concise'} || $node->data->{'caption'};
       $title        =~ s/\s*\(.*\[\[.*\]\].*\)\s*//;
    my $type  = $hub->type;

    # eg: 
    if ($type eq 'Help') {
      $self->set("Ensembl Genomes he!p");
    }
    # species home page:
    elsif($type eq 'Info' && $hub->action eq 'Index'){
      $self->set(sprintf('%s - %s', $species_defs->SPECIES_BIO_NAME, $species_defs->ENSEMBL_SITE_NAME));
    }
    else {
      $title .= " - $caption" if($caption && $title !~ /$caption/ );
      $title = " - $title" if ($title);
      $self->set(sprintf('%s: %s%s', $species_defs->ENSEMBL_SITE_NAME, $species_defs->SPECIES_BIO_NAME, $title));
    }    
    # eg

    ## Short title to be used in the bookmark link
    if ($hub->user) {

      if ($type eq 'Location' && $caption =~ /: ([\d,-]+)/) {
        (my $strip_commas = $1) =~ s/,//g;
        $caption =~ s/: [\d,-]+/:$strip_commas/;
      }
      
      $caption =~ s/Chromosome //          if $type eq 'Location';
      $caption =~ s/Regulatory Feature: // if $type eq 'Regulation';
      $caption =~ s/$type: //;
      $caption =~ s/\(.+\)$//;
      
      $self->set_short(sprintf '%s: %s%s', $species_defs->SPECIES_COMMON_NAME, $title, ($caption ? " - $caption" : ''));
    }
  }
}

1;
