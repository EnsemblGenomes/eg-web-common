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

package EnsEMBL::Web::Tools::DHTMLmerge;

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);
use EnsEMBL::Web::Exceptions;

# Set to something truthy for more verbose logging of minification
my $DEBUG = 0;

sub get_filegroups {
  ## Gets a datastructure of lists of grouped files for the given type that are served to the frontend
  ## Override this method in plugins to add any extra files that are not present in the default 'components' folder (they can grouped using the group key to serve them on-demand)
  ## @param SpeciesDefs object
  ## @param css or js
  ## @return List of hashrefs as accepted by constructor of EnsEMBL::Web::Tools::DHTMLmerge::FileGroup
  my ($species_defs, $type) = @_;

  my $dir = 'components';
  $dir = '.' if $type eq 'image';
  return {
    'group_name'  => 'components',
    'files'       => get_files_from_dir($species_defs, $type, $dir),
    'condition'   => sub { 1 },
    'ordered'     => 0
  },{
    group_name => 'newtable',
    files => get_files_from_dir($species_defs,$type,'newtable'),
    condition => sub { 1 },
    ordered => 0
  };
}

sub merge_all {
  ## This merges all CSS and JS files and saves the combined and minified ones on the disk
  ## Call this at startup
  ## @param EnsEMBL::Web::SpeciesDefs object
  my $species_defs  = shift;
  my $configs       = {};

  try {
    foreach my $type (qw(js css ie7css image)) {
      push @{$configs->{$type}}, map { EnsEMBL::Web::Tools::DHTMLmerge::FileGroup->new($species_defs, $type, $_) } get_filegroups($species_defs, $type);
    }
    for (@{$configs->{'image'}}) {
      delete $_->{'files'};
    }
    $species_defs->set_config('ENSEMBL_JSCSS_FILES', $configs);
    $species_defs->store;
  } catch {
    warn $_;
    throw $_;
  };
}

sub get_files_from_dir {
  ## Recursively gets all the files from all the directories (from inside all the HTDOCS dirs) with the given name
  ## @param SpeciesDefs object
  ## @param Type of files (css or js)
  ## @param Dir name to be checked in all HTDOCS dir
  ## @return Arrayref of absolute file names
  my ($species_defs, $type, $dir) = @_;

  my @files;

  my @types = ($type);
  @types = qw(gif png jpg jpeg) if $type eq 'image';
  @types = qw(css) if $type eq 'ie7css';
## Skip image dir for bacteria
  foreach my $htdocs_dir (grep { !m/biomart/ && -d "$_/$dir" && !(m/bacteria/ && $type eq 'image')} reverse @{$species_defs->ENSEMBL_HTDOCS_DIRS || []}) {
##
    foreach my $file (@{list_dir_contents("$htdocs_dir/$dir",{recursive=>1})}) {
      my $path = "$htdocs_dir/$dir/$file";
      next if $path =~ m!/minified/!;
      push @files,$path if grep { $file =~ /\.$_$/ } @types;
    }
  }

  warn "  Found ".(scalar @files)." files type=$type in $dir\n" if $DEBUG;

  return \@files;
}


1;
