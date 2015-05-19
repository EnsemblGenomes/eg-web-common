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

package EG::Common::SiteDefs;
use strict;

use Data::Dumper;

sub update_conf {
  map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;
  
  $SiteDefs::SITE_RELEASE_VERSION = 27;
  $SiteDefs::SITE_RELEASE_DATE = 'May 2015';
  
  $SiteDefs::SITE_MISSION = 'Ensembl Genomes provides integrated access to genome-scale data from invertebrate metazoa, plants, fungi, protists and bacteria in partnership with the scientifc communities that work in each domain.';
  
  $SiteDefs::ENSEMBL_LONGPROCESS_MINTIME    = 10;
  
  @SiteDefs::ENSEMBL_PERL_DIRS    = (
    $SiteDefs::ENSEMBL_WEBROOT.'/perl',
    $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/perl',
  );

  push (@SiteDefs::ENSEMBL_LIB_DIRS, 
    $SiteDefs::ENSEMBL_SERVERROOT . '/ensemblgenomes-api/modules'
  );
  
  $SiteDefs::TEMPLATE_ROOT = $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/templates';
      
  $SiteDefs::DOCSEARCH_INDEX_DIR = $SiteDefs::ENSEMBL_TMP_DIR . '/docsearch_index';
  
  $SiteDefs::OBJECT_TO_SCRIPT->{'Info'} = 'AltPage';
  
  $SiteDefs::ENSEMBL_BLASTSCRIPT       = $SiteDefs::ENSEMBL_SERVERROOT."/utils/parse_blast.pl";
  $SiteDefs::ENSEMBL_LOGINS            = 1;
  $SiteDefs::ENSEMBL_BLAST_BY_SEQID    = 0;
  
  $SiteDefs::APACHE_BIN    = '/usr/sbin/httpd';
  $SiteDefs::APACHE_DIR    = '/etc/httpd';
  $SiteDefs::SAMTOOLS_DIR  = '/nfs/public/rw/ensembl/samtools';
  
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

  # TOOLS

  # Database key name for tools db as defined in MULTI.ini
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'ticket'} = 'DATABASE_WEB_TOOLS';

  # Which dispatcher to be used for the jobs (provide the appropriate values in your plugins)
  #$SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER = { 'Blast' => 'WuBlast' };
  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER = { 'Blast' => 'NcbiBlast' };

  # Flag to enable/disable BLAST, VEP, Assembly Converter
  $SiteDefs::ENSEMBL_BLAST_ENABLED  = 1;
  $SiteDefs::ENSEMBL_VEP_ENABLED    = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED   = 0;
  $SiteDefs::ENSEMBL_AC_ENABLED     = 0;

  #$SiteDefs::WUBLAST_REST_ENDPOINT  = 'http://www.ebi.ac.uk/Tools/services/rest/wublast';
  #$SiteDefs::NCBIBLAST_REST_ENDPOINT = 'http://www.ebi.ac.uk/Tools/services/rest/ncbiblast';
  $SiteDefs::NCBIBLAST_REST_ENDPOINT = 'http://wwwdev.ebi.ac.uk/Tools/services/rest/ncbiblast';

  $SiteDefs::EBEYE_REST_ENDPOINT     = 'http://www.ebi.ac.uk/ebisearch/ws/rest';

  $SiteDefs::ENSEMBL_REST_URL     = 'http://rest.ensemblgenomes.org';
  $SiteDefs::ENSEMBL_REST_DOC_URL = 'http://ensemblgenomes.org/info/access/rest';

  $SiteDefs::LARGE_SPECIES_SET = 0;
}


1;

