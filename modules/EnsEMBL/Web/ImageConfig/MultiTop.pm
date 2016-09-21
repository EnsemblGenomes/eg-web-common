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

package EnsEMBL::Web::ImageConfig::MultiTop;

use strict;
use previous qw(init_cacheable);

sub init_cacheable {
  my $self = shift;
  $self->PREV::init_cacheable(@_);
  
  # set spritelib for the EG division - TODO: make this configurable
  my $site = $SiteDefs::ENSEMBL_SITETYPE =~ s/Ensembl //r; #/
  my $sp_img_48 = $self->species_defs->ENSEMBL_SERVERROOT . '/eg-web-' . lc($site) . '/htdocs/i/species/48'; # 
  if(-e $sp_img_48) {
    $self->set_parameters({ spritelib => {
      %{$self->get_parameter('spritelib')||{}},
      species => $sp_img_48,
    }});
  }
}

sub join_genes {
  my ($self, $chr, @slices) = @_;
  my ($ps, $pt, $ns, $nt) = map { $_->{'species'}, $_->{'target'} } @slices;
  my $sp         = $self->{'species'};
  my $sd         = $self->species_defs;
## EG
  my $hub = $self->hub;
  
  for (map { @{$hub->intra_species_alignments($_, $ps, $pt)}, @{$hub->intra_species_alignments($_, $ns, $nt)} } @{$sd->compara_like_databases}) {
    $self->set_parameter('homologue', $_->{'homologue'}) if $_->{'species'}{"$sp--$chr"};
  }
##
  
  foreach ($self->get_node('transcript')->nodes) {
    $_->set('previous_species', $ps) if $ps;
    $_->set('next_species',     $ns) if $ns;
    $_->set('previous_target',  $pt) if $pt;
    $_->set('next_target',      $nt) if $nt;
    $_->set('join', 1);
  }
}

1;
