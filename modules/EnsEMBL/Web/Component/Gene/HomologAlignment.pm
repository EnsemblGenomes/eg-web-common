=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::HomologAlignment;

use strict;

use Bio::AlignIO;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $cdb          = shift || $hub->param('cdb') || 'compara';

  my $species      = $hub->species;
  my $species_defs = $hub->species_defs;
  my $gene_id      = $self->object->stable_id;
  my $second_gene  = $hub->param('g1');
  my $seq          = $hub->param('seq');
  my $text_format  = $hub->param('text_format');
  my (%skipped, $html);

  my $is_ncrna       = ($self->object->Obj->biotype =~ /RNA/);
  my $gene_product   = $is_ncrna ? 'Transcript' : 'Peptide';
  my $unit           = $is_ncrna ? 'nt' : 'aa';
  my $identity_title = '% identity'.(!$is_ncrna ? " ($seq)" : '');

## EG - remove for E86, when this PR is merged https://github.com/Ensembl/ensembl-webcode/pull/474
  my $homologies = $self->get_homologies($cdb);
##
 
  # Remove the homologies with hidden species
  foreach my $homology (@{$homologies}) {

    my $compara_seq_type = $seq eq 'cDNA' ? 'cds' : undef;
    $homology->update_alignment_stats($compara_seq_type);
    my $sa;
    
    eval {
      $sa = $homology->get_SimpleAlign(-SEQ_TYPE => $compara_seq_type);
    };
    warn $@ if $@;
    
    if ($sa) {
      my $data = [];
      my $flag = !$second_gene;
      
      foreach my $peptide (@{$homology->get_all_Members}) {
        my $gene = $peptide->gene_member;
        $flag = 1 if $gene->stable_id eq $second_gene; 

        my $member_species = ucfirst $peptide->genome_db->name;
        my $location       = sprintf '%s:%d-%d', $gene->dnafrag->name, $gene->dnafrag_start, $gene->dnafrag_end;
       
        if (!$second_gene && $member_species ne $species && $hub->param('species_' . lc $member_species) eq 'off') {
          $flag = 0;
          $skipped{$species_defs->species_label($member_species)}++;
          next;
        }

        if ($gene->stable_id eq $gene_id) {
          push @$data, [
            $species_defs->species_label($member_species),
            $gene->stable_id,
            $peptide->stable_id,
            sprintf('%d %s', $peptide->seq_length, $unit),
            sprintf('%d %%', $peptide->perc_id),
            sprintf('%d %%', $peptide->perc_cov),
            $location,
          ]; 
        } else {
          push @$data, [
            $species_defs->species_label($member_species),
            sprintf('<a href="%s">%s</a>',
              $hub->url({ species => $member_species, type => 'Gene', action => 'Summary', g => $gene->stable_id, r => undef }),
              $gene->stable_id
            ),
            sprintf('<a href="%s">%s</a>',
              $hub->url({ species => $member_species, type => 'Transcript', action => 'ProteinSummary', peptide => $peptide->stable_id, __clear => 1 }),
              $peptide->stable_id
            ),
            sprintf('%d %s', $peptide->seq_length, $unit),
            sprintf('%d %%', $peptide->perc_id),
            sprintf('%d %%', $peptide->perc_cov),
            sprintf('<a href="%s">%s</a>',
              $hub->url({ species => $member_species, type => 'Location', action => 'View', g => $gene->stable_id, r => $location, t => undef }),
              $location
            )
          ];
        }
      }
     
      next unless $flag;
 
      my $homology_desc_mapped = $Bio::EnsEMBL::Compara::Homology::PLAIN_TEXT_DESCRIPTIONS{$homology->{'_description'}} || $homology->{'_description'} || 'no description';

      $html .= "<h2>Type: $homology_desc_mapped</h2>";
      
      my $ss = $self->new_table([
          { title => 'Species',          width => '20%' },
          { title => 'Gene ID',          width => '15%' },
          { title => "$gene_product ID",       width => '15%' },
          { title => "$gene_product length",   width => '10%' },
          { title => $identity_title,    width => '10%' },
          { title => '% coverage',       width => '10%' },
          { title => 'Genomic location', width => '20%' }
        ],
        $data
      );
      
      $html .= $ss->render;

      my $alignio = Bio::AlignIO->newFh(
        -fh     => IO::String->new(my $var),
        -format => $self->renderer_type($text_format)
      );
      
      print $alignio $sa;
      
      $html .= "<pre>$var</pre>";
    }
  }
  
  if (scalar keys %skipped) {
    my $count;
    $count += $_ for values %skipped;
    
    $html .= '<br />' . $self->_info(
      'Orthologues hidden by configuration',
      sprintf(
        '<p>%d orthologues not shown in the table above from the following species. Use the "<strong>Configure this page</strong>" on the left to show them.<ul><li>%s</li></ul></p>',
        $count,
        join "</li>\n<li>", map "$_ ($skipped{$_})", sort keys %skipped
      )
    );
  }
  
  return $html;
}        

1;

