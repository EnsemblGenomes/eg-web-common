=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ZMenu::ProteinSummary;

use strict;
use JSON qw(from_json);

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $db          = $hub->param('db') || 'core';
  my $pfa         = $hub->database(lc $db)->get_ProteinFeatureAdaptor;
  my $pf          = $pfa->fetch_by_dbID($hub->param('pf_id'));
  my @prot_feats  = @{ $pfa->fetch_all_by_translation_id($hub->param('translation_id')) } if($hub->param('translation_id'));

  my $hit_db      = $pf->analysis->db;
  my $hit_name    = $pf->display_id;
  my $interpro_ac = $pf->interpro_ac;
  my $start       = $pf->start;
  my $end         = $pf->end;
  # get the very begining/start of the protein track (see ENSWEB-2286)
  if(@prot_feats) {
    foreach (@prot_feats) {
      if ($_->{hseqname} eq $hit_name) {
        $start = $_->{start} if($_->{start} < $start);
        $end   = $_->{end} if($_->{end} > $end);
      }
    }
  }

## EG visualising MS peptide domains
  (my $hit_db_spaces = $hit_db) =~ s/_/ /g;
  
  my $ms_domain = 0;
  my $web_data = from_json($pf->analysis->web_data);
  if (exists $web_data->{'type'}) {
    if ($web_data->{'type'} eq 'ms_domain') {
      $ms_domain = 1;
    }
  }
  
  if ($ms_domain) {
    $self->caption("$hit_name");
  } else {
    $self->caption("$hit_name ($hit_db_spaces)");
  }

  my $record_link = $hub->get_ExtURL($hit_db, $hit_name);
  if ($hit_db eq 'Gene3D' && $hit_name=~/:/){
    my ($prefix, $ext_id) = split(/:/, $hit_name);
    $record_link = $hub->get_ExtURL($hit_db, $ext_id) if $ext_id;
  } 
  
  if ($ms_domain) {
    $self->add_entry({
      type  => 'Study',
      label => $hit_db_spaces,
      link  => $record_link,
      external => 1,
    });
  } else {
    $self->add_entry({
      type  => 'View record',
      label => $hit_name,
      link  => $record_link,
      external => 1,
    });
  }
##  
  if ($interpro_ac) {
    $self->add_entry({
      type  => 'View InterPro',
      label => $interpro_ac,
      link  => $hub->get_ExtURL('interpro', $interpro_ac),
      external => 1,
    });
  }

## EG 
  if (!$ms_domain) {
  $self->add_entry({
    type  => 'Description',
    label => $pf->idesc
  });
  }
##
  
  $self->add_entry({
    type  => 'Position',
    label => $start . '-' . $end . ' aa'
  })if($hub->param('translation_id'));
}

1;
