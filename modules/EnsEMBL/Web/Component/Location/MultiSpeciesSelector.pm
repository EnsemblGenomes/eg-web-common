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

package EnsEMBL::Web::Component::Location::MultiSpeciesSelector;

use strict;

our @ISA = qw(EnsEMBL::Web::Component::MultiSelector); # Important! Redefine parent class.
use base qw(EnsEMBL::Web::Component::MultiSelector); # Important! Actually load(/use) parent module.

sub _init {
  my $self = shift;
  
  $self->SUPER::_init;

  $self->{'link_text'}       = 'Select species or regions';
  $self->{'included_header'} = 'Selected species';
  $self->{'excluded_header'} = 'Unselected species';
  $self->{'panel_type'}      = 'MultiSpeciesSelector';
  $self->{'url_param'}       = 's';
  $self->{'rel'}             = 'modal_select_species_or_regions';
}

sub content {
  return "";
}

sub content_ajax {
  my $self            = shift;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;
  my $params          = $hub->multi_params; 
  my $alignments      = $species_defs->multi_hash->{'DATABASE_COMPARA'}->{'ALIGNMENTS'} || {};
  my $primary_species = $hub->species;
  my $species_label   = $species_defs->species_label($primary_species, 1);
  my %shown           = map { $params->{"s$_"} => $_ } grep s/^s(\d+)$/$1/, keys %$params; # get species (and parameters) already shown on the page
  my $object          = $self->object;
  my $chr             = $object->seq_region_name;
## EG 
  #my $start           = $object->seq_region_start;
  #my $end             = $object->seq_region_end;

  my $slice           = $object->Obj->{slice};
  my @intra_species   = @{ $hub->intra_species_alignments('DATABASE_COMPARA', $primary_species, $slice) };
##
#warn "INTRA" . Data::Dumper::Dumper(\@intra_species);

  my $chromosomes     = $species_defs->ENSEMBL_CHROMOSOMES;
  my (%species, %included_regions);
  my $lookup = $species_defs->prodnames_to_urls_lookup;

## EG  
  foreach my $alignment (@intra_species) {
##
    my $type = lc $alignment->{'type'};
    my ($s)  = grep /--$alignment->{'target_name'}$/, keys %{$alignment->{'species'}};
    my ($sp, $target) = split '--', $s;
    my $url = $lookup->{$sp};
    s/_/ /g for $type, $target;

    $species{$url} = $species_defs->species_label($url, 1) . (grep($target eq $_, @$chromosomes) ? ' chromosome' : '') . " $target - $type";
  }

  foreach my $target (keys %included_regions) {
    my $s     = "$primary_species--$target";
    my $label = $species_label . (grep($target eq $_, @$chromosomes) ? ' chromosome' : '');
    
    foreach (grep $_->{'target_name'} eq $chr, @{$included_regions{$target}}) {
      (my $type = lc $_->{'type'}) =~ s/_/ /g;
      (my $t    = $target)         =~ s/_/ /g;
      $species{$s} = "$label $t - $type";
    }
  }
  
  my $prodname = $species_defs->SPECIES_PRODUCTION_NAME;
  foreach my $alignment (grep { $_->{'species'}{$prodname} && $_->{'class'} =~ /pairwise/ } values %$alignments) {
    foreach (keys %{$alignment->{'species'}}) {
      my $sp_url = $lookup->{$_};
      next if $sp_url eq 'Pristionchus_pacificus_prjna12644';
      if ($_ ne $prodname) {
        my $type = lc $alignment->{'type'};
           $type =~ s/_net//;
           $type =~ s/_/ /g;
        
        if ($species{$sp_url}) {
          $species{$sp_url} .= "/$type";
        } else {
          $species{$sp_url} = $species_defs->species_label($sp_url, 1) . " - $type";
        }
      }
    }
  }
  
  if ($shown{$primary_species}) {
    my ($chr) = split ':', $params->{"r$shown{$primary_species}"};
    $species{$primary_species} = "$species_label - chromosome $chr";
  }

  $self->{'all_options'}      = \%species;
  $self->{'included_options'} = \%shown;

## EG-2183 - HACK: prefix with sub_genome group name  
  foreach my $alignment (@intra_species) {
    if (my $sub_genome = $alignment->{target_sub_genome}) {
      my $old_key = "$primary_species--$alignment->{target_name}";
      my $new_key = "$species_label $sub_genome~~$old_key";
      $self->{'all_options'}->{$new_key}      = delete $self->{'all_options'}->{$old_key}      if exists $self->{'all_options'}->{$old_key};
      $self->{'included_options'}->{$new_key} = delete $self->{'included_options'}->{$old_key} if exists $self->{'included_options'}->{$old_key};
    }
  }
##

## ENSEMBL-4770 force to use 'Multi' as action in place of 'MultiSpeciesSelector'
  $self->{'url'} = $self->hub->url({ function => undef, action => 'Multi', align => $hub->param('align') }, 1);
##
  $self->SUPER::content_ajax;
}

1;
