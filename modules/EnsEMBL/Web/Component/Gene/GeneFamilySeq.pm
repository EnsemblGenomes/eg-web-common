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

# $Id: HomologSeq.pm,v 1.4 2013-10-03 14:55:18 nl2 Exp $

package EnsEMBL::Web::Component::Gene::GeneFamilySeq;

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
  my $self             = shift;
  my $hub              = $self->hub;
  my $species_defs     = $hub->species_defs;
  my $gene_family_id   = $self->param('gene_family_id');
  my $format           = $self->param('_format');  
  my $object           = $self->object;
  my $gene_stable_id   = $object->stable_id;
  my $compara_db       = $object->database('compara');
  my $family_adaptor   = $compara_db->get_FamilyAdaptor;
  my $family           = $family_adaptor->fetch_by_stable_id($gene_family_id);
  my $filtered_data    = $object->filtered_family_data($family, 1);
  my $html = '';

  my $lookup = $species_defs->prodnames_to_urls_lookup;
  foreach my $member_data (@{$filtered_data->{members}}) {

    my $sequence = $member_data->{sequence};
    next unless $sequence;

    my $title = join ' ', $member_data->{id}, $member_data->{description}, '('.$species_defs->species_label($lookup->{$member_data->{species}}).')';
    $title   .= " (gene=$member_data->{name})" if $member_data->{name};

    if($format =~ /^text$/i){
      $sequence =~ s/(.{60})/$1\n/g;
      $html .= sprintf(">%s\n%s\n\n", $title, $sequence); 
    }
    else{
      $sequence =~ s/(.{60})/$1<\/br>/g;
      $html .= sprintf('<pre><em>>%s</em></br>%s</pre>', $title, $sequence); 
    }
  }
  
  return $html;
}        

1;
