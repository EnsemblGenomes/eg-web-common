#!/usr/local/bin/perl
# Copyright [2009-2014] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Dump search XML files for indexing by the EBEye search engine.
#

package ebi_search_dump;

use strict;
use DBI;
use Carp;
use File::Find;
use Getopt::Long;
use IO::Zlib;
use Data::Dumper;
use HTML::Entities;
use FindBin qw($Bin);
use lib $Bin;
use LibDirs;
use utils::Tool;

my (
  $host,    $user,        $pass,   $port,     $species, $ind,
  $release, $max_entries, $parallel, $dir,     $inifile,
  $nogenetrees, $novariation, $noxrefs, $skip_existing, $noortholog, $nodomaindescription,
);

my %rHash = map { $_ } @ARGV;
if ( $inifile = $rHash{'-inifile'} ) {
  my $icontent = `cat $inifile`;
  warn $icontent;
  eval $icontent;
}

GetOptions(
  "host=s",        \$host,        "port=i",    \$port,
  "user=s",        \$user,        "pass=s",    \$pass,
  "species=s",     \$species,     "release=s", \$release,
  "index=s",       \$ind,         
  "max_entries=i", \$max_entries, "parallel",  \$parallel,
  "dir=s",         \$dir,         "help",      \&usage,
  "inifile=s",     \$inifile,  
  "nogenetrees",   \$nogenetrees,
  "novariation",   \$novariation,
  "noxrefs",       \$noxrefs,
  "skipexisting",   \$skip_existing,
  "noortholog",       \$noortholog,
  "nodomaindescription", \$nodomaindescription,
  );

$ind     ||= 'ALL';
$dir     ||= ".";
$release ||= 'LATEST';

usage() and exit unless ( $host && $port && $user);

## HACK 1 - if the INDEX is set to all grab all dumper methods...
my @indexes = split ',', $ind;
@indexes = map { /dump(\w+)/ ? $1 : () } keys %ebi_search_dump:: if $ind eq 'ALL';
#warn Dumper \@indexes;

my $dbHash = get_databases();
print "*** No databases found ***\n" unless %{$dbHash};
#warn Dumper $dbHash;

my @datasets = split ',', $species;
# restrict species to only those defined in the current eg site
@datasets = @datasets ? @{ utils::Tool::check_species(\@datasets) } : @{ utils::Tool::all_species() };

print "\nDatasets to process: \n  " . join("\n  ", @datasets) . "\n";

my $entry_count;
my $global_start_time = time;
my $total             = 0;

foreach my $dataset ( @datasets ) {
  my $conf = $dbHash->{lc($dataset)};

  foreach my $index (@indexes) {
    my $function = "dump$index";
    no strict "refs";

    $dataset =~ s/_/ /g;

    &$function( ucfirst($dataset), $conf );
  }
}

print_time($global_start_time);
warn " Dumped $total entries ...\n";

#------------------------------------------------------------------------------

sub text_month {
  my $m = shift;
  my @months = qw[JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC];
  return $months[$m];
}

sub print_time {
  my $start = shift;
  my $t = time - $start;
  my $s = $t % 60;
  $t = ( $t - $s ) / 60;
  my $m = $t % 60;
  $t = ( $t - $m ) / 60;
  my $h = $t % 60;
  print "Time taken: " . $h . "h " . $m . "m " . $s . "s\n";
}

sub usage {
  print <<EOF; exit(0);

Usage: perl $0 <options>
  
  -host         REQUIRED. Database host to connect to. 
  -port         REQUIRED. Database port to connect to. 
  -user         Database username. Defaults to ensro.
  -species      Species name. Defaults to ALL.
  -index        Index to create. Defaults to ALL.
  -release      Release of the database to dump. Defaults to 'latest'.
  -pass         Password for user.
  -dir          Directory to write output to. Defaults to /lustre/scratch1/ensembl/gp1/xml.
  -nogzip       Don't compress output as it's written.
  -help         This message.
  -inifile      First take the arguments from this file. Then overwrite with what is provided in the command line

EOF
}

sub get_databases {

  my ( $dbHash, $dbcHash );
  
  my $dsn = "DBI:mysql:host=$host";
  $dsn .= ";port=$port" if ($port);

  my $dbh = DBI->connect( $dsn, $user, $pass );
  my @dbnames = map { $_->[0] } @{ $dbh->selectall_arrayref("show databases") };
  $dbh->disconnect();

  my $latest_release = 0;
  my ( $db_species, $db_release, $db_type );
  my $compara_hash;
  for my $dbname (@dbnames) {

    if ( ($db_type, $db_release) = $dbname =~ /^ensembl_compara_(\w+)_(\d+)_\w+/ ) {
       
      $compara_hash->{$db_type}->{$db_release} = $dbname;
    
    } elsif ( ( $db_species, $db_type, $db_release ) = $dbname =~ /^([a-z]+_[a-z0-9]+)(?:_collection)?_([a-z]+)_(\d+)_\w+$/ ) {

      $db_species =~ s/_collection$//;
      $latest_release = $db_release if ( $db_release > $latest_release );
      $dbHash->{$db_species}->{$db_type}->{$db_release} = $dbname;

    } 
  }

  map { $dbHash->{$_}->{'compara'} = $compara_hash } keys %$dbHash;
  $release = $latest_release if ( $release eq 'LATEST' );

  return $dbHash;
}

