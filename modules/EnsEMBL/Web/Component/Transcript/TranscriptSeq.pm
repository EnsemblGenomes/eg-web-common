package EnsEMBL::Web::Component::Transcript::TranscriptSeq;

use strict;

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Transcript);

sub initialize {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object || $hub->core_object('transcript');

  my $adorn = $hub->param('adorn') || 'none';

  my $config = {
    display_width   => $hub->param('display_width') || 60,
    species         => $hub->species,
    maintain_colour => 1,
    transcript      => 1,
  };

  $config->{$_}            = $hub->param($_) eq 'yes' ? 1 : 0 for qw(exons codons coding_seq translation rna snp_display utr hide_long_snps);
  $config->{'codons'}      = $config->{'coding_seq'} = $config->{'translation'} = 0 unless $object->Obj->translation;
  $config->{'snp_display'} = 0 unless $hub->species_defs->databases->{'DATABASE_VARIATION'};

  if ($hub->param('line_numbering') ne 'off') {
    $config->{'line_numbering'} = 'yes';
    $config->{'number'}         = 1;
  }

  $self->set_variation_filter($config);

  my ($sequence, $markup) = $self->get_sequence_data($object, $config,$adorn);

  $self->markup_exons($sequence, $markup, $config)     if $config->{'exons'};
  $self->markup_codons($sequence, $markup, $config)    if $config->{'codons'};
  if($adorn ne 'none') {
    $self->markup_variation($sequence, $markup, $config) if $config->{'snp_display'};
  } else {
    push @{$config->{'loading'}||=[]},'variations' if $self->hub->database('variation');
  }
  $self->markup_line_numbers($sequence, $config)       if $config->{'line_numbering'};

  $config->{'v_space'} = "\n" if $config->{'coding_seq'} || $config->{'translation'} || $config->{'rna'};

  return ($sequence, $config);
}