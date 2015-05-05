=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Parsers::Blast;

use strict;
use warnings;

use XML::Simple;

sub new {
  my ($class, $hub) = @_;
  return bless {
    'hub' => $hub,
  }, $class;
}

sub parse_xml {
  my ($self, $xml, $species, $source_type) = @_;
  my $hub  = $self->{hub};
  my $db   = $hub->database('core', $species);
  my $data = XMLin($xml, ForceArray => ['hit', 'alignment']); 
  my $hits = $data->{SequenceSimilaritySearchResult}->{hits}->{hit};
  my @results;

  foreach my $hit_id (keys %$hits) {
    my $hit = $hits->{$hit_id};
    
    foreach my $align (@{ $hit->{alignments}->{alignment} }) {
      
      my $qstart = $align->{querySeq}->{start};
      my $qend   = $align->{querySeq}->{end};
      my $qori   = $qstart < $qend ? 1 : -1;

      my $tstart = $align->{matchSeq}->{start};
      my $tend   = $align->{matchSeq}->{end};
      my $tori   = $tstart < $tend ? 1 : -1;
      
      my ($qframe, $tframe) = split /\s*\/\s*/, $align->{frame} || ''; # E.g "+2 / -3"

      my $result = {
        qid    => 'Query_1', #??
        qstart => $qstart,
        qend   => $qend,
        qori   => $qori,
        qframe => $qframe,
        tid    => $hit_id,
        tstart => $tstart,
        tend   => $tend,
        tori   => $tori,
        tframe => $tframe,
        score  => $align->{score},
        evalue => $align->{expectation},
        pident => $align->{identity},
        len    => length($align->{querySeq}->{content}),
        aln    => btop($align->{querySeq}->{content}, $align->{matchSeq}->{content}),
      };
      
      push @results, $self->map_to_genome($result, $species, $source_type, $db);
    }
  }

  return \@results;
}

sub map_to_genome {
  my ($self, $hit, $species, $source_type, $dba) = @_;

  my ($g_id, $g_start, $g_end, $g_ori, $g_coords);

  if ($source_type =~/LATESTGP/) {

    $g_id     = $hit->{'tid'};
    $g_start  = $hit->{'tstart'};
    $g_end    = $hit->{'tend'};
    $g_ori    = $hit->{'tori'};

  } else {

    my $feature_type = $source_type =~ /abinitio/i ? 'PredictionTranscript' : $source_type =~ /pep/i ? 'Translation' : 'Transcript';
    my $mapper        = $source_type =~ /pep/i ? 'pep2genomic' : 'cdna2genomic';
    my $adaptor       = $dba->get_adaptor($feature_type);
    my $object        = $adaptor->fetch_by_stable_id($hit->{'tid'});

    if ($object) {
      eval {
        $object     = $object->transcript if $feature_type eq 'Translation';
        my @coords  = sort { $a->start <=> $b->start } grep { !$_->isa('Bio::EnsEMBL::Mapper::Gap') } $object->$mapper($hit->{'tstart'}, $hit->{'tend'}, $hit->{'tori'});
        $g_id       = $object->seq_region_name;
        $g_start    = $coords[0]->start;
        $g_end      = $coords[-1]->end;
        $g_ori      = $object->strand;
        $g_coords   = \@coords;
      };
      warn "Warning - failed mapping feature to geneome: " . $@ if $@;
    }

    if (!$g_id) {
      $g_id       = 'Unmapped';
      $g_start    = 'N/A';
      $g_end      = 'N/A';
      $g_ori      = 'N/A'
    }
  }

  $hit->{'gid'}       = $g_id;
  $hit->{'gstart'}    = $g_start;
  $hit->{'gend'}      = $g_end;
  $hit->{'gori'}      = $g_ori;
  $hit->{'species'}   = $species;
  $hit->{'source'}    = $source_type;
  $hit->{'g_coords'}  = $g_coords if $g_coords;

  return $hit;
}

sub btop {
  my ($query_seq, $match_seq) = @_;

  my @q       = split '', $query_seq;
  my @m       = split '', $match_seq;
  my $counter = 0;
  my $btop    = '';

  for (0..$#q) {
    $counter++, next if $q[$_] eq $m[$_];
    $btop    .= ($counter || '') . $q[$_] . $m[$_];
    $counter  = 0;
  }

  $btop .= $counter || '';

  return $btop;
}

1;