sub footer {
  my ($ecount) = @_;

  p("</entries>");
  p("<entry_count>$ecount</entry_count>");
  p("</database>");

  print "Dumped $ecount entries\n";
  close(FILE) or die $!;
  $total += $ecount;
}

sub header {
  my ( $dbname, $dataset, $dbtype ) = @_;

  p("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>");
  p("<!DOCTYPE database [ <!ENTITY auml \"&#228;\">]>");
  p("<database>");
  p("<name>$dbname</name>");
  p("<description>Ensembl Genomes $dataset $dbtype database</description>");
  p("<release>$release</release>");
  p("");
  p("<entries>");
}

sub p {
  my ($str) = @_;
  # TODO - encoding
  $str .= "\n";
  print FILE $str or die "Can't write to file ", $!;
}

sub format_date {
  my $t = shift;
  my ( $y, $m, $d, $ss, $mm, $hh ) = ( localtime($t) )[ 5, 4, 3, 0, 1, 2 ];
  $y += 1900;
  $d = "0" . $d if ( $d < 10 );
  my $mm = text_month($m);
  return "$d-$mm-$y";
}

sub format_datetime {
  my $t = shift;
  my ( $y, $m, $d, $ss, $mm, $hh ) = ( localtime($t) )[ 5, 4, 3, 0, 1, 2 ];
  $y += 1900;
  $d = "0" . $d if ( $d < 10 );
  my $ms = text_month($m);
  return sprintf "$d-$ms-$y %02d:%02d:%02d", $hh, $mm, $ss;
}

sub connect_db {
  my $db_name = shift;

  my $dsn = "DBI:mysql:host=$host";
  $dsn .= ";port=$port" if ($port);

  my $dbh;  
  my $attempt = 0;
  my $max_attempts = 100;
  while (!$dbh and ++$attempt <= $max_attempts) {
    eval { $dbh = DBI->connect( "$dsn:$db_name", $user, $pass ) };
    warn "DBI connect error: $@" if $@;
    if (!$dbh) {
      warn "Failed DBI connect attempt $attempt of $max_attempts\n" if !$dbh;
      sleep 5;
    }
  }

  return $dbh;
}

sub dumpGene {

  my ( $dataset, $conf ) = @_;

  foreach my $DB (qw(core otherfeatures)) {
    my $SNPDB     = $novariation ? undef : eval { $conf->{variation}->{$release} };
    my $FUNCGENDB = eval { $conf->{funcgen}->{$release} };
    my $DBNAME    = $conf->{$DB}->{$release} or warn "$dataset $DB $release: no database not found";
    next unless $DBNAME;
    
    print "\nSTART dumpGene\n";
    print "Database: $DBNAME\n";
      
    my $dbh = connect_db($DBNAME);
  
    my $has_stable_ids = $dbh->selectrow_array('SELECT COUNT(*) FROM gene WHERE stable_id IS NOT NULL');
    if (!$has_stable_ids) {
      warn "Skipping this database - the genes do not have stable IDs\n";
      return;
    }
  
    $dbh->do("SET sql_mode = 'NO_BACKSLASH_ESCAPES'"); # metazoa have backslahes in thier gene names and synonyms :.(
    
    # determine genomic unit
    my $division = $dbh->selectrow_array("SELECT meta_value FROM meta WHERE meta_key = 'species.division'");
    (my $genomic_unit = lc($division)) =~ s/^ensembl//; # eg EnsemblProtists -> protists
    print "Genomic unit: " . $genomic_unit . "\n";
  
    my $genetree_lookup = $nogenetrees ? {} : get_genetree_lookup($genomic_unit, $conf);
    
    my $haplotypes = $dbh->selectall_hashref(
      "SELECT gene_id FROM gene g, assembly_exception ae WHERE g.seq_region_id=ae.seq_region_id AND ae.exc_type='HAP'", 
      [qw(gene_id)]
    );
  
    my %transcript_probes;
    my %transcript_probesets;
    if ($FUNCGENDB) {
    
      print "Fetching probes...\n";  
    
      my $rows = $dbh->selectall_arrayref(
        "SELECT x.dbprimary_acc, p.name 
         FROM $FUNCGENDB.probe p, $FUNCGENDB.array_chip ac, $FUNCGENDB.array a, $FUNCGENDB.status s, 
              $FUNCGENDB.status_name sn, $FUNCGENDB.object_xref ox, $FUNCGENDB.xref x 
         WHERE sn.name='MART_DISPLAYABLE'        
         AND sn.status_name_id=s.status_name_id       
         AND s.table_name='array'        
         AND s.table_id=a.array_id              
         AND p.array_chip_id = ac.array_chip_id        
         AND ac.array_id = a.array_id
         AND p.probe_id=ox.ensembl_id
         AND ox.ensembl_object_type='Probe'
         AND ox.xref_id=x.xref_id
         GROUP BY ox.object_xref_id"
      );
      
      foreach (@$rows) {
        $transcript_probes{$_->[0]} ||= [];
        push @{$transcript_probes{$_->[0]}}, $_->[1];
      }
      
      print "Fetching probe sets...\n";  
    
      $rows = $dbh->selectall_arrayref(
        "SELECT x.dbprimary_acc, ps.name 
         FROM $FUNCGENDB.probe_set ps, $FUNCGENDB.probe p, $FUNCGENDB.array_chip ac, $FUNCGENDB.array a, 
              $FUNCGENDB.status s, $FUNCGENDB.status_name sn, $FUNCGENDB.object_xref ox, $FUNCGENDB.xref x 
         WHERE sn.name='MART_DISPLAYABLE'        
         AND sn.status_name_id=s.status_name_id       
         AND s.table_name='array'        
         AND s.table_id=a.array_id        
         AND ps.probe_set_id = p.probe_set_id             
         AND p.array_chip_id = ac.array_chip_id        
         AND ac.array_id = a.array_id
         AND ps.probe_set_id=ox.ensembl_id
         AND ox.ensembl_object_type='ProbeSet'
         AND ox.xref_id=x.xref_id
         GROUP BY ox.object_xref_id;"
      );
      
      foreach (@$rows) {
        $transcript_probesets{$_->[0]} ||= [];
        push @{$transcript_probesets{$_->[0]}}, $_->[1];
      }
    }
  
    my %xrefs      = ();
    my %xrefs_desc = ();
    my %disp_xrefs = ();
    unless ($noxrefs) {
      foreach my $type (qw(Gene Transcript Translation)) {
    
        print "Fetching $type xrefs...\n";
              
        my $xrefs = [];
        if ($type eq 'Translation') {

            # Interpro
            $xrefs = $dbh->selectall_arrayref(
              "SELECT pf.translation_id, x.display_label, x.dbprimary_acc, ed.db_name, es.synonym, x.description
               FROM (protein_feature AS pf, interpro AS i, xref AS `x`, external_db AS ed)
               LEFT JOIN external_synonym AS es ON es.xref_id = x.xref_id
               WHERE pf.hit_name = i.id AND i.interpro_ac = x.dbprimary_acc 
               AND x.external_db_id = ed.external_db_id AND ed.db_name = 'Interpro'"
            );

        } else { 
          
          my $table = lc($type);
          
          $xrefs = $dbh->selectall_arrayref(
            "SELECT t.${table}_id, x.display_label, x.dbprimary_acc, ed.db_name, es.synonym, x.description
             FROM ${table} t
             JOIN xref x ON x.xref_id = t.display_xref_id
             JOIN external_db ed ON ed.external_db_id = x.external_db_id
             LEFT JOIN external_synonym es ON es.xref_id = x.xref_id"
          );
        }
        
        my $object_xrefs = $dbh->selectall_arrayref(
          "SELECT ox.ensembl_id, x.display_label, x.dbprimary_acc, ed.db_name, es.synonym, x.description
           FROM (object_xref AS ox, xref AS x, external_db AS ed) 
           LEFT JOIN external_synonym AS es ON es.xref_id = x.xref_id
           WHERE ox.ensembl_object_type = '$type' AND ox.xref_id = x.xref_id AND x.external_db_id = ed.external_db_id"
        );
        
        foreach (@$xrefs, @$object_xrefs) {
          $xrefs{$type}{ $_->[0] }{ $_->[3] }{ $_->[1] } = 1 if $_->[1];
          $xrefs{$type}{ $_->[0] }{ $_->[3] }{ $_->[2] } = 1 if $_->[2];
          ## remove the duplicates + Temp fix for metazoa data
          if (my $syn = $_->[4]) {
            $syn =~ s/^\'|\'$//g;
            next if ($syn =~ /^(FBtr|FBpp)\d+/);
            next if ($syn =~ /^CG\d+\-/);
            $xrefs{$type}{ $_->[0] }{ $_->[3] . "_synonym" }{ $syn } = 1;
          }
          ##
          $xrefs_desc{$type}{ $_->[0] }{ $_->[5] } = 1 if $_->[5];
        }
      }
    }
    
    print "Fetching exons...\n";
  
    my %exons = ();
    my $T = $dbh->selectall_arrayref(
      "SELECT DISTINCT t.gene_id, e.stable_id
       FROM transcript AS t, exon_transcript AS et, exon AS e
       WHERE t.transcript_id = et.transcript_id AND et.exon_id = e.exon_id"
    );
    
    foreach (@$T) {
      $exons{ $_->[0] }{ $_->[1] } = 1;
    }
  
    print "Fetching domains...\n";
  
    my %domains;
    $T = $dbh->selectall_arrayref(
      'SELECT DISTINCT g.gene_id, pf.hit_name 
       FROM gene g, transcript t, translation tl, protein_feature pf 
       WHERE g.gene_id = t.gene_id AND t.transcript_id = tl.transcript_id AND tl.translation_id = pf.translation_id'
    );

    foreach (@$T) {
      $domains{$_->[0]}{$_->[1]} = 1;
    }

    my %domain_count;
    $T = $dbh->selectall_arrayref(
      'SELECT DISTINCT g.gene_id, COUNT(pf.hit_name) 
       FROM gene g, transcript t, translation tl, protein_feature pf 
       WHERE g.gene_id = t.gene_id AND t.transcript_id = tl.transcript_id AND tl.translation_id = pf.translation_id
       GROUP BY g.gene_id'
    );

    foreach (@$T) {
      $domain_count{$_->[0]} = $_->[1];
    }

    unless($nodomaindescription) {
      my %domain_descriptions;
      $T = $dbh->selectall_arrayref(
        'SELECT DISTINCT g.gene_id, pf.hit_description
         FROM gene g, transcript t, translation tl, protein_feature pf 
         WHERE g.gene_id = t.gene_id AND t.transcript_id = tl.transcript_id AND tl.translation_id = pf.translation_id AND pf.hit_description IS NOT NULL'
      );
      foreach (@$T) {
        $domains{$_->[0]}{$_->[1]} = 1;
      }
    }
    
    print "Fetching seq regions...\n";
  
    my $species_to_seq_region = $dbh->selectall_hashref(
      "SELECT 
        meta.meta_value AS species_name, 
        coord_system.species_id, coord_system.coord_system_id, seq_region.seq_region_id,
        coord_system.name, seq_region.name AS seqname, 
        seq_region.length, attrib_type.name
       FROM meta, coord_system, seq_region, seq_region_attrib, attrib_type
       WHERE 
         coord_system.coord_system_id = seq_region.coord_system_id 
         AND seq_region_attrib.seq_region_id = seq_region.seq_region_id
         AND seq_region_attrib.attrib_type_id = attrib_type.attrib_type_id
         AND meta.species_id=coord_system.species_id 
         AND meta.meta_key = 'species.display_name' 
         AND attrib_type.name = 'Top Level'
       GROUP BY seq_region.seq_region_id  
       ORDER BY species_name, seqname, LENGTH DESC",
      [ 'species_name', 'seq_region_id' ]
    );
  
    #warn Dumper($species_to_seq_region);
  
    foreach my $species (keys %$species_to_seq_region) {
      my $counter = make_counter(0);
      my ($species_id)      = @{$dbh->selectrow_arrayref("SELECT DISTINCT(species_id) FROM meta WHERE meta_value = ? LIMIT 0,1", undef, $species)};
      my ($taxon_id)        = @{$dbh->selectrow_arrayref("SELECT meta_value FROM meta WHERE meta_key = 'species.taxonomy_id' AND species_id = ?", undef, $species_id)};
      my ($production_name) = @{$dbh->selectrow_arrayref("SELECT meta_value FROM meta WHERE meta_key = 'species.production_name' AND species_id = ?", undef, $species_id)};
      
      my $ortholog_lookup     = get_ortholog_lookup($conf, $production_name, $genomic_unit);
      my $ortholog_lookup_pan = get_ortholog_lookup($conf, $production_name, 'pan_homology');
      
      (my $filename = "Gene_${species}_${DB}") =~ s/[\W]/_/g;
      my $file = "$dir/$filename.xml";
      my $start_time = time;
    
      if ($skip_existing and -f $file) {
        warn "**** Index file already exists - skipping ****\n";
        next;
      }
    
      print "Dumping $species to $file\n";
      print "Start time " . format_datetime($start_time) . "\n";
      print "Num seq regions: " . (scalar keys %{ $species_to_seq_region->{$species} }) . "\n";
      
      open( FILE, ">$file" ) || die "Can't open $file: $!";
      
      header( $DBNAME, $dataset, $DB );
  
      # prepare the gene output sub
      # this is called when ready to ouput the gene line
      my $output_gene = sub() {
        my ($gene_data) = shift;
        my @transcript_stable_ids = keys %{ $gene_data->{transcript_stable_ids} };
        
        # add variation features
        if ($DB eq 'core' && $SNPDB) {
          $gene_data->{snps} = $dbh->selectall_arrayref(
        #    "SELECT DISTINCT(vf.variation_name) FROM $SNPDB.transcript_variation AS tv, $SNPDB.variation_feature AS vf
        #     WHERE vf.variation_feature_id = tv.variation_feature_id AND tv.feature_stable_id IN('" . join("', '", @transcript_stable_ids) . "')"
             "SELECT feature_stable_id, variation.name, variation_synonym.name AS synonym
              FROM $SNPDB.transcript_variation
              INNER JOIN $SNPDB.variation_feature USING (variation_feature_id)
              INNER JOIN $SNPDB.variation USING (variation_id)
              LEFT JOIN $SNPDB.variation_synonym USING (variation_id)
              WHERE feature_stable_id IN('" . join("', '", @transcript_stable_ids) . "')"         
          );
        }


        #use Data::Dumper;
        #warn Dumper($gene_data->{snps});
        my @all_snps;
        foreach my $snp_record(@{$gene_data->{snps}}){
          push @all_snps, $snp_record->[1] if defined($snp_record->[1]);
          push @all_snps, $snp_record->[2] if defined($snp_record->[2]);
        }
        $gene_data->{snps} = \@all_snps;
        #warn Dumper($gene_data->{snps});
        #exit;

 
        # add probes and probesets
        if ($FUNCGENDB) {
          $gene_data->{probes} = [];
          $gene_data->{probesets} = [];
          foreach (@transcript_stable_ids) { 
            push(@{$gene_data->{probes}},    @{$transcript_probes{$_}})    if $transcript_probes{$_};
            push(@{$gene_data->{probesets}}, @{$transcript_probesets{$_}}) if $transcript_probesets{$_};
          }
        }
        
        # add orthologs    
        
        $gene_data->{orthologs} = $ortholog_lookup_pan->{$gene_data->{gene_stable_id}};      # want all eg
        foreach my $orth ( @{ $ortholog_lookup->{$gene_data->{gene_stable_id}} || [] } ) {         
          if (!grep { $orth->[0] eq $_->[0] } @{ $gene_data->{orthologs} }) {                # want only unique ensembl
            push @{ $gene_data->{orthologs} }, $orth;
          }
        }      
        
 	      p geneLineXML( $species, $dataset, $gene_data, $counter );
      };
      
  
      #my $sr_count = 0;
      
      foreach my $seq_region_id ( keys %{ $species_to_seq_region->{$species} } ) {
        #print ++$sr_count . " ";
        #$|++;
              
        my $gene_sql = 
          "SELECT g.gene_id, t.transcript_id, tr.translation_id,
             g.stable_id AS gsid, t.stable_id AS tsid, tr.stable_id AS trsid,
             g.description, ed.db_display_name, x.dbprimary_acc,x.display_label AS xdlgene, 
             ad.display_label, ad.description, ad.web_data, g.source, g.status, g.biotype,
             sr.name AS seq_region_name, g.seq_region_start, g.seq_region_end
           FROM (gene AS g,
             analysis_description AS ad,
             transcript AS t) LEFT JOIN
             translation AS tr ON t.transcript_id = tr.transcript_id LEFT JOIN
             xref AS `x` ON g.display_xref_id = x.xref_id LEFT JOIN
             external_db AS ed ON ed.external_db_id = x.external_db_id LEFT JOIN
             seq_region AS sr ON sr.seq_region_id = g.seq_region_id
           WHERE t.gene_id = g.gene_id AND g.analysis_id = ad.analysis_id AND g.seq_region_id = ?
           ORDER BY g.stable_id, t.stable_id";
        
        #warn "$gene_sql  $seq_region_id\n";
        
        my $gene_info = $dbh->selectall_arrayref($gene_sql, undef, $seq_region_id);
        next unless @$gene_info;
      
        my %old;
      
        foreach my $row (@$gene_info) {
      
          my (
            $gene_id,                            $transcript_id,
            $translation_id,                     $gene_stable_id,
            $transcript_stable_id,               $translation_stable_id,
            $gene_description,                   $extdb_db_display_name,
            $xref_primary_acc,                   $xref_display_label,
            $analysis_description_display_label, $analysis_description, $web_data,
            $gene_source,                        $gene_status,
            $gene_biotype,                       $seq_region_name,
            $seq_region_start,                   $seq_region_end
          ) = @$row;
          
          if ($web_data) {
            $web_data = eval $web_data;
            if ( ref($web_data) eq 'HASH' ) {
              next if $web_data->{exclude_from_search};
            }
          }

          if ( $old{'gene_id'} != $gene_id ) {
            
            # output old gene if we have one
            $output_gene->(\%old) if $old{'gene_id'}; 
            
            # start building a new gene
            %old = (
              'gene_id'                => $gene_id,
              'haplotype'              => $haplotypes->{$gene_id} ? 'haplotype' : 'reference',
              'gene_stable_id'         => $gene_stable_id,
              'description'            => $gene_description,
              'taxon_id'               => $taxon_id,
              'translation_stable_ids' => { $translation_stable_id ? ( $translation_stable_id => 1 ) : () },
              'transcript_stable_ids'  => { $transcript_stable_id ? ( $transcript_stable_id => 1 ) : () },
              'transcript_ids'         => { $transcript_id ? ( $transcript_id => 1 ) : () },
              'exons'                  => {},
              'external_identifiers'   => {},
              'gene_name'              => $xref_display_label ? $xref_display_label : $gene_stable_id,
              'seq_region_name'        => $seq_region_name,
              'ana_desc_label'         => $analysis_description_display_label,
              'ad'                     => $analysis_description,
              'source'                 => ucfirst($gene_source),
              'st'                     => $gene_status,
              'biotype'                => $gene_biotype,
              'genomic_unit'           => $genomic_unit,
              'location'               => sprintf( '%s:%s-%s', $seq_region_name, $seq_region_start, $seq_region_end ),
              'exons'                  => $exons{$gene_id},
              'genetrees'              => $genetree_lookup->{$gene_stable_id} || [],
              'domains'                => $domains{$gene_id},
              'domain_count'           => $domain_count{$gene_id},
              'system_name'            => $production_name,
              'database'                => $DB,
            );
            
            $old{'source'} =~ s/base/Base/;
      
            # display name
            if (!$xref_display_label or $xref_display_label eq $gene_stable_id) {
              $old{'display_name'} = $gene_stable_id;
            } else {
              $old{'display_name'} = "$xref_display_label [$gene_stable_id]";
            }
      
            foreach my $K ( keys %{ $exons{$gene_id} } ) {
              $old{'i'}{$K} = 1;
            }
      
            foreach my $db ( keys %{ $xrefs{'Gene'}{$gene_id} || {} } ) {
              foreach my $K ( keys %{ $xrefs{'Gene'}{$gene_id}{$db} } ) {
                $old{'external_identifiers'}{$db}{$K} = 1;
              }
            }
            
            foreach my $db ( keys %{ $xrefs{'Transcript'}{$transcript_id} || {} } ) {
              foreach my $K ( keys %{ $xrefs{'Transcript'}{$transcript_id}{$db} } ) {
                $old{'external_identifiers'}{$db}{$K} = 1;
              }
            }
            
            foreach my $db ( keys %{ $xrefs{'Translation'}{$translation_id} || {} } ) {
              foreach my $K ( keys %{ $xrefs{'Translation'}{$translation_id}{$db} } ) {
                $old{'external_identifiers'}{$db}{$K} = 1;
              }
            } 

          } else {
          
            $old{'transcript_stable_ids'}{$transcript_stable_id}   = 1;
            $old{'transcript_ids'}{$transcript_id}                 = 1;
            $old{'translation_stable_ids'}{$translation_stable_id} = 1;
      
            foreach my $db ( keys %{ $xrefs{'Transcript'}{$transcript_id} || {} } ) {
              foreach my $K ( keys %{ $xrefs{'Transcript'}{$transcript_id}{$db} } ) {
                $old{'external_identifiers'}{$db}{$K} = 1;
              }
            }
            
            foreach my $db ( keys %{ $xrefs{'Translation'}{$translation_id} || {} } ) {
              foreach my $K ( keys %{ $xrefs{'Translation'}{$translation_id}{$db} } ) {
                $old{'external_identifiers'}{$db}{$K} = 1;
              }
            }
          }
        }
        $output_gene->(\%old) if $old{'gene_id'}; 
      }
      footer( $counter->() );
    }
      
    warn "FINISHED dumpGene ($DB)\n";
  } #$DB loop
}

sub geneLineXML {
  my ( $species, $dataset, $xml_data, $counter ) = @_;

  if (!$xml_data->{'gene_stable_id'}) {
    warn "gene id not set" ;
    return;
  }

  my $gene_id              = $xml_data->{'gene_stable_id'};
  my $genomic_unit         = $xml_data->{'genomic_unit'};
  my $location             = $xml_data->{'location'};
  my $transcripts          = $xml_data->{'transcript_stable_ids'} or die "transcripts not set";
  my $snps                 = $xml_data->{'snps'} || [];
  my $orthologs            = $xml_data->{'orthologs'};
  my $peptides             = $xml_data->{'translation_stable_ids'} or die "peptides not set";
  my $exons                = $xml_data->{'exons'} or die "exons not set";
  my $domains              = $xml_data->{'domains'};
  my $domain_descriptions  = $xml_data->{'domain_descriptions'};
  my $external_identifiers = $xml_data->{'external_identifiers'} or die "external_identifiers not set";
  my $description          = $xml_data->{'description'};
  my $gene_name            = encode_entities($xml_data->{'gene_name'});
  my $seq_region_name      = $xml_data->{'seq_region_name'};
  my $type                 = $xml_data->{'source'} . ' ' . $xml_data->{'biotype'} or die "problem setting type";
  my $haplotype            = $xml_data->{'haplotype'};
  my $taxon_id             = $xml_data->{'taxon_id'};
  my $exon_count           = scalar keys %$exons;
  my $domain_count         = $xml_data->{'domain_count'};
  my $transcript_count     = scalar keys %$transcripts;
  my $display_name         = $xml_data->{'display_name'};
  my $genetrees            = $xml_data->{'genetrees'};
  my $probes               = $xml_data->{'probes'};
  my $probesets            = $xml_data->{'probesets'};
  my $system_name          = $xml_data->{'system_name'};
  my $database             = $xml_data->{'database'};

  $display_name =~ s/</&lt;/g;
  $display_name =~ s/>/&gt;/g;

  $description =~ s/</&lt;/g;
  $description =~ s/>/&gt;/g;
  $description =~ s/'/&apos;/g;
  $description =~ s/&/&amp;/g;

  $gene_name =~ s/</&lt;/g;
  $gene_name =~ s/>/&gt;/g;
  $gene_name =~ s/'/&apos;/g;
  $gene_name =~ s/&/&amp;/g;

  $gene_id =~ s/</&lt;/g;
  $gene_id =~ s/>/&gt;/g;

  my $xml = qq{
<entry id="$gene_id">
<name>$display_name</name>
<description>$description</description>};

  my $synonyms = "";
  my $unique_synonyms;
  my $cross_references = qq{
<cross_references>
<ref dbname="ncbi_taxonomy_id" dbkey="$taxon_id"/>};

  # for some types of xref, merge the subtypes into the larger type
  # e.g. Uniprot/SWISSPROT and Uniprot/TREMBL become just Uniprot
  # synonyms are stored as additional fields rather than cross references
  foreach my $ext_db_name ( keys %$external_identifiers ) {

    if ( $ext_db_name =~ /(Uniprot|GOA|GO|Interpro|Medline|Sequence_Publications|EMBL)/ ) {
      my $matched_db_name = $1;
      
      # synonyms
      if ( $ext_db_name =~ /_synonym/ ) {
        foreach my $ed_key ( keys %{ $external_identifiers->{$ext_db_name} } ) {
          #   $unique_synonyms->{$ed_key} = 1;
          my $encoded = encode_entities($ed_key);
          $synonyms .= qq{
<field name="${matched_db_name}_synonym">$encoded</field>};
        }
      }
      else {    # non-synonyms
        map { $cross_references .= qq{
<ref dbname="$matched_db_name" dbkey="$_"/>};
        } keys %{ $external_identifiers->{$ext_db_name} }
      }
    
    } else {
    
      foreach my $key ( keys %{ $external_identifiers->{$ext_db_name} } ) {
        $key = encode_entities($key);
        $ext_db_name =~ s/^Ens.*/ENSEMBL/;

        if ( $ext_db_name =~ /_synonym/ ) {
          $unique_synonyms->{$key} = 1;
          $synonyms .= qq{
<field name="$ext_db_name">$key</field>};
        }
        else {
          $cross_references .= qq{
<ref dbname="$ext_db_name" dbkey="$key"/>};
        }
      }
    }
  }

  $cross_references .= ( join "", ( map { qq{
<ref dbname="ensemblvariation" dbkey="$_"/>}
  } @$snps));

  $cross_references .= ( join "", ( map { qq{
<ref dbname="$_->[1]" dbkey="$_->[0]"/>}
  } @$orthologs ) );
  
  $cross_references .= qq{
</cross_references>};

  map { $synonyms .= qq{
<field name="gene_synonym">} . encode_entities($_) . qq{</field> }
  } keys %$unique_synonyms;

  my $additional_fields .= qq{
<additional_fields>
<field name="species">$species</field>
<field name="system_name">$system_name</field>
<field name="featuretype">Gene</field>
<field name="source">$type</field>
<field name="location">$location</field>
<field name="transcript_count">$transcript_count</field>
<field name="gene_name">$gene_name</field>
<field name="seq_region_name">$seq_region_name</field>
<field name="haplotype">$haplotype</field>}
    . ($dataset ne $species ? qq{
<field name="collection">$dataset</field>} : '')
    . ($genomic_unit ? qq{
<field name="genomic_unit">$genomic_unit</field>} : '') 
    . ( join "", ( map { qq{
<field name="transcript">$_</field>}
      } map {encode_entities($_)} keys %$transcripts ) )
    . qq{  
<field name="exon_count">$exon_count</field> }
    . ( join "", ( map { qq{
<field name="exon">$_</field>}
      } map {encode_entities($_)} keys %$exons ) ) 
    . qq{  
<field name="domain_count">$domain_count</field> }
    . ( join "", ( map { qq{
<field name="domain">$_</field>}
      } map {encode_entities($_)} keys %$domains ) )
    . ( join "", ( map { qq{
<field name="peptide">$_</field>}
      } map {encode_entities($_)} keys %$peptides ) )
    . ( join "", ( map { qq{
<field name="genetree">$_</field>}
      } map {encode_entities($_)} @$genetrees ) )
    . ( join "", ( map { qq{
<field name="probe">$_</field>}
      } map {encode_entities($_)} @$probes ) )  
    . ( join "", ( map { qq{
<field name="probeset">$_</field>}
      } map {encode_entities($_)} @$probesets ) )  
    . ( join "", ( map { qq{
<field name="gene_synonym">$_</field>}
      } map {encode_entities($_)} keys %$unique_synonyms ) )  
    . qq{
<field name="database">$database</field>      
</additional_fields>};

  $counter->();
  return $xml . $cross_references . $additional_fields . "\n</entry>";
}


