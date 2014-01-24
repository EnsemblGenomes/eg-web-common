package EnsEMBL::Web::Document::Element::FooterLinks;

### Replacement footer links for www.ensembl.org

use strict;

sub content {

  return qq(
    <div class="twocol-right right">
      <a href="http://www.ensemblgenomes.org">About&nbsp;Ensembl Genomes</a> | 
      <a href="/info/about/contact/index.html">Contact&nbsp;Us</a> | 
      <a href="http://www.ebi.ac.uk/Information/termsofuse.html">EMBL-EBI Terms of use</a> | 
      <a href="http://www.ebi.ac.uk/Information/Privacy.html">Privacy</a> | 
      <a href="/info/about/cookies.html">Cookies</a> | 
      <a href="/info/website/help/index.html">Help</a> 
    </div>) 
  ;
}

1;

