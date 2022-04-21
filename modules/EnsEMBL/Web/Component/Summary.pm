=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Summary;

use strict;

use EnsEMBL::Web::Utils::FormatText qw(helptip glossary_helptip get_glossary_entry);


sub set_columns {
  my $self = shift;

  my @columns = (
       { key => 'name',       sort => 'string',  title => 'Name'          },
       { key => 'transcript', sort => 'html',    title => 'Transcript ID' },
       { key => 'bp_length',  sort => 'numeric', label => 'bp', title => 'Length in base pairs'},
       { key => 'protein',sort => 'html_numeric',label => 'Protein', title => 'Protein length in amino acids' },
       { key => 'translation',sort => 'html',    title => 'Translation ID', 'hidden' => 1 },
       { key => 'biotype',    sort => 'html',    title => 'Biotype', align => 'left' },
    );

  return @columns;
}

sub get_synonym_html {
  my ($self, $gene) = @_;
  my $object = $self->object; 

  my $syns_html = '';
  # check if synonyms are attached  via display xref .. 
  my ($display_name) = $object->display_xref;
  if (my $xref = $object->Obj->display_xref) {
  my $sn = $xref->get_all_synonyms;
    if (scalar @{$sn||[]}) {
      my $syns = join ', ', grep { $_ && ($_ ne $display_name) } @$sn;
      $syns_html = "<p>$syns</p>";
    }
  }
  return $syns_html;
}


## EG matches need to support mysql LIKE instead of regex
sub get_extra_links {
  my $self = shift;
  my $hub = $self->hub;

  return {
      uniprot => { 
          match => "UniProt/S%", 
          name => "UniProt", 
          order => 0, 
          title => get_glossary_entry($hub, 'UniProt Match') 
        },
      refseq => { 
          match => "RefSeq%", 
          name => "RefSeq", 
          order => 1,
          title => "RefSeq transcripts with sequence similarity and genomic overlap" 
        },
    };
}

## hacked to avoid using the v.slow $gene->get_all_DBLinks()
sub get_gene_display_link {
  ## @param Gene object
  ## @param Gene xref object or description string
  my ($self, $gene, $xref) = @_;
  
  my $hub = $self->hub;
  my $dbname;
  my $primary_id;
  
  if ($xref && !ref $xref) { 
    # description string    
    my $details = { map { split ':', $_, 2 } split ';', $xref =~ s/^.+\[|\]$//gr }; #/
    if ($details->{'Source'} and $details->{'Acc'}) {
      my $dbh     = $hub->database($self->object->get_db)->dbc->db_handle;
      $dbname     = $dbh->selectrow_array('SELECT db_name FROM external_db WHERE db_display_name = ?', undef, $details->{'Source'});
      $primary_id = $details->{'Acc'};
    }
  } else { 
    # xref object
    if ($xref->info_type ne 'PROJECTION') {;
      $dbname     = $xref->dbname;
      $primary_id = $xref->primary_id;
    }
  }

  my $url = $hub->get_ExtURL($dbname, $primary_id) if $dbname and $primary_id;

  return $url ? ($url, $primary_id) : ()
}

1;
