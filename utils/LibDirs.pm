=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

#
# A utility to find and include the standard Ensembl lib dirs
#
# Use this module in your script to configure @INC 
# ready for use with the Ensembl codebase
#

package LibDirs;
use strict;

use FindBin qw($Bin);
use Cwd qw(abs_path);

our $WEBROOT;
our $SERVERROOT;

BEGIN {
  $WEBROOT    = find_web_root();
  $SERVERROOT = "$WEBROOT/ensembl-webcode";
  
  unshift @INC, "$SERVERROOT";
  unshift @INC, "$SERVERROOT/conf";
  
  require SiteDefs;
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;  
  
  # Find the webroot by stepping up the dir tree looking for 
  # the dir containing 'ensembl-webcode'
  
  sub find_web_root {
    my $web_root = $Bin;
    my $found    = 0;

    while (!$found and $web_root ne '/') {
      if (-d "$web_root/ensembl-webcode") {
        $found = 1;
      } else {
        $web_root = abs_path("$web_root/../");
      }
    }
    
    die "Cannot locate WEBROOT dir" if !$found;
    
    return $web_root;
  }
}

1;