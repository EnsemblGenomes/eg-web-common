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

package EG::Common::SiteDefs;
use strict;

use Data::Dumper;

sub update_conf {
  map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;

  $SiteDefs::ENSEMBL_COHORT = 'EnsemblGenomes';
  
  $SiteDefs::SITE_RELEASE_VERSION = 57;
  $SiteDefs::SITE_RELEASE_DATE    = 'May 2023';
  $SiteDefs::SITE_MISSION         = 'Ensembl Genomes provides integrated access to genome-scale data from invertebrate metazoa, plants, fungi, protists and bacteria in partnership with the scientifc communities that work in each domain.';
  $SiteDefs::BIOSCHEMAS_DATACATALOG = defer { 'http://'.$SiteDefs::DIVISION.'.ensembl.org/#project' };
    
  $SiteDefs::SPECIES_IMAGE_DIR          = defer { sprintf '%s/eg-web-%s/%s', 
                                                $SiteDefs::ENSEMBL_SERVERROOT,
                                                $SiteDefs::DIVISION,
                                                $SiteDefs::DEFAULT_SPECIES_IMG_DIR };

  push @$SiteDefs::ENSEMBL_API_LIBS, $SiteDefs::ENSEMBL_SERVERROOT . '/ensembl-metadata/modules';
  push @$SiteDefs::ENSEMBL_API_LIBS, $SiteDefs::ENSEMBL_SERVERROOT . '/ensembl-taxonomy/modules';
  
  $SiteDefs::PERL_RLIMIT_AS = '8192:16384';

  $SiteDefs::ENSEMBL_MIN_SPARE_SERVERS =  5;
  $SiteDefs::ENSEMBL_MAX_SPARE_SERVERS = 20;
  $SiteDefs::ENSEMBL_MAX_PROCESS_SIZE = 850000; # Kill httpd over 850000KB

  # Does this site have a large species set?
  # (used by the interface to determine whether to use dropdown or auto-comeplete etc)
  $SiteDefs::LARGE_SPECIES_SET = 0;

  ## Allow wiggle tracks to be drawn on whole chromosomes for small genomes
  $SiteDefs::MAX_DRAWING_LENGTH = 1000000;

  # Static content flags
  $SiteDefs::HAS_ANNOTATION             = 1;
  $SiteDefs::HAS_TUTORIALS              = 1;
  $SiteDefs::HAS_API_DOCS               = 1;

  # disable sprite maps - not used for EG
  $SiteDefs::ENSEMBL_DEBUG_IMAGES = 1;
  
  $SiteDefs::GENE_FAMILY_ACTION = 'Gene_families'; # Used to build the link to gene families page
  $SiteDefs::FAMILY_ALIGNMENTS_DOWNLOADABLE   = 0; # Sequence alignments are not available for non-vertebrates

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

  # EG doesn't use file chameleon
  $SiteDefs::ENSEMBL_FC_ENABLED = 0;

  ## Show docs about annotation
  $SiteDefs::HAS_ANNOTATION = 1;
 
  # EG doesn't use VCF2PED
  $SiteDefs::ENSEMBL_VP_ENABLED = 0;

  #----------------------------------------------------------------------------
  # EXTERNAL
  #----------------------------------------------------------------------------

  # REST endpoints
  $SiteDefs::NCBIBLAST_REST_ENDPOINT = 'http://www.ebi.ac.uk/Tools/services/rest/ncbiblast';
  $SiteDefs::EBEYE_REST_ENDPOINT     = 'https://www.ebi.ac.uk/ebisearch/ws/rest';

  # EG rest server
  $SiteDefs::ENSEMBL_REST_DOC_URL = '/info/data/rest.html';
  $SiteDefs::Pathway              = 1; #enabling pathway widget

}


1;

