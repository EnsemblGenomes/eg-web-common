# $Id: TextSequence.pm,v 1.8 2013-09-05 13:07:16 nl2 Exp $

package EnsEMBL::Web::Component::TextSequence;

use strict;
  

sub tool_buttons {
  my ($self, $blast_seq, $peptide) = @_;
  
  return unless $self->html_format;
  
  my $hub  = $self->hub;
  my $html = sprintf('
    <div class="other_tool">
      <p><a class="seq_export export" href="%s">Download view as RTF</a></p>
    </div>', 
    $self->ajax_url('rtf', { filename => join('_', $hub->type, $hub->action, $hub->species, $self->object->Obj->stable_id), _format => 'RTF' })
  );
  
  if ($blast_seq && $hub->species_defs->ENSEMBL_BLAST_ENABLED) {
    $html .= sprintf('
      <div class="other_tool">
        <p><a class="seq_blast find" href="#">BLAST this sequence</a></p>
        <form class="external hidden seq_blast" action="/Multi/blastview" method="post">
          <fieldset>
            <input type="hidden" name="_query_sequence" value="%s" />
            <input type="hidden" name="species" value="%s" />
            %s
          </fieldset>
        </form>
      </div>',
      $blast_seq, $hub->species, $peptide ? '<input type="hidden" name="query" value="peptide" /><input type="hidden" name="database" value="peptide" />' : ''
    );
  }

  if ($self->hub->species_defs->ENSEMBL_ENASEARCH_ENABLED && $blast_seq) {
    $html .= sprintf('
      <div class="other_tool">
        <p><a class="seq_ena find" href="#">Search Ensembl Genomes with this sequence</a></p>
        <form id="enaform" class="external hidden seq_ena
" action="/Multi/enasearch" method="post">
          <fieldset>
            <input type="hidden" name="_query_sequence" value="%s" />
            <input type="hidden" name="evalue" value="1" />
          </fieldset>
        </form>
      </div>',
      $blast_seq
    );
  }

  
  return $html;
}

1;
