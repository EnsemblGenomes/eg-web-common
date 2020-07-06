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

package EnsEMBL::Web::Document::Element::FatFooter;

### Optional fat footer - site-specific, so see plugins 

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  my $species_defs = shift->species_defs;
  my $sister_sites = '<p><a href="http://www.ensembl.org">Ensembl</a></p>';
  my $html = '<hr /><div id="fat-footer">';

  $html .= qq(
              <div class="column-four left">
                <h3>About Us</h3>
                <p><a href="/info/about/">About us</a></p>
                <p><a href="/info/about/contact/">Contact us</a></p>
                <p><a href="/info/about/publications.html">Citing Ensembl Genomes</a></p>
                <p><a href="https://www.ebi.ac.uk/data-protection/ensembl/privacy-notice">Privacy policy</a></p>
                <p><a href="/info/about/legal/">Disclaimer</a></p>
              </div>
  );


 $html .= qq(
              <div class="column-four left">
                <h3>Get help</h3>
                <p><a href="/info/website/">Using this website</a></p>
                <p><a href="/info/">Documentation</a></p>
                <p><a href="/info/website/upload/">Adding custom tracks</a></p>
                <p><a href="/info/data/">Downloading data</a></p>
              </div>
  );

  foreach("bacteria","fungi","plants","protists","metazoa"){
    $sister_sites .= qq(<p><a href="http://$_.ensembl.org">Ensembl ${\ucfirst($_)}</a></p>) if $species_defs->EG_DIVISION ne $_;
  }

  $html .= qq(
              <div class="column-four left">
                <h3>Our sister sites</h3>
                $sister_sites
              </div>
  );


  $html .= qq(
              <div class="column-four left">
                <h3>Follow us</h3>
                <p><a class="media-icon" href="http://www.ensembl.info/">
                  <img alt="[RSS logo]" title="Ensembl blog" src="/i/rss_icon_16.png"></a>
                  <a href="http://www.ensembl.info/">Blog</a></p>
                <p><a class="media-icon" href="https://twitter.com/ensemblgenomes">
                  <img alt="[twitter logo]" title="Follow us on Twitter!" src="/i/twitter.png"></a>
                    <a href="https://twitter.com/ensemblgenomes">Twitter</a></p>
              </div>
  );

  $html .= '</div>';

  return $html;
}

1;
