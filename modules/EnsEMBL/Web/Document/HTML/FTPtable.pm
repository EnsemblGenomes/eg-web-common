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

package EnsEMBL::Web::Document::HTML::FTPtable;

### This module outputs a table of links to the FTP site

use strict;
use warnings;

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::Document::Table;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self = shift;

  my $hub             = new EnsEMBL::Web::Hub;
  my $species_defs    = $hub->species_defs;

  my $rel = $species_defs->SITE_RELEASE_VERSION;

  my @species = $species_defs->valid_species;
  my %title = (
    dna       => 'Masked and unmasked genome sequences associated with the assembly (contigs, chromosomes etc.)',
    cdna      => 'cDNA sequences for protein-coding genes',
    ncrna     => 'Non-coding RNA sequences',
    prot      => 'Protein sequences for protein-coding genes',
    rna       => 'Non-coding RNA gene predictions',
    embl      => 'Ensembl Genomes database dumps in EMBL nucleotide sequence database format',
    genbank   => 'Ensembl Genomes database dumps in GenBank nucleotide sequence database format',
    gtf       => 'Gene sets for each species in GTF format. These files include annotations of both coding and non-coding genes',
    gff3      => 'Gene sets and other features for each species in GFF3 format. These files include genes, transcripts and repeat features',
    emf       => 'Alignments of resequencing data from the Compara database',
    gvf       => 'Variation data in GVF format',
    vcf       => 'Variation data in VCF format',
    vep       => 'Cache files for use with the VEP script',
    coll      => 'Additional regulation data (not in database)',
    bed       => 'Constrained elements calculated using GERP',
    files     => 'Additional release data stored as flat files rather than MySQL for performance reasons',
    ancestral => 'Ancestral Allele data in FASTA format',
    bam       => 'Alignments against the genome',
    core      => '%s core data export',
    otherfeatures     => '%s other features data export',
    variation      => '%s variation data export',
    funcgen   => '%s funcgen data export',
    pan       => 'Pan-taxomic Compara data export',
    compara   => '%s Compara data export',
    mart      => '%s BioMart data export',
    tsv       => 'Tab separated files containing selected data for individual species and from comparative genomics',

  );
  $title{$_} = encode_entities($title{$_}) for keys %title;

  my @rows;
  foreach my $spp (sort @species) {
    (my $sp_name = $spp) =~ s/_/ /;
     my $sp_dir =lc($spp);
     my $sp_var = lc($spp).'_variation';
     my $common = $species_defs->get_config($spp, 'SPECIES_COMMON_NAME');

    my $genomic_unit = $species_defs->get_config($spp, 'GENOMIC_UNIT');
    my $collection;
    if($genomic_unit =~ /bacteria/i){
      my $group = lc $species_defs->get_config($spp, 'SPECIES_GROUP');
      $collection = $group . '_collection/'  if $group;
    }
    my $ftp_base_path_stub = "ftp://ftp.ensemblgenomes.org/pub/release-$rel/$genomic_unit";
    my @mysql;
    foreach my $db( qw/core otherfeatures funcgen variation/){
      my $db_config =  $species_defs->get_config($spp, 'databases')->{'DATABASE_' . uc($db)};
      if($db_config){
        my $title = sprintf($title{$db}, $sp_name);
        my $db_name = $db_config->{NAME};
        push(@mysql, qq{<a rel="external" title="$title" href="$ftp_base_path_stub/mysql/$db_name">MySQL($db)</a>});
      }
    }
        
    my $data = {
species    => qq{<strong><i>$sp_name</i></strong>},
dna        => qq{<a rel="external"  title="$title{'dna'}" href="$ftp_base_path_stub/fasta/$sp_dir/dna/">FASTA</a> (DNA)},
cdna       => qq{<a rel="external"  title="$title{'cdna'}" href="$ftp_base_path_stub/fasta/$sp_dir/cdna/">FASTA</a> (cDNA)},
ncrna      => qq{<a rel="external"  title="$title{'ncrna'}" href="$ftp_base_path_stub/fasta/$sp_dir/ncrna/">FASTA</a> (ncRNA)},
prot       => qq{<a rel="external"  title="$title{'prot'}" href="$ftp_base_path_stub/fasta/$sp_dir/pep/">FASTA</a> (protein)},
embl       => qq{<a rel="external"  title="$title{'embl'}" href="$ftp_base_path_stub/embl/} . $sp_dir . qq{/">EMBL</a>},
genbank    => qq{<a rel="external"  title="$title{'genbank'}" href="$ftp_base_path_stub/genbank/} . $sp_dir . qq{/">GenBank</a>},
gtf        => qq{<a rel="external"  title="$title{'gtf'}" href="$ftp_base_path_stub/gtf/$sp_dir">GTF</a>},
gff3       => qq{<a rel="external"  title="$title{'gff3'}" href="$ftp_base_path_stub/gff3/$sp_dir">GFF3</a>},
mysql      => join('<br/>',@mysql),
tsv        => qq{<a rel="external"  title="$title{'tsv'}" href="$ftp_base_path_stub/tsv/$sp_dir/">TSV</a>},
vep        => qq{<a rel="external"  title="$title{'vep'}" href="$ftp_base_path_stub/vep/">VEP</a>},
    };
    my $db_hash = $hub->databases_species($spp, 'variation');
    if ($db_hash->{variation}) {
      $data->{'gvf'} = qq{<a rel="external" title="$title{'gvf'}" href="$ftp_base_path_stub/gvf/$sp_dir">GVF</a>};
      $data->{'vcf'} = qq{<a rel="external" title="$title{'vcf'}" href="$ftp_base_path_stub/vcf/$sp_dir">VCF</a>};
    }
    push(@rows, $data);
  }

  my $genomic_unit = $species_defs->GENOMIC_UNIT;

  my $g_units = {
   'bacteria' => 'Bacterial',
   'fungi'    => 'Fungal',
   'metazoa'  => 'Metazoa',
   'plants'   => 'Plants',
   'protists' => 'Protists',
  };


  my $table    = EnsEMBL::Web::Document::Table->new(
    [
      {key=>'species',    sort=>'html', title=>'Species'},
      {key => 'dna',      sort=>'none', title => 'DNA'},    
      {key => 'cdna',     sort=>'none', title => 'cDNA'},
      {key => 'ncrna',    sort=>'none', title => 'ncRNA'},   
      {key => 'prot',     sort=>'none', title => 'Protein'},    
      {key => 'embl',     sort=>'none', title => 'EMBL'},   
      {key => 'genbank',  sort=>'none', title => 'GENBANK'},
      {key => 'mysql',    sort=>'none', title => 'MySQL'},  
      {key => 'tsv',      sort=>'none', title => 'TSV'},    
      {key => 'gtf',      sort=>'none', title => 'GTF'},    
      {key => 'gff3',     sort=>'none', title => 'GFF3'},   
      {key => 'gvf',      sort=>'none', title => 'GVF'},    
      {key => 'vcf',      sort=>'none', title => 'VCF'},    
      {key => 'vep',      sort=>'none', title => 'VEP'},
    ],
    \@rows,
    { data_table=>1, exportable=>0 }
  );
  $table->code = 'FTPtable::'.scalar(@rows);
  $table->{'options'}{'data_table_config'} = {iDisplayLength => 10};

  my $pan_compara = $species_defs->get_config('MULTI', 'databases')->{DATABASE_COMPARA_PAN_ENSEMBL}->{NAME};
  my $compara = $species_defs->get_config('MULTI', 'databases')->{DATABASE_COMPARA}->{NAME};
  my $multi_sp = $g_units->{$genomic_unit};
  my $multi_table    = EnsEMBL::Web::Document::Table->new(
    [
      {key=>'database',    sort=>'html',title=>'Database'},
      {key => 'mysql',    sort=>'none',title => 'MySQL' },  
      {key => 'tsv',      sort=>'none',title => 'TSV'   },    
      {key => 'emf',      sort=>'none',title => 'EMF'   },    
    ],
    [
      {
      database => qq{<strong>Pan_compara Multi-species</strong>},
      mysql   => qq{<a rel="external" title="$title{pan}" href="ftp://ftp.ensemblgenomes.org/pub/pan_ensembl/release-$rel/mysql/$pan_compara/">MySQL</a>},
      emf     => qq{<a rel="external" title="$title{emf}" href="ftp://ftp.ensemblgenomes.org/pub/pan_ensembl/release-$rel/emf/ensembl-compara/homologies">EMF</a>},
      tsv     => qq{<a rel="external" title="$title{tsv}" href="ftp://ftp.ensemblgenomes.org/pub/pan_ensembl/release-$rel/tsv/ensembl-compara/">TSV</a>},
      },
      {
      database => qq{<strong>$multi_sp Multi-species</strong>},
      mysql   => sprintf(qq{<a rel="external" title="%s" href="ftp://ftp.ensemblgenomes.org/pub/$genomic_unit/release-$rel/mysql/$compara">MySQL</a>},sprintf($title{compara},ucfirst $genomic_unit)),
      emf     => qq{<a rel="external" title="$title{emf}" href="ftp://ftp.ensemblgenomes.org/pub/pan_ensembl/release-$rel/emf/ensembl-compara/homologies">EMF</a>},
      tsv     => qq{<a rel="external" title="$title{tsv}" href="ftp://ftp.ensemblgenomes.org/pub/$genomic_unit/release-$rel/tsv/ensembl-compara">TSV</a>},
      },
      {
      database => qq{<strong>Ensembl Mart</strong>},
      mysql   => sprintf(qq{<a rel="external" title="%s" href="ftp://ftp.ensemblgenomes.org/pub/$genomic_unit/release-$rel/mysql/$genomic_unit\_mart_$rel">MySQL</a>},sprintf($title{mart},ucfirst $genomic_unit)),
      }
    ],
    { data_table=>0 }
  );
  $table->add_option('class','no_col_toggle');

  return sprintf(qq{<h3>Multi-species data</h3>%s<h3>Single species data</h3><div id="species_ftp_dl" class="js_panel"><input type="hidden" class="panel_type" value="Content"/>%s</div>},
    $multi_table->render,$table->render);
      
}



1;
