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

