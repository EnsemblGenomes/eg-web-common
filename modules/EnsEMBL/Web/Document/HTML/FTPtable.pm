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

package EnsEMBL::Web::Document::HTML::FTPtable;

sub multi_table {
  my ($self, $rel, %title) = @_;
  my $hub             = $self->hub;
  my $species_defs    = $hub->species_defs;
  my $ftp             = $species_defs->ENSEMBL_GENOMES_FTP_URL;

  ## Override default parameter
  $rel = $species_defs->SITE_RELEASE_VERSION;

  my $genomic_unit = $species_defs->GENOMIC_UNIT;

  my $g_units = {
   'bacteria' => 'Bacterial',
   'fungi'    => 'Fungal',
   'metazoa'  => 'Metazoa',
   'plants'   => 'Plants',
   'protists' => 'Protists',
  };

  my $pan_compara = $species_defs->get_config('MULTI', 'databases')->{DATABASE_COMPARA_PAN_ENSEMBL}->{NAME};
  my $compara = $species_defs->get_config('MULTI', 'databases')->{DATABASE_COMPARA}->{NAME};
  my $multi_sp = $g_units->{$genomic_unit};
  my $multi_table    = EnsEMBL::Web::Document::Table->new(
    [
      {key=>'database',    sort=>'html',title=>'Database'},
      {key => 'mysql',    sort=>'none',title => 'MySQL' },  
      {key => 'tsv',      sort=>'none',title => 'TSV'   },    
      {key => 'emf',      sort=>'none',title => 'EMF'   },
      {key => 'maf',      sort=>'none',title => 'MAF'   },
      {key => 'xml',      sort=>'none',title => 'XML'   },    
    ],
    [
      {
      database => qq{<strong>Pan_compara Multi-species</strong>},
      mysql   => qq{<a rel="external" title="$title{pan}" href="$ftp/release-$rel/pan/mysql/$pan_compara/">MySQL</a>},
      emf     => qq{<a rel="external" title="$title{emf}" href="$ftp/release-$rel/pan/emf/ensembl-compara/homologies">EMF</a>},
      tsv     => qq{<a rel="external" title="$title{tsv}" href="$ftp/release-$rel/pan/tsv/ensembl-compara/homologies">TSV</a>},
      xml     => qq{<a rel="external" title="$title{xml}" href="$ftp/release-$rel/pan/xml/ensembl-compara/homologies">XML</a>}
      },
      {
      database => qq{<strong>$multi_sp Multi-species</strong>},
      mysql   => sprintf(qq{<a rel="external" title="%s" href="$ftp/$genomic_unit/release-$rel/mysql/$compara">MySQL</a>},sprintf($title{compara},ucfirst $genomic_unit)),
      emf     => qq{<a rel="external" title="$title{emf}" href="$ftp/$genomic_unit/release-$rel/emf/ensembl-compara/homologies">EMF</a>},
      tsv     => qq{<a rel="external" title="$title{tsv}" href="$ftp/$genomic_unit/release-$rel/tsv/ensembl-compara/homologies">TSV</a>},
      maf     => qq{<a rel="external" title="$title{maf}" href="$ftp/$genomic_unit/release-$rel/maf/">MAF</a>},
      xml     => qq{<a rel="external" title="$title{xml}" href="$ftp/$genomic_unit/release-$rel/xml/ensembl-compara/homologies">XML</a>},
      },
      {
      database => qq{<strong>Ensembl Mart</strong>},
      mysql   => sprintf(qq{<a rel="external" title="%s" href="$ftp/$genomic_unit/release-$rel/mysql/$genomic_unit\_mart_$rel">MySQL</a>},sprintf($title{mart},ucfirst $genomic_unit)),
      }
    ],
    { data_table=>0 }
  );

  return $multi_table; 
}

sub metadata {
  my $self = shift;
  my $sd = $self->hub->species_defs;

  my $ftp = $sd->ENSEMBL_GENOMES_FTP_URL;
  my $division = $sd->EG_DIVISION;
  my $uc_div   = ucfirst($division);

  return qq(
<h3>Metadata</h3>

<p>Data files containing metadata for Ensembl Genomes from release 15 onwards can be found 
in the root directory or appropriate division directory of each release e.g.
<a href="$ftp/current/$division/">$ftp/current/$division/</a>.</p>

<p>The following files are provided:</p>

<ul>
  <li><a href="$ftp/current/species.txt">species.txt</a> (or e.g. <a href="$ftp/current/$division/species_Ensembl$uc_div.txt">species_Ensembl$uc_div.txt</a>) - simple tab-separated file containing basic information about each genome</li>
  <li><a href="$ftp/current/species_metadata.json">species_metadata.json</a> (or e.g. <a href="$ftp/current/$division/species_metadata_Ensembl$uc_div.json">species_metadata_Ensembl$uc_div.json</a>) - full metadata about each genome in JSON format, including comparative analyses, sequence region names etc.</li>
  <li><a href="$ftp/current/species_metadata.xml">species_metadata.xml</a> (or e.g. <a href="$ftp/current/$division/species_metadata_Ensembl$uc_div.xml">species_metadata_Ensembl$uc_div.xml</a>) - full metadata about each genome in XML format, including comparative analyses, sequence region names etc.</li>
  <li><a href="$ftp/current/uniprot_report.txt">uniprot_report.txt</a> (or e.g. <a href="$ftp/current/$division/uniprot_report_Ensembl$uc_div.txt">uniprot_report_Ensembl$uc_div.txt</a>) - specialised tab-separated file containing information about mapping of genome to UniProtKB</li>
</ul>
  );

}

1;
