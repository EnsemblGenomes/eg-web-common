#!/usr/bin/env perl
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
use Pod::Usage;
use Getopt::Long;

BEGIN {                                                                                                                                                                         
  unshift @INC, "$Bin/../../../conf";                                                                                                                                            
  unshift @INC, "$Bin/../../..";                                                                                                                                                 
  eval{ require SiteDefs };                                                                                                                                                    
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }                                                                                                                               
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;                                                                                                                         
}

use JSON;
use utils::Tool;
use Bio::EnsEMBL::Utils::Scalar qw(check_ref);

my $options = {};
my @switches = qw(target=s help man);
GetOptions($options, @switches) or pod2usage(1);
pod2usage( -exitstatus => 0, -verbose => 1 ) if $options->{help};
pod2usage( -exitstatus => 0, -verbose => 2 ) if $options->{man};

my $target_file = $options->{target};
if(! defined $target_file) {
  print STDERR 'No -target specified at command line', "\n";
  pod2usage( -exitstatus => 1, -verbose => 1 );
}
if(-f $target_file) {
  print STDERR "The file '${target_file}' already exists; remove and rerun\n";
  pod2usage( -exitstatus => 2, -verbose => 1 );
}

my @species = @{ utils::Tool::all_species()};
my $species_defs = utils::Tool::species_defs();

my $url_hash = {};
foreach my $s (@species) {
  my $genome_browsers = $species_defs->get_config($s,'EXTERNAL_GENOME_BROWSERS');
  my $urls = $species_defs->get_config($s,'ENSEMBL_EXTERNAL_URLS');

  next unless check_ref($genome_browsers, 'HASH');
  foreach my $key (%{$genome_browsers}) {
    my $name = $genome_browsers->{$key};
    my $url = $urls->{$key};
    next unless defined $url && $url;
    $url_hash->{$s}->{$name} = $url;
        
  }
}

my $json = JSON->new->pretty(1)->encode($url_hash);

my $template = <<'TEMPLATE';
Ensembl.LayoutManager = Ensembl.LayoutManager.extend({
  externalDbUrls: function () {
    var superUrls = this.base();
    var myUrls = %s;
    var merged = $.extend(superUrls, myUrls);
    return merged;
  }
});
TEMPLATE

open(my $fh, '>', $target_file) or die("Cannot open $target_file for writing: $!");
print $fh sprintf($template, $json);
close($fh) or die ("Cannot close $target_file : $!");

__END__
=pod

=head1 NAME

generate_externaldbs_callbacks.pl

=head1 SYNOPSIS

  ./generate_externaldbs_callbacks.pl --target exteranldbs.js [--help | --man]

=head1 DESCRIPTION

A script used to generate the callbacks required for automatically updating
the URLs seen in the left had bar of EnsEMBL websites for working with
External Genome browsers. This allows the placement of these URLs in
the SiteDefs configuration file and allows you to regenerate the callbacks
as & when these are updated.

=head1 OPTIONS

=over 8

=item B<--target>

The target location of the file to generate the URLs to

=back

=head1 REQUIREMENTS

=over 8

=item Ensembl WebCode

=item JSON

=back

=head1 AUTHOR

ayates

=head1 MAINTAINER

$Author: ady $

=head VERSION

$Revision: 1.1 $

=cut
