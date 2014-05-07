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

package EnsEMBL::Web::Object::UserData;
                                                                                 
use strict;

use EnsEMBL::Web::Document::Table;

sub consequence_table {
  my ($self, $consequence_data) = @_;
  my $hub     = $self->hub;
  my $species = $hub->param('species') || $hub->species;
  my $code    = $hub->param('code');

  my %popups = (
    'var'       => 'What you input (chromosome, nucleotide position, alleles)',
    'location'  => 'Chromosome and nucleotide position in standard coordinate format (chr:nucleotide position or chr:start-end)',
    'allele'    => 'The variant allele used to calculate the consequence',
    'gene'      => 'Ensembl stable ID of the affected gene (e.g. ENSG00000187634)',
    'trans'     => 'Ensembl stable ID of the affected feature (e.g. ENST00000474461)',
    'ftype'     => 'Type of feature (i.e. Transcript, RegulatoryFeature or MotifFeature)',
    'con'       => 'Consequence type of this variant',
    'cdna_pos'  => 'Nucleotide (base pair) position in the cDNA sequence',
    'cds_pos'   => 'Nucleotide (base pair) position in the coding sequence',
    'prot_pos'  => 'Amino acid position in the protein sequence',
    'aa'        => 'All possible amino acids at the position.  This is only given if the variant affects the protein-coding sequence',
    'codons'    => 'All alternative codons at the position.  The position of the variant is highlighted as bold (HTML version) or upper case (text version)',
    'snp'       => 'Known identifiers of variants at that position',
    'extra'     => 'More information',
  );

  my $columns = [
    { key => 'var',      title =>'Uploaded Variation',   help => $popups{'var'}, align => 'center', sort => 'string'        },
    { key => 'location', title =>'Location',             help => $popups{'location'}, align => 'center', sort => 'position_html' },
    { key => 'allele',   title =>'Allele',               help => $popups{'allele'}, align => 'center', sort => 'string'        },
    { key => 'gene',     title =>'Gene',                 help => $popups{'gene'}, align => 'center', sort => 'html'          },
    { key => 'trans',    title =>'Feature',              help => $popups{'trans'}, align => 'center', sort => 'html'          },
    { key => 'ftype',    title =>'Feature type',         help => $popups{'ftype'}, align => 'center', sort => 'html'          },
    { key => 'con',      title =>'Consequence',          help => $popups{'con'}, align => 'center', sort => 'string'        },
    { key => 'cdna_pos', title =>'Position in cDNA',     help => $popups{'cdna_pos'}, align => 'center', sort => 'position'      },
    { key => 'cds_pos',  title =>'Position in CDS',      help => $popups{'cds_pos'}, align => 'center', sort => 'position'      },
    { key => 'prot_pos', title =>'Position in protein',  help => $popups{'prot_pos'}, align => 'center', sort => 'position'      },
    { key => 'aa',       title =>'Amino acid change',    help => $popups{'aa'}, align => 'center', sort => 'none'          },
    { key => 'codons',   title =>'Codon change',         help => $popups{'codons'}, align => 'center', sort => 'none'          },
    { key => 'snp',      title =>'Co-located Variation', help => $popups{'snp'}, align => 'center', sort => 'html'          },
    { key => 'extra',    title =>'Extra',                help => $popups{'extra'}, align => 'left',   sort => 'html'          },
  ];

  my @rows;

  foreach my $feature_set (keys %$consequence_data) {
    foreach my $f (@{$consequence_data->{$feature_set}}) {
      next if $f->id =~ /^Uploaded/;
      
      my $row               = {};
      my $location          = $f->location;
      my $allele            = $f->allele;
      my $url_location      = $f->seqname . ':' . ($f->rawstart - 500) . '-' . ($f->rawend + 500);
      my $uploaded_loc      = $f->id;
      my $feature_id        = $f->feature;
      my $feature_type      = $f->feature_type;
      my $gene_id           = $f->gene;
      my $consequence       = $f->consequence;
      my $cdna_pos          = $f->cdna_position;
      my $cds_pos           = $f->cds_position;
      my $prot_pos          = $f->protein_position;
      my $aa                = $f->aa_change;
      my $codons            = $f->codons;
      my $extra             = $f->extra_col;
      my $snp_id            = $f->snp;
      my $feature_string    = $feature_id;
      my $gene_string       = $gene_id;
      my $snp_string        = $snp_id;
      
      
## EG - ENSEMBL-3117: for EG we cannot map stable id to db type so assume it is core
      # guess core type from feature ID
      #my $core_type = 'otherfeatures' unless $feature_id =~ /^ENS/ and $feature_id !~ /^ENSEST/;
      my $core_type = 'core';
##

      my $location_url = $hub->url({
        species          => $species,
        type             => 'Location',
        action           => 'View',
        r                =>  $url_location,
        contigviewbottom => "variation_feature_variation=normal,upload_$code=normal",
      });
      
      # transcript
      if ($feature_type eq 'Transcript') {
        my $feature_url = $hub->url({
          species => $species,
          type    => 'Transcript',
          action  => 'Summary',
          db      => $core_type,
          t       => $feature_id,
        });
        
        $feature_string = qq{<a href="$feature_url" rel="external">$feature_id</a>};
      }
      # reg feat
      elsif ($feature_id =~ /^ENS.{0,3}R/) {
        my $feature_url = $hub->url({
          species => $species,
          type    => 'Regulation',
          action  => 'Cell_line',
          rf      => $feature_id,
        });
        
        $feature_string = qq{<a href="$feature_url" rel="external">$feature_id</a>};
      }
      # gene
      elsif ($feature_id =~ /^ENS.{0,3}G/) {
        my $feature_url = $hub->url({
          species => $species,
          type    => 'Gene',
          action  => 'Summary',
          rf      => $feature_id,
        });
        
        $feature_string = qq{<a href="$feature_url" rel="external">$feature_id</a>};
      }
      else {
        $feature_string = $feature_id;
      }

      if ($gene_id ne '-') {
        my $gene_url = $hub->url({
          species => $species,
          type    => 'Gene',
          action  => 'Summary',
          db      => $core_type,
          g       => $gene_id,
        });
        
        $gene_string = qq{<a href="$gene_url" rel="external">$gene_id</a>};
      }
      
      
      $snp_string = '';
      
      if ($snp_id =~ /^\w/){
        
        foreach my $s(split /\,/, $snp_id) {
          my $snp_url =  $hub->url({
            species => $species,
            type    => 'Variation',
            action  => 'Explore',
            v       =>  $s,
          });
          
          $snp_string .= qq{<a href="$snp_url" rel="external">$s</a>,};
        }
        
        $snp_string =~ s/\,$//g;
      }
      
      $snp_string ||= '-';
      
      $consequence =~ s/\,/\,\<br\/>/g;
      
      # format extra string nicely
      $extra = join ";", map {$self->render_sift_polyphen($_); s/(\w+?=)/<b>$1<\/b>/g; $_ } split /\;/, $extra;
      $extra =~ s/;/;<br\/>/g; 
      
      $extra =~ s/(ENSP\d+)/'<a href="'.$hub->url({
        species => $species,
        type    => 'Transcript',
        action  => 'ProteinSummary',
        t       =>  $feature_id,
      }).'" rel="external">'.$1.'<\/a>'/e;
      
      #$consequence = qq{<span class="hidden">$ranks{$consequence}</span>$consequence};

      $row->{'var'}      = $uploaded_loc;
      $row->{'location'} = qq{<a href="$location_url" rel="external">$location</a>};
      $row->{'allele'}   = $allele;
      $row->{'gene'}     = $gene_string;
      $row->{'trans'}    = $feature_string;
      $row->{'ftype'}    = $feature_type;
      $row->{'con'}      = $consequence;
      $row->{'cdna_pos'} = $cdna_pos;
      $row->{'cds_pos'}  = $cds_pos;
      $row->{'prot_pos'} = $prot_pos;
      $row->{'aa'}       = $aa;
      $row->{'codons'}   = $codons;
      $row->{'extra'}    = $extra || '-';
      $row->{'snp'}      = $snp_string;

      push @rows, $row;
    }
  }
  
  return EnsEMBL::Web::Document::Table->new($columns, [ sort { $a->{'var'} cmp $b->{'var'} } @rows ], { data_table => '1' });
}

1;
