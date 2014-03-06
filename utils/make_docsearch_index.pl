#!/usr/local/bin/perl
# Copyright [2009-2014] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use strict;
use warnings;
use FindBin qw($Bin);
use File::Find;
use Lucy::Simple;
use File::Path qw(make_path remove_tree);
use LibDirs;

my $index_dir = $SiteDefs::DOCSEARCH_INDEX_DIR || die '$SiteDefs::DOCSEARCH_INDEX_DIR is not set';

# Lucy doesn't like building the index directly on an nfs mount
# Instead, build it in local /tmp then move it to the dest dir
my $temp_dir = '/tmp/docsearch_' . time;
print "Building index in $temp_dir\n";
make_path($temp_dir);

my $files = find_files_to_index();
 
my $index = Lucy::Simple->new( path => $temp_dir, language => 'en' );

foreach my $url (sort keys %$files) {
  print "parsing $url\n";
  my $content = extract_content($files->{$url});
  $index->add_doc({
    url => $url,
    title => $content->{title} || '',
    body => $content->{body} || '',
  });
}

END {
  # do this in an end block to ensure Lucy::Simple has closed it's filehandles
  print "Moving index to $index_dir\n";
  if (-e $index_dir) {
    print "Dest dir already exists, deleting...\n";
  } else {
    make_path($index_dir); # ensure full path exists
  }
  remove_tree($index_dir);
  #move ($temp_dir, $index_dir); # doesn't seem to work
  print `mv $temp_dir $index_dir`; 
  print "Finished making index in $index_dir\n";
};

#------------------------------------------------------------------------------

sub find_files_to_index {
  # traverse plugins and get list of .ssi and .html files that we want to index
  my @plugin_dirs = map -e "$_/htdocs/info" ? "$_/htdocs/info" : (), reverse @{$SiteDefs::ENSEMBL_PLUGINS || []};
  unshift @plugin_dirs, "$SiteDefs::ENSEMBL_SERVERROOT/htdocs/info";
#  warn join "\n", @plugin_dirs;
  my $files;
  my $wanted = sub {
    my $dir  = $File::Find::topdir;
    my $file = $File::Find::name;
    (my $url = $file) =~ s/^$dir\///;
    if ($url ne 'index.html' and $url !~ /^search\// and $url =~ /(\.ssi|\.html)$/) {
      $files->{$url} = $file;
    }
  };
  find($wanted, @plugin_dirs); 
  return $files;
}

sub extract_content {
  my $filename = shift;

  open IN, "< $filename" || die("Can't open input file $filename :(\n");
  my @contents = <IN>;
  close IN;

  my $content = {
    title => get_title(\@contents),
    body => get_body(\@contents),
  };

  $content->{body} =~ s/\<[^\<]+\>//gm; # strip html
  $content->{body} =~ s/\[\[(.*?)\]\]//gm; # strip [[directives]]

  return $content;
}

sub get_title {
  ### Parses an HTML file and returns the contents of the <title> tag
  # taken from EnsEMBL::Web::Tools::WebTree
  my( $contents ) = @_;
  my $title;

  foreach(@$contents) {
    if( m!<title.*?>(.*?)(?:</title>|$)!i) {
      $title = $1;
    } elsif( defined($title) && m!^(.*?)(?:</title>|$)!i) {
      $title .= $1;
    }
    last if m!</title!i;
  }

  $title =~ s/\s{2,}//g;
  return $title;
}

sub get_body {
  ### Parses an HTML file and returns the contents of the <body> tag
  my( $contents ) = @_;
  my $body;

  foreach(@$contents) {
    if( m!<body.*?>(.*?)(?:</body>|$)!i) {
      $body = $1;
    } elsif( defined($body) && m!^(.*?)(?:</body>|$)!i) {
      $body .= $1;
    }
    last if m!</body!i;
  }

  $body =~ s/\s{2,}//g;
  return $body;
}


