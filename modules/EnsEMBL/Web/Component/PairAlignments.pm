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

# $Id $

package EnsEMBL::Web::Component::PairAlignments;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $cdb          = shift || $hub->param('cdb') || 'compara';
  my $species_defs = $hub->species_defs;
  my $db_hash      = $species_defs->multi_hash;
  my $alignments   = $db_hash->{'DATABASE_COMPARA' . ($cdb =~ /pan_ensembl/ ? '_PAN_ENSEMBL' : '')}{'ALIGNMENTS'} || {}; # Get the compara database hash

  return unless %$alignments;
  
  my $species = $hub->species;
  
  my %data;
  foreach my $aln( values %$alignments) {
    foreach my $sp1 (keys %{$aln->{'species'}}){
      foreach my $sp2 (keys %{$aln->{'species'}}){
        next if $sp1 eq $sp2;
        $data{$sp1} = [] unless exists $data{$sp1};
        push(@{$data{$sp1}}, {species=> $species_defs->SPECIES_COMMON_NAME($sp2), id=>$aln->{'id'}, type=>$aln->{'type'},'set'=>$aln->{'species_set_id'}});
      }
    }
  }
    
  if($species){
    my $loc=$species_defs->SAMPLE_DATA->{LOCATION_PARAM};
    my $table = $self->align_table($species,$loc,$data{$species},'position:absolute; z-index:1; width:40% !important;');
    exists $data{$species}
      ? return sprintf(qq{<a rel="%s_aligns" class="toggle no_img closed" href="#" title="expand"><span class="closed"><small>Show</small>&raquo;</span><span class="open">&laquo;<small>Hide</small></span></a>%s}, $species, $table)
      : return '';
  }
  my @rows;
  foreach my $sp1 ( sort keys %data){
    my $loc=$species_defs->SAMPLE_DATA($sp1) ? $species_defs->SAMPLE_DATA($sp1)->{LOCATION_PARAM} : undef;
    my $align_table = $self->align_table($sp1,$loc,$data{$sp1});
    my $count = scalar @{$data{$sp1}};
    my $row = sprintf('<a title="Click to show/hide" rel="%s_aligns" class="toggle no_img closed" href="#"><span class="open closed" style="width:50%;float:left;"><strong><em>%s</em></strong></span></a> <span style="width:20px; float:left; text-align:right;padding-right:1em;">%d</span> genome alignment%s %s',
      $sp1,$species_defs->SPECIES_COMMON_NAME($sp1),
      $count,
      ($count > 1) ? "s" : "",
      $align_table);
    push(@rows, {species=>$row});
  }
      
  my $table = $self->new_table(
    [
      {key=>'species',title=>'Species', sort=>'text'},
    ],
    \@rows,
    {
      data_table=>0,id=>'genomic_align_table',sorting => ['species'],
      exportable=>0,
      header=>'no',
      class=>sprintf('no_col_toggle'),
    },
  );
  my $button = $self->dom->create_element('a',{href=>'#',rel=>'all_species_tables',class=>'toggle closed',title=>'Expand all tables',inner_HTML=>'<span class="closed">Toggle All</span><span class="open">Toggle All</span>'});
  return sprintf(qq{<div class="info-box"><p>%s or click a species names to expand/collapse its alignment list</h3>%s</div>}, $button->render, $table->render);
}

sub align_table {
  my ($self, $sp1, $loc, $data, $style)=@_;
  my $species_defs = $self->hub->species_defs;
  my @rows;
  my @sorted_data = sort { $a->{species} cmp $b->{species} } @$data;

  foreach my $aln (@sorted_data){  
    my $sp1name = $species_defs->SPECIES_COMMON_NAME($sp1);
    my $sp2name = $aln->{'species'};

    my $url = '/info/genome/compara/mlss/mlss_'.$aln->{'id'}.'/mlss_'.$aln->{'id'}.'.html';

    push(@rows,
      {
      'species' => $loc ? $self->_link(sprintf('<em>%s</em> : <em>%s</em>',$sp1name,$sp2name),$url):$aln->{'species'},
      'type' => $aln->{'type'}
      }
    );
  }

  my $table = $self->new_table(
    [
      {key=>'species',title=>'Species'},
      {key=>'type',title=>'Type',align=>'right'},
    ],
    \@rows,
    {
      data_table=>0,id=>$sp1 . '_aligns',toggleable=>1,
      exportable=>0,
      header=>'no',
      class=>sprintf('all_species_tables no_col_toggle hide'),
      style=>$style,
    },
  );
  return $table->render;
}

sub _link {
  my ($self,$text,$url)=@_;
  return sprintf(qq{<a href="%s">%s</a>},$url,$text);
}

1;
