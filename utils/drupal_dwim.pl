#! /usr/bin/env perl

# Update the drupals in this checkout per SOP.

use strict;
use warnings;

use FindBin qw($Bin);
use Storable;

my $conf = retrieve("$Bin/../../../config.sconf");

my $division = $conf->{'SiteDefs'}{'DIVISION'};
my $release = $conf->{'SiteDefs'}{'SITE_RELEASE_VERSION'};

warn "updating drupal for $division/$release\n";

system("$Bin/drupal_import_home.pl -d $division -r $release") && die;
unless($division eq 'bacteria') {
  system("$Bin/drupal_import_species.pl -d $division") && die;
}

1;

