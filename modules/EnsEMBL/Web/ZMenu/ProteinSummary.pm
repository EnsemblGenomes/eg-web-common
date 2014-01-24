package EnsEMBL::Web::ZMenu::ProteinSummary;

use strict;

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $db          = $hub->param('db') || 'core';
  my $pfa         = $hub->database(lc $db)->get_ProteinFeatureAdaptor;
  my $pf          = $pfa->fetch_by_dbID($hub->param('pf_id'));
  my $hit_db      = $pf->analysis->db;
  my $hit_name    = $pf->display_id;
  my $interpro_ac = $pf->interpro_ac;
  
  $self->caption("$hit_name ($hit_db)");

  my $record_link = $hub->get_ExtURL($hit_db, $hit_name);
  if ($hit_db eq 'Gene3D' && $hit_name=~/:/){
    my ($prefix, $ext_id) = split(/:/, $hit_name);
    $record_link = $hub->get_ExtURL($hit_db, $ext_id) if $ext_id;
  } 
  
  $self->add_entry({
    type  => 'View record',
    label => $hit_name,
    link  => $record_link,
  });
  
  if ($interpro_ac) {
    $self->add_entry({
      type  => 'View InterPro',
      label => $interpro_ac,
      link  => $hub->get_ExtURL('interpro', $interpro_ac)
    });
  }
  
  $self->add_entry({
    type  => 'Description',
    label => $pf->idesc
  });
  
  $self->add_entry({
    type  => 'Position',
    label => $pf->start . '-' . $pf->end . ' aa'
  });
}

1;
