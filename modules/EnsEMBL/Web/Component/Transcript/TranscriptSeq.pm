package EnsEMBL::Web::Component::Transcript::TranscriptSeq;

use strict;

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Transcript);

sub initialize {
  my $self   = shift;
  my $hub    = $self->hub;
  my $object = $self->object || $hub->core_object('transcript');

  my $type   = $hub->param('data_type') || $hub->type;
  my $vc = $self->view_config($type);
 
  my $adorn = $hub->param('adorn') || 'none';
 
  my $config = { 
    species         => $hub->species,
    maintain_colour => 1,
    transcript      => 1,
  };
 
  $config->{'display_width'} = $hub->param('display_width') || $vc->get('display_width'); 
  $config->{$_} = ($hub->param($_) eq 'on' || $vc->get($_) eq 'on') ? 1 : 0 for qw(exons exons_case codons coding_seq translation rna snp_display utr hide_long_snps);
  $config->{'codons'}      = $config->{'coding_seq'} = $config->{'translation'} = 0 unless $object->Obj->translation;
 
  if ($hub->param('line_numbering') ne 'off') {
    $config->{'line_numbering'} = 'on';
    $config->{'number'}         = 1;
  }
  
  $self->set_variation_filter($config);
  
  my ($sequence, $markup) = $self->get_sequence_data($object, $config,$adorn);
  
  $self->markup_exons($sequence, $markup, $config)     if $config->{'exons'};
  $self->markup_codons($sequence, $markup, $config)    if $config->{'codons'};
  if($adorn ne 'none') {
    $self->markup_variation($sequence, $markup, $config) if $config->{'snp_display'};  
## EG - Only show variation in key if a variation database is attached 
    push @{$config->{'loaded'}||=[]},'variations' if $self->hub->database('variation');
  } else {
    push @{$config->{'loading'}||=[]},'variations' if $self->hub->database('variation');
  }
##  
  $self->markup_line_numbers($sequence, $config)       if $config->{'line_numbering'};
  
  $config->{'v_space'} = "\n" if $config->{'coding_seq'} || $config->{'translation'} || $config->{'rna'};
  
  return ($sequence, $config);
}

sub blast_options {
 ## @override
 return { 'no_button' => 0 };
}
