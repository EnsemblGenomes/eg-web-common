package EnsEMBL::Web::Document::Element::Copyright;

### Copyright notice for footer (basic version with no logos)

use strict;

sub content {
  my $self = shift;

  my $sd = $self->species_defs;

  return sprintf( qq(
  <div class="twocol-left left">
		   %s release %d - %s
		  &copy; <span class="print_hide"><a href="http://www.ebi.ac.uk/" style="white-space:nowrap">EBI</a></span>
      <span class="screen_hide_inline">EBI</span>
  </div>),     $sd->SITE_NAME, $sd->SITE_RELEASE_VERSION, $sd->SITE_RELEASE_DATE
	       );
}

1;

