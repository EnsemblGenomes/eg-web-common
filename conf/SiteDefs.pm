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

  $SiteDefs::ENSEMBL_COHORT = 'EnsemblGenomes';
  
  $SiteDefs::SITE_RELEASE_VERSION = 35;
  $SiteDefs::SITE_RELEASE_DATE    = 'March 2017';
  $SiteDefs::SITE_MISSION         = 'Ensembl Genomes provides integrated access to genome-scale data from invertebrate metazoa, plants, fungi, protists and bacteria in partnership with the scientifc communities that work in each domain.';
    
  @SiteDefs::ENSEMBL_PERL_DIRS    = (
    $SiteDefs::ENSEMBL_WEBROOT.'/perl',
    $SiteDefs::ENSEMBL_SERVERROOT.'/eg-web-common/perl',
  );

  push (@SiteDefs::ENSEMBL_LIB_DIRS, 
    $SiteDefs::ENSEMBL_SERVERROOT . '/ensemblgenomes-api/modules',
    '/nfs/public/rw/ensembl/bioperl-1.6.1'
  );

  $SiteDefs::APACHE_BIN    = '/usr/sbin/httpd';
  $SiteDefs::APACHE_DIR    = '/etc/httpd';
  $SiteDefs::SAMTOOLS_DIR  = '/nfs/public/rw/ensembl/samtools';

  # Does this site have a large species set?
  # (used by the interface to determine whether to use dropdown or auto-comeplete etc)
  $SiteDefs::LARGE_SPECIES_SET = 0;
  
  #---------------------------------------------------------------------------- 
  # TOOLS
  #----------------------------------------------------------------------------

  # Database key name for tools db as defined in MULTI.ini
  $SiteDefs::ENSEMBL_ORM_DATABASES->{'ticket'} = 'DATABASE_WEB_TOOLS';

  # use NcbiBlast dispatcher
  $SiteDefs::ENSEMBL_TOOLS_JOB_DISPATCHER->{Blast} = 'NcbiBlast';

  # if enabled, the BLAST form will try to look sequences up from external dbs
  # best to diable for EG
  $SiteDefs::ENSEMBL_BLAST_BY_SEQID = 0;

  # Flag to enable/disable BLAST, VEP, Assembly Converter
  $SiteDefs::ENSEMBL_BLAST_ENABLED  = 1;
  $SiteDefs::ENSEMBL_VEP_ENABLED    = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED   = 0;
  $SiteDefs::ENSEMBL_AC_ENABLED     = 0;
  $SiteDefs::ENSEMBL_HMMER_ENABLED  = 0;
  $SiteDefs::ENSEMBL_FC_ENABLED     = 0;

  #----------------------------------------------------------------------------
  # EXTERNAL
  #----------------------------------------------------------------------------

  # REST endpoints
  $SiteDefs::NCBIBLAST_REST_ENDPOINT = 'http://www.ebi.ac.uk/Tools/services/rest/ncbiblast';
  $SiteDefs::EBEYE_REST_ENDPOINT     = 'http://www.ebi.ac.uk/ebisearch/ws/rest';

  # EG rest server
  $SiteDefs::ENSEMBL_REST_DOC_URL = 'http://ensemblgenomes.org/info/access/rest';
}


1;

