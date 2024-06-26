=head1 LICENSE

Copyright [2009-2024] EMBL-European Bioinformatics Institute

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

# $Id: ComparaTree.pm,v 1.3 2011-08-30 16:01:38 it2 Exp $

package EnsEMBL::Web::ZMenu::Gene::ComparaTree;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $stable_id    = $object->stable_id;
  my $species      = $hub->species;
  my $species_path = $hub->species_path($species);
  my $phy_link     = $hub->get_ExtURL('PHYLOMEDB', $stable_id);
  my $dyo_link     = $hub->get_ExtURL('GENOMICUSSYNTENY', $stable_id);
  my $treefam_link = $hub->get_ExtURL('TREEFAMSEQ', $stable_id);
  my $ens_tran     = $object->Obj->canonical_transcript; # Link to protein sequence for cannonical or longest translation
  my $ens_prot;
  
  $self->SUPER::content;
  
  if ($ens_tran) {
    $ens_prot = $ens_tran->translation;
  } else {
    my ($longest) = sort { $b->[1]->length <=> $a->[1]->length } map {[$_, ($_->translation || next) ]} @{$object->Obj->get_all_Transcripts};
    ($ens_tran, $ens_prot) = @{$longest||[]};
  }
  
  $self->add_entry({
    type        => 'Species',
## EG
    label_html  => $hub->species_defs->species_display_label($species),
##
    link        => $species_path,
    position    => 1
  });

  if ($ens_prot) {
    $self->add_entry({
      type     => 'Protein',
      label    => 'Summary',
      position => 5,
      link     => $hub->url({
        type   => 'Transcript',
        action => 'ProteinSummary',
        t      => $ens_tran->stable_id 
      })
    });

    $self->add_entry({
      type     => ' ',
      label    => 'Sequence',
      position => 6,
      link     => $hub->url({
        type   => 'Transcript',
        action => 'Sequence_Protein',
        t      => $ens_tran->stable_id 
      })
    });
  }
  
  if ($phy_link) {
    $self->add_entry({
      type     => 'PhylomeDB',
      label    => 'Gene in PhylomeDB',
      link     => $phy_link,
      external => 1,
      position => 16
    });
  }
  
  if ($dyo_link) {
    $self->add_entry({
      type     => 'Genomicus Synteny',
      label    => 'Gene in Genomicus',
      link     => $dyo_link,
      external => 1, 
      position => 17
    });
  }
  
  if ($treefam_link) {
    $self->add_entry({
      type     => 'TreeFam',
      label    => 'Gene in TreeFam',
      link     => $treefam_link,
      external => 1,
      position => 18
    });
  }
  
}

1;
