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

package EnsEMBL::Web::Tools::RobotsTxt;

use strict;

use Sys::Hostname;
use File::Path qw(make_path);

sub _lines { # utility
  my $type = shift;
  my $lines = join("\n",map { "$type: $_" } @_);
  return sprintf("%s%s\n",($type eq 'User-agent')?"\n":'',$lines);
}

sub _box {
  my $text = shift;
  return join("\n",'-' x length $text,$text,'-' x length $text,'');
}

sub create {
  ### This is to try and stop search engines killing e! - it gets created each
  ### time on server startup and gets placed in the first directory in the htdocs
  ### tree.
  ### Returns: none
  my $species = shift;
  my $sd      = shift;
  my $root    = $sd->ENSEMBL_HTDOCS_DIRS->[0];
  my @allowed = @{$sd->ENSEMBL_EXTERNAL_SEARCHABLE||[]};
  
  #check if directory for creating .cvsignore and robots.txt exist
  make_path($root) unless(-e $root);

  my %ignore = qw(robots.txt 1 .cvsignore 1);
  if( -e "$root/.cvsignore" ) {
    open I, "$root/.cvsignore";
    while(<I>) {
      $ignore{$1}=1 if/(\S+)/;
    }
    close I;
  }
  warn _box("Placing .cvsignore and robots.txt into $root");

  open O, ">$root/.cvsignore";
  print O join "\n", sort keys %ignore;
  close O;

  my $server_root = $sd->ENSEMBL_SERVERROOT;
  unless(open FH, ">$root/robots.txt") {
    warn _box("UNABLE TO CREATE ROBOTS.TXT FILE IN $root/");
    return;
  }

  if(-e "$server_root/htdocs/sitemaps/sitemap-index.xml" and hostname =~ /(ves-oy|ves-pg)/) {

    # If we have a sitemap we need a less-restrictive robots.txt, so
    # that the crawler can use the sitemap.
    warn _box("Creating robots.txt for google sitemap");

    print FH _lines("User-agent","*");
  
    print FH _lines("Allow",qw(*/Gene/Summary */Transcript/Summary));
  
    print FH _lines("Disallow",qw(
      /Multi/  /biomart/  /Account/  /ExternalData/  /UserAnnotation/
      */Ajax/  */Config/  */blastview/  */Export/  */Experiment/ */Experiment*
      */Gene/ */Location/  */LRG/  */Phenotype/  */Regulation/  */Search/ 
      */Share */Transcript/ */UserConfig/  */UserData/  */Variation/
    ));


    #old views
    print FH _lines("Disallow",qw(*/*view));

    #other misc views google bot hits
    print FH _lines("Disallow",qw(/id/));
    print FH _lines("Disallow",qw(/*/psychic));
  
    # links from ChEMBL
    print FH _lines("Disallow","/Gene/Summary");
    print FH _lines("Disallow","/Transcript/Summary");
    
    print FH _lines("Crawl-delay","20");
    
    print FH _lines("Sitemap","http://" . $sd->ENSEMBL_SERVERNAME . "/sitemap-index.xml");
    
  } else {
    
    # No sitemap, use restrictive robots.txt.
    if( @allowed ) {      
      print FH _lines("User-agent","*");
      print FH _lines("Disallow",qw(/Multi/  /biomart/));
      foreach my $sp ( @{$species||[]} ) {
        print FH _lines("Disallow","/$sp/");
        print FH _lines("Allow",map { "/$sp/$_" } @allowed);
      }
    } else {
      ## Allowed list is empty so we only allow access to the main
      ## index page... /index.html...
      print FH _lines("User-agent","*");
      print FH _lines("Disallow","/");
    }
    print FH _lines("User-agent","W3C-checklink");
    print FH _lines("Allow","/info");
    
  }
 
  # stop AhrefsBot indexing us (https://ahrefs.com/robot/)
  print FH _lines("User-agent","AhrefsBot");
  print FH _lines("Disallow","/");
  
  close FH;

  return;
}

1;
