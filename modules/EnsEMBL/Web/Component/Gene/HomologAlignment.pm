# $Id: HomologAlignment.pm,v 1.9 2013-07-01 15:27:05 jk10 Exp $

package EnsEMBL::Web::Component::Gene::HomologAlignment;

use strict;

use Bio::AlignIO;
use List::MoreUtils qw{ none any };

use EnsEMBL::Web::Constants;

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
  my $database     = $hub->database($cdb);
  my $qm           = $database->get_MemberAdaptor->fetch_by_source_stable_id('ENSEMBLGENE', $gene_id);
  my ($homologies, $html, %skipped);

  eval {
    $homologies = $database->get_HomologyAdaptor->fetch_all_by_Member($qm);
  };

  my %desc_mapping = (
    ortholog_one2one          => '1 to 1 orthologue',
    apparent_ortholog_one2one => '1 to 1 orthologue (apparent)',
    ortholog_one2many         => '1 to many orthologue',
    between_species_paralog   => 'paralogue (between species)',
    ortholog_many2many        => 'many to many orthologue',
    within_species_paralog    => 'paralogue (within species)',
    other_paralog             => 'other paralogue (within species)',
  );
 
  my @orthologues = qw/ortholog_one2one apparent_ortholog_one2one ortholog_one2many ortholog_many2many possible_ortholog/;
  my @paralogues = ('other_paralog', 'between_species_paralog', 'within_species_paralog');
  my @list_to_show = ();

  if ( ($hub->referer->{'ENSEMBL_ACTION'} eq 'Compara_Paralog' && $hub->referer->{'ENSEMBL_FUNCTION'} eq 'Alignment_pan_compara')
    || ($hub->referer->{'ENSEMBL_ACTION'} eq 'Compara_Paralog' && $hub->referer->{'ENSEMBL_FUNCTION'} eq 'Alignment') ) { 
      @list_to_show = (@paralogues);
  }
  if ( ($hub->referer->{'ENSEMBL_ACTION'} eq 'Compara_Ortholog' && $hub->referer->{'ENSEMBL_FUNCTION'} eq 'Alignment_pan_compara')
    || ( $hub->referer->{'ENSEMBL_ACTION'} eq 'Compara_Ortholog' && $hub->referer->{'ENSEMBL_FUNCTION'} eq 'Alignment')){
      @list_to_show = (@orthologues);
  }

  foreach my $homology (@{$homologies}) {
    my $sa;
    
    eval {
      $sa = $homology->get_SimpleAlign(-CDNA => ($seq eq 'cDNA' ? 1 : 0));
    };
    
    if ($sa) {
      my $data = [];
      my $flag = !$second_gene;
      
      foreach my $peptide (@{$homology->get_all_Members}) {
        
        my $gene = $peptide->gene_member;
        $flag = 1 if $gene->stable_id eq $second_gene;
        
        my $member_species = ucfirst $peptide->genome_db->name;
        my $location       = sprintf '%s:%d-%d', $gene->chr_name, $gene->chr_start, $gene->chr_end;
        
        if (!$second_gene && $member_species ne $species && $hub->param('species_' . lc $member_species) eq 'off') {
          $flag = 0;
          $skipped{$species_defs->species_label($member_species)}++;
          next;
        }
        
        if ($gene->stable_id eq $gene_id) {
          push @$data, [
            $species_defs->get_config($member_species, 'SPECIES_SCIENTIFIC_NAME'),
            $gene->stable_id,
            $peptide->stable_id,
            sprintf('%d aa', $peptide->seq_length),
            sprintf('%d %%', $peptide->perc_id),
            $location,
          ]; 
        } else {
          push @$data, [
            $species_defs->get_config($member_species, 'SPECIES_SCIENTIFIC_NAME') || $species_defs->species_label($member_species),
            sprintf('<a href="%s">%s</a>',
              $hub->url({ species => $member_species, type => 'Gene', action => 'Summary', g => $gene->stable_id, r => undef }),
              $gene->stable_id
            ),
            sprintf('<a href="%s">%s</a>',
              $hub->url({ species => $member_species, type => 'Transcript', action => 'ProteinSummary', peptide => $peptide->stable_id, __clear => 1 }),
              $peptide->stable_id
            ),
            sprintf('%d aa', $peptide->seq_length),
            sprintf('%d %%', $peptide->perc_id),
            sprintf('<a href="%s">%s</a>',
              $hub->url({ species => $member_species, type => 'Location', action => 'View', g => $gene->stable_id, r => $location, t => undef }),
              $location
            )
          ];
        }
      }
      
      next unless $flag;
      
      my $homology_types = EnsEMBL::Web::Constants::HOMOLOGY_TYPES;
      my $homology_desc  = $homology_types->{$homology->{'_description'}} || $homology->{'_description'};

      next if 
        none { $homology_desc eq $_ } @list_to_show;
      
      my $homology_desc_mapped = $desc_mapping{$homology_desc} ? $desc_mapping{$homology_desc} : 
                                 $homology_desc ? $homology_desc : 'no description';

      $html .= "<h2>Homologue type: $homology_desc_mapped</h2>";
      
      my $ss = $self->new_table([
          { title => 'Species',          width => '18%' },
          { title => 'Gene ID',          width => '18%' },
          { title => 'Peptide ID',       width => '18%' },
          { title => 'Peptide length',   width => '13%' },
          { title => '% identity',       width => '13%' },
          { title => 'Genomic location', width => '20%' }
        ],
        $data
      );
## EG: add alignment details table      
      my $match_line = $sa->match_line;
      my $identical = $match_line =~ tr/*/*/;
      my $similar   = $match_line =~ tr/:/:/;
      $similar += $identical;
      my $gaps = 0;
      map { $gaps += $_->seq =~ tr/-/-/ } $sa->each_seq;
      my $alntable = $self->new_table([
        { title => 'Alignment details',       width => '15%' },
        { title => '',       width => '05%', align=>'right'},
        { title => '',       width => '05%', align=>'right'},
        { title => '',       width => '10%', align=>'right'},
        { title => '',       width => '05%', align=>'right'},
        { title => '',       width => '60%', align=>'right'},

        ],
        [
          ['Alignment length', $sa->length,'','gaps', $gaps,''],
          ['identical residues', $identical,'','similar residues', $similar,''],
        ]);
      $html .= $ss->render . $alntable->render;
## /EG
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

