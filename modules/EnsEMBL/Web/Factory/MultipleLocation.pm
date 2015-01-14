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

package EnsEMBL::Web::Factory::MultipleLocation;

use strict;

use POSIX qw(floor);

use Bio::EnsEMBL::Registry;

use base qw(EnsEMBL::Web::Factory::Location);

sub createObjects {
  my $self = shift;
  
  $self->SUPER::createObjects;
  
  my $object = $self->object;
  
  return unless $object;
  
  # Redirect if we need to generate a new url
  return if $self->generate_url($object->slice);
  
  my $hub = $self->hub;

## EG - default comparisons
  my $species_defs = $hub->species_defs;

  if ($hub->action =~ /Polyploid/) {
    my $primary_slice   = $object->slice;
    my $primary_species = $hub->species; 
    my $alignments      = $hub->intra_species_alignments('DATABASE_COMPARA', $primary_species, $primary_slice);
    my %align_species;

    foreach my $align (sort { $a->{target_name} cmp $b->{target_name} } @$alignments) {
      next unless $align->{'class'} =~ /pairwise_alignment/;
      next unless $align->{'species'}{"$primary_species--" . $primary_slice->seq_region_name};
      my $sp = sprintf('%s--%s', $primary_species, $align->{target_name});
      $align_species{$sp} = 1;
    }

    my $already_configured = !!$hub->param("s1");

    # check if current configured species are valid for polyploid view
    if ($already_configured) {
      my $i = 1;
      while (my $s = $hub->param("s$i")) {
        $already_configured = 0 if !$align_species{$s};
        $i ++;
      }
      ## disabled - this is a bad assumption as there could be alignments in this list that 
      ##            don't have features for the current location
      #$already_configured = 0 if scalar keys %align_species != $i-1; 
      ##
      if (!$already_configured) {
        # clear old params
        my $i = 1;
        while ($hub->param("s$i")) {
          $hub->delete_param("s$i", "r$i");
          $i ++;
        }
      }
    }  

    if (!$already_configured) {
      # set up default intra-species comparisons for polyploid view
      my $i = 1;
      for (keys %align_species) {
        $hub->param("s$i", $_);
        $i ++;
      }
    }
  } elsif (!$hub->param("r1")) { 
    # if we have got default species, and this is not a self referral (i.e. from species selector)
    if ($species_defs->DEFAULT_COMPARISON_SPECIES and $hub->referer->{ENSEMBL_ACTION} ne 'Multi') {
      my @species = @{ $species_defs->DEFAULT_COMPARISON_SPECIES };
      for my $i (1..@species) {
        $hub->param("s$i", $species[$i-1]);
      }
    }
  }
##  

  my $action_id = $self->param('id');
  my $gene      = 0;
  my $invalid   = 0;
  my @slices;
  my $chr_flag;
  
  my %inputs = (
    0 => { 
      s => $self->species,
      r => $self->param('r'),
      g => $self->param('g')
    }
  );
  
  foreach ($self->param) {
    $inputs{$2}->{$1} = $self->param($_) if /^([gr])(\d+)$/;
    ($inputs{$1}->{'s'}, $inputs{$1}->{'chr'}) = split '--', $self->param($_) if /^s(\d+)$/;
    $chr_flag = 1 if $inputs{$1} && $inputs{$1}->{'chr'};
  }
  
  # Strip bad parameters (r/g without s)
  foreach my $id (grep !$inputs{$_}->{'s'}, keys %inputs) {
    $self->delete_param("$_$id") for keys %{$inputs{$id}};
    $invalid = 1;
  }
  
  $inputs{$action_id}->{'action'} = $self->param('action') if $inputs{$action_id};
  
  # If we had bad parameters, redirect to remove them from the url.
  # If we came in on an a gene, redirect so that we use the location in the url instead.
  return $self->problem('redirect', $hub->url($hub->multi_params)) if $invalid || $self->input_genes(\%inputs) || $self->change_all_locations(\%inputs);
  
  foreach (sort { $a <=> $b } keys %inputs) {
    my $species = $inputs{$_}->{'s'};
    my $r       = $inputs{$_}->{'r'};
    
    next unless $species && $r;
    
    $self->__set_species($species);
    
    my ($seq_region_name, $s, $e, $strand) = $r =~ /^([^:]+):(-?\w+\.?\w*)-(-?\w+\.?\w*)(?::(-?\d+))?/;
    $s = 1 if $s < 1;
    
    $inputs{$_}->{'chr'} ||= $seq_region_name if $chr_flag;
    
    my $action = $inputs{$_}->{'action'};
    my $chr    = $inputs{$_}->{'chr'} || $seq_region_name;
    my $slice;
    
    my $modifiers = {
      in      => sub { ($s, $e) = ((3*$s + $e)/4,   (3*$e + $s)/4  ) }, # Half the length
      out     => sub { ($s, $e) = ((3*$s - $e)/2,   (3*$e - $s)/2  ) }, # Double the length
      left    => sub { ($s, $e) = ($s - ($e-$s)/10, $e - ($e-$s)/10) }, # Shift left by length/10
      left2   => sub { ($s, $e) = ($s - ($e-$s)/2,  $e - ($e-$s)/2 ) }, # Shift left by length/2
      right   => sub { ($s, $e) = ($s + ($e-$s)/10, $e + ($e-$s)/10) }, # Shift right by length/10
      right2  => sub { ($s, $e) = ($s + ($e-$s)/2,  $e + ($e-$s)/2 ) }, # Shift right by length/2
      flip    => sub { ($strand ||= 1) *= -1 },
      realign => sub { $self->realign(\%inputs, $_) },
      primary => sub { $self->change_primary_species(\%inputs, $_) }
    };
    
    # We are modifying the url - redirect.
    if ($action && exists $modifiers->{$action}) {
      $modifiers->{$action}();
      
      $self->check_slice_exists($_, $chr, $s, $e, $strand);
      
      return $self->problem('redirect', $hub->url($hub->multi_params));
    }
    
    eval { $slice = $self->slice_adaptor->fetch_by_region(undef, $chr, $s, $e, $strand); };
    next if $@;
    
    push @slices, {
      slice         => $slice,
      species       => $species,
      target        => $inputs{$_}->{'chr'},
      species_check => $species eq $hub->species ? join('--', grep $_, $species, $inputs{$_}->{'chr'}) : $species,
      name          => $slice->seq_region_name,
      short_name    => $object->chr_short_name($slice, $species),
      start         => $slice->start,
      end           => $slice->end,
      strand        => $slice->strand,
      length        => $slice->seq_region_length
    };
  }
  
  $object->__data->{'_multi_locations'} = \@slices;
}

1;
