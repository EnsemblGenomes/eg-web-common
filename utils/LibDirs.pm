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

our $SERVERROOT;
our $WEBROOT;

BEGIN {
  $SERVERROOT = find_server_root();
  $WEBROOT    = "$SERVERROOT/ensembl-webcode";
  
  unshift @INC, "$WEBROOT";
  unshift @INC, "$WEBROOT/conf";
  
  require SiteDefs;
  map{ unshift @INC, $_ } (
    "$SERVERROOT/eg-web-common/modules",
    "$SERVERROOT/ensemblgenomes-api/modules",
    @SiteDefs::ENSEMBL_LIB_DIRS,
  );

  
  # Find the webroot by stepping up the dir tree looking for 
  # the dir containing 'ensembl-webcode'
  
  sub find_server_root {
    my $root = $Bin;
    my $found    = 0;

    while (!$found and $root ne '/') {
      if (-d "$root/ensembl-webcode") {
        $found = 1;
      } else {
        $root = abs_path("$root/../");
      }
    }
    
    die "Cannot locate SERVERROOT dir" if !$found;
    
    return $root;
  }
}

1;