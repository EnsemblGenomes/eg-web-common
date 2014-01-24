package EG::Common::SiteDefs;
use strict;

use Data::Dumper;

sub update_conf {
  map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;
  
  $SiteDefs::SITE_RELEASE_VERSION = 21;
  $SiteDefs::SITE_RELEASE_DATE = 'December 2013';
  
  $SiteDefs::SITE_MISSION = 'Ensembl Genomes provides integrated access to genome-scale data from invertebrate metazoa, plants, fungi, protists and bacteria in partnership with the scientifc communities that work in each domain.';
  
  $SiteDefs::ENSEMBL_LONGPROCESS_MINTIME    = 10;
  
  @SiteDefs::ENSEMBL_PERL_DIRS    = (
    $SiteDefs::ENSEMBL_SERVERROOT.'/perl',
    $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/eg/common/perl',
  );
  
  $SiteDefs::TEMPLATE_ROOT = $SiteDefs::ENSEMBL_SERVERROOT.'/public-plugins/eg/common/templates';
      
  $SiteDefs::DOCSEARCH_INDEX_DIR = $SiteDefs::ENSEMBL_TMP_DIR . '/docsearch_index';
  
  $SiteDefs::OBJECT_TO_SCRIPT->{'Info'} = 'AltPage';
  
  $SiteDefs::ENSEMBL_BLASTSCRIPT       = $SiteDefs::ENSEMBL_SERVERROOT."/utils/parse_blast.pl";
  $SiteDefs::ENSEMBL_BLAST_ENABLED     = 1;   
  $SiteDefs::ENSEMBL_ENASEARCH_ENABLED = 1;
  $SiteDefs::ENSEMBL_LOGINS            = 1;
  
  $SiteDefs::APACHE_BIN   = '/usr/sbin/httpd';
  $SiteDefs::APACHE_DIR   = '/etc/httpd';
  $SiteDefs::SAMTOOLS_DIR = '/nfs/public/rw/ensembl/samtools';
  
  $SiteDefs::ENSEMBL_USERDB_HOST = 'localhost';
  $SiteDefs::ENSEMBL_USERDB_PORT = 3306;
  $SiteDefs::ENSEMBL_USERDB_USER = 'ensrw';
  $SiteDefs::ENSEMBL_USERDB_PASS = 'ensrw';
  $SiteDefs::ENSEMBL_USERDB_NAME = 'ensembl_accounts';

  $SiteDefs::ROSE_DB_DATABASES->{'user'}   = {
    database  => $SiteDefs::ENSEMBL_USERDB_NAME,
    host      => $SiteDefs::ENSEMBL_USERDB_HOST,
    port      => $SiteDefs::ENSEMBL_USERDB_PORT,
    username  => $SiteDefs::ENSEMBL_USERDB_USER || $SiteDefs::DATABASE_WRITE_USER,
    password  => $SiteDefs::ENSEMBL_USERDB_PASS || $SiteDefs::DATABASE_WRITE_PASS,
  };
}

1;