sub geneLineTSV {
  my ( $species, $dataset, $xml_data, $counter ) = @_;


  my $external_identifiers = $xml_data->{'external_identifiers'} or die "external_identifiers not set";
  my $gene_id = $xml_data->{'gene_stable_id'} or die "gen id not set";
  $gene_id =~ s/</&lt;/g;
  $gene_id =~ s/>/&gt;/g;


  my $description          = $xml_data->{'description'};
  my $gene_name            = encode_entities($xml_data->{'gene_name'});
  my $display_name         = $xml_data->{'display_name'};

  $display_name =~ s/</&lt;/g;
  $display_name =~ s/>/&gt;/g;

  $description =~ s/</&lt;/g;
  $description =~ s/>/&gt;/g;
  $description =~ s/'/&apos;/g;
  $description =~ s/&/&amp;/g;

  $gene_name =~ s/</&lt;/g;
  $gene_name =~ s/>/&gt;/g;
  $gene_name =~ s/'/&apos;/g;
  $gene_name =~ s/&/&amp;/g;


  my $xrefs;
  # for some types of xref, merge the subtypes into the larger type
  # e.g. Uniprot/SWISSPROT and Uniprot/TREMBL become just Uniprot
  # synonyms are stored as additional fields rather than cross references
  foreach my $ext_db_name ( keys %$external_identifiers ) {
      my $matched_db_name = $ext_db_name;
      if ( $ext_db_name =~ /(Uniprot|GOA|GO|Interpro|Medline|Sequence_Publications|EMBL)/ ) {
	  $matched_db_name = $1;
	  @{$xrefs->{$matched_db_name}} = map { encode_entities($_) } keys %{ $external_identifiers->{$ext_db_name} };
      }
  }
  my $xrefs_str = join ';', map { join ',', @{$xrefs->{$_}||[]} } keys %$xrefs;
  
  my $url = sprintf qq{http://%s.ensembl.org/%s/Gene/Summary?g=%s;r=%s}, $xml_data->{'genomic_unit'}, $xml_data->{'system_name'}, $xml_data->{gene_stable_id}, $xml_data->{'location'};
  my @fields;
  push @fields, $gene_id, $xml_data->{'biotype'}, $gene_name, $xrefs_str, $url, $description;
  $counter->();
  return join "\t", @fields;
}


sub make_counter {
  my $start = shift;
  return sub { $start++ }
}

#------------------------------------------------------------------------------
#
# Build a gene tree id lookup
# It's slow, but common to all species, so we only have to do it once
#

my $_genetree_lookup;

sub get_genetree_lookup {
  my ($genomic_unit, $conf) = @_;

  unless ($_genetree_lookup) {
       
    print "Building gene tree id lookup...\n";

    foreach my $dbtype ($genomic_unit, 'pan_homology') {
      
      my $dbname = $conf->{compara}->{$dbtype}->{$release};
      next unless $dbname;
      
      print "  $dbname\n";

      my $compara_dbh = connect_db($dbname);

      my $sql =
        "SELECT gm.stable_id AS gene, gtr.stable_id AS genetree
         FROM seq_member sm
         JOIN gene_tree_node gtn USING(seq_member_id)
         JOIN gene_tree_root gtr USING(root_id)
         JOIN gene_member gm USING(gene_member_id)
         WHERE gtr.stable_id IS NOT NULL
         ORDER BY gm.stable_id";

      #warn "$sql\n";

      my $rows = $compara_dbh->selectall_arrayref($sql);

      foreach (@$rows) {
        $_genetree_lookup->{$_->[0]} ||= [];
        push(@{$_genetree_lookup->{$_->[0]}}, $_->[1]);
      }

      $compara_dbh->disconnect;
    }
  }

  return $_genetree_lookup;
}

#------------------------------------------------------------------------------
#
# Build an ortholog lookup for given species/compara-db
#

sub get_ortholog_lookup {
  my ($conf, $species, $compara_db) = @_;

  return {} if ($noortholog);

  my $prefix = $compara_db eq 'pan_homology' ? 'ensemblgenomes' : 'ensembl';
  
  my $orth_species = {
    'homo_sapiens'                            => "ensembl_ortholog",
    'mus_musculus'                            => "ensembl_ortholog",
    'drosophila_melanogaster'                 => "${prefix}_ortholog",
    'caenorhabditis_elegans'                  => "${prefix}_ortholog",
    'saccharomyces_cerevisiae'                => "${prefix}_ortholog",
    'arabidopsis_thaliana'                    => "${prefix}_ortholog",
    'escherichia_coli_str_k_12_substr_mg1655' => "${prefix}_ortholog",
    'schizosaccharomyces_pombe' => "${prefix}_ortholog",
    'bacillus_subtilis_subsp_subtilis_str_168' => "${prefix}_ortholog",
  };
  
  return {} unless delete $orth_species->{$species};                         # do we want orthologs for this species?
  return {} unless my $dbname = $conf->{compara}->{$compara_db}->{$release}; # have we got a compara db?

  print "Building ortholog lookup for $species (compara_$compara_db)...\n";
  
  my $compara_dbh = connect_db($dbname);

  my $orth_species_string = join('","', keys %$orth_species);

  my $orthologs_sth = $compara_dbh->prepare(qq{
    SELECT
      m1.stable_id , m2.stable_id, gdb2.name
    FROM 
      genome_db gdb1  JOIN gene_member m1 USING (genome_db_id)
      JOIN homology_member hm1 USING (gene_member_id)
      JOIN homology h USING (homology_id)
      JOIN homology_member hm2 USING (homology_id)
      JOIN gene_member m2 ON (hm2.gene_member_id = m2.gene_member_id)
      JOIN genome_db gdb2 ON (m2.genome_db_id = gdb2.genome_db_id)
    WHERE
      gdb1.name = "$species" 
      AND m2.source_name = "ENSEMBLGENE"
      AND gdb2.name IN ("$orth_species_string")
      AND h.description in ("ortholog_one2one", "apparent_ortholog_one2one",
      "ortholog_one2many", "ortholog_many2many")
  });
  $orthologs_sth->execute;
  
  # process rows in batches
  my $lookup = {};
  my $rows = [];
  while ( my $row = ( shift(@$rows) || shift( @{ $rows = $orthologs_sth->fetchall_arrayref( undef, 10_000 ) || [] } ) ) ) {
    push @{ $lookup->{$row->[0]} }, [ $row->[1], $orth_species->{$row->[2]} ];
  }    
  
  return $lookup;
}

