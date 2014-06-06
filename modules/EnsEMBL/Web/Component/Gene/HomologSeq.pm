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

# $Id: HomologSeq.pm,v 1.4 2013-10-03 14:55:18 nl2 Exp $

package EnsEMBL::Web::Component::Gene::HomologSeq;

use strict;

use Bio::AlignIO;
use List::MoreUtils qw{ none any };
use EnsEMBL::Web::Constants;
use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $cdb          = shift || $hub->param('cdb') || 'compara';
  my $species      = $hub->species;
  my $species_defs = $hub->species_defs;
  my $gene_id      = $self->object->stable_id;
  my $second_gene  = $hub->param('g1');
  my $cds          = $hub->param('seq') eq 'cds';
  my $format       = $hub->param('_format');
  my $database     = $hub->database($cdb);
  my $qm           = $database->get_GeneMemberAdaptor->fetch_by_source_stable_id('ENSEMBLGENE', $gene_id);
  my ($homologies, $html, %skipped);

  eval {
    $homologies = $database->get_HomologyAdaptor->fetch_all_by_Member($qm);
  };

  my ($match_type, $desc_mapping) = $self->homolog_type;
   
  my $homology_types = EnsEMBL::Web::Constants::HOMOLOGY_TYPES;

  my $members = {};

  foreach my $homology (@{$homologies}) {
    
    my $sa;

    ## filter out non-required types
    my $homology_desc  = $homology_types->{$homology->{'_description'}} || $homology->{'_description'};
    next unless $desc_mapping->{$homology_desc};    

    eval {
      $sa = $homology->get_SimpleAlign($cds ? (-SEQ_TYPE => 'cds') : ());
    };
    
    if ($sa) {
      my $flag = !$second_gene;
      
      foreach my $m (@{$homology->get_all_Members}) {
        
        my $gene = $m->gene_member;
        $flag = 1 if $gene->stable_id eq $second_gene;
        
        my $member_species = ucfirst $m->genome_db->name;
        
        my $species_name = $species_defs->get_config($member_species, 'SPECIES_SCIENTIFIC_NAME') || $species_defs->species_label($member_species);
        $species_name =~ s/\s/_/g;
        
        if (!$second_gene && $member_species ne $species && $hub->param('species_' . lc $member_species) eq 'off') {
          $flag = 0;
          $skipped{$species_defs->species_label($member_species)}++;
          next;
        }
        
        unless (exists $members->{$m->stable_id}) {
          $members->{$m->stable_id."_".$species_name} = $m;
        }        
                
      }
      
      next unless $flag;
      
    }
  }
  
  foreach my $member_id (keys %{$members}) {
    my $member = $members->{$member_id};
    my $sequence = eval{ $cds ? $member->sequence_cds : $member->get_Translation->seq };
    warn "Caught exception: $@" if $@;
    next unless $sequence;
    
    if($format =~ /^text$/i){
      $sequence =~ s/(.{60})/$1\n/g;
      $html .= sprintf(">%s\n%s\n\n", $member_id, $sequence); 
    }
    else{
      $sequence =~ s/(.{60})/$1<\/br>/g;
      $html .= sprintf('<pre><em>>%s</em></br>%s</pre>', $member_id, $sequence); 
    }
  }

  return $html;
}        

1;
