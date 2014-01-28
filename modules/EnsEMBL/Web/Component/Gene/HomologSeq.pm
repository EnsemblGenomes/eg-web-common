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
  my $seq          = $hub->param('seq');
  my $format  = $hub->param('_format');
  my $raw_peptide  = $hub->param('raw_peptide');
  my $database     = $hub->database($cdb);
  my $qm           = $database->get_MemberAdaptor->fetch_by_source_stable_id('ENSEMBLGENE', $gene_id);
  my ($homologies, $html, %skipped);

  eval {
    $homologies = $database->get_HomologyAdaptor->fetch_all_by_Member($qm);
  };

  my $raw_peps = {};

  foreach my $homology (@{$homologies}) {
    my $sa;
    
    eval {
      $sa = $homology->get_SimpleAlign(-CDNA => ($seq eq 'cDNA' ? 1 : 0));
    };
    
    if ($sa) {
      my $flag = !$second_gene;
      
      foreach my $peptide (@{$homology->get_all_Members}) {
        
        my $gene = $peptide->gene_member;
        $flag = 1 if $gene->stable_id eq $second_gene;
        
        my $member_species = ucfirst $peptide->genome_db->name;
        
        my $species_name = $species_defs->get_config($member_species, 'SPECIES_SCIENTIFIC_NAME') || $species_defs->species_label($member_species);
        $species_name =~ s/\s/_/g;
        
        if (!$second_gene && $member_species ne $species && $hub->param('species_' . lc $member_species) eq 'off') {
          $flag = 0;
          $skipped{$species_defs->species_label($member_species)}++;
          next;
        }
        
        unless (exists $raw_peps->{$peptide->stable_id}) {
          $raw_peps->{$peptide->stable_id."_".$species_name} = $peptide;
        }        
                
      }
      
      next unless $flag;
      
    }
  }
  
  foreach my $pep_id (keys %{$raw_peps}) {
    my $translation = eval { $raw_peps->{$pep_id}->get_Translation->seq };
    warn "Caught exception: $@" if $@;
    next unless $translation;
    
    if($format =~ /^text$/i){
      $translation =~ s/(.{60})/$1\n/g;
      $html .= sprintf(">%s\n%s\n\n", $pep_id, $translation); 
    }
    else{
      $translation =~ s/(.{60})/$1<\/br>/g;
      $html .= sprintf('<pre><em>>%s</em></br>%s</pre>', $pep_id, $translation); 
    }
  }
  warn "CDB $cdb";  
  return $html;
}        

1;

