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

package EnsEMBL::Web::Component::Variation::Summary;

use strict;

sub content {
  my $self               = shift;
  my $hub                = $self->hub;
  my $object             = $self->object;
  my $variation          = $object->Obj;
  my $vf                 = $hub->param('vf');
  my $var_id             = $hub->param('v');
  my $variation_features = $variation->get_all_VariationFeatures;
  my ($feature_slice)    = map { $_->dbID == $vf ? $_->feature_Slice : () } @$variation_features; # get slice for variation feature
  my $avail              = $object->availability;  

  my ($info_box);
  if ($variation->failed_description || (scalar keys %{$object->variation_feature_mapping} > 1)) { 
    ## warn if variation has been failed
    $info_box = $self->multiple_locations($feature_slice, $variation->failed_description); 
  }
  
  my @str_array = $self->feature_summary($avail);
  
  my $summary_table = $self->new_twocol(    
    $self->most_severe_consequence($variation_features),
    $self->alleles($feature_slice),
    $self->location,
    $feature_slice ? $self->co_located($feature_slice) : (),
    $self->evidence_status,
    $self->clinical_significance,
    $self->hgvs,
    $self->object->vari_class eq 'SNP' ? () : $self->three_prime_co_located(),
    $self->synonyms,
## EG
    $self->inter_homoeologues,
##    
    $self->sets,
    $self->variation_source,
    @str_array ? ['About this variant', sprintf('This variant %s.', $self->join_with_and(@str_array))] : (),
    ($hub->species eq 'Homo_sapiens' && $hub->snpedia_status) ? $var_id && $self->snpedia($var_id) : ()
  );

  return sprintf qq{<div class="summary_panel">$info_box%s</div>}, $summary_table->render;
}


## EG ENSEMBL-3426 link to inter-homoeologues
sub inter_homoeologues {
  my $self           = shift;
  my $hub            = $self->hub;
  my $attribs        = $self->object->Obj->get_all_attributes();
  my @rows;

  foreach my $caption (keys %$attribs) {
    my $id      = $attribs->{$caption};
    my $url     = $hub->url({ v => $id, __clear => 1 });
    push @rows, [ucfirst($caption), sprintf('<a href="%s">%s</a> %s', $url, $id)];
  } 

  return @rows ;
}
##

sub variation_source {
  my $self    = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $name    = $object->name;
  my $source  = $object->source;
  my $version = $object->source_version;
  my $url     = $object->source_url;
  my ($source_link, $sname);
  
  # Date version
  if ($version =~ /^(20\d{2})(\d{2})/) {
    $version = "$2/$1";
  }
  
  ## parse description for links
  (my $description = $object->source_description) =~ s/(\w+) \[(http:\/\/[\w\.\/]+)\]/<a href="$2" class="constant">$1<\/a>/; 
  my $source_prefix = 'View in';

  # Source link
  if ($source =~ /dbSNP/) {
    $sname       = 'DBSNP';
    $source_link = $hub->get_ExtURL_link("$source_prefix dbSNP", $sname, $name);
  } elsif ($source =~ /ClinVar/i) {
    $sname = ($name =~ /^rs/) ?  'CLINVAR_DBSNP' : 'CLINVAR';
    $source_link = $hub->get_ExtURL_link("About $source", $sname, $name);
  } elsif ($source =~ /SGRP/) {
    $source_link = $hub->get_ExtURL_link("About $source", 'SGRP_PROJECT');
  } elsif ($source =~ /COSMIC/) {
    my $cname = ($name =~ /^COSM(\d+)/) ? $1 : $name;
    $source_link = $hub->get_ExtURL_link("$source_prefix $source", $source, $cname);
  } elsif ($source =~ /HGMD/) {
    $version =~ /(\d{4})(\d+)/;
    $version = "$1.$2";
    my $pf          = ($hub->get_adaptor('get_PhenotypeFeatureAdaptor', 'variation')->fetch_all_by_Variation($object->Obj))->[0];
    my $asso_gene   = $pf->associated_gene;
       $source_link = $hub->get_ExtURL_link("$source_prefix $source", 'HGMD', { ID => $asso_gene, ACC => $name });
  } elsif ($source =~ /ESP/) {
    if ($name =~ /^TMP_ESP_(\d+)_(\d+)/) {
      $source_link = $hub->get_ExtURL_link("$source_prefix $source", $source, { CHR => $1 , START => $2, END => $2});
    }
    else {
      $source_link = $hub->get_ExtURL_link("$source_prefix $source", "${source}_HOME");
    }
  } elsif ($source =~ /LSDB/) {
    $version = ($version) ? " ($version)" : '';
    $source_link = $hub->get_ExtURL_link("$source_prefix $source", $source, $name);
  }  elsif ($source =~ /PhenCode/) {
     $sname       = 'PHENCODE';
     $source_link = $hub->get_ExtURL_link("$source_prefix PhenCode", $sname, $name);
  } else {
## EG
    #$source_link = $url ? qq{<a href="$url" class="constant">$source_prefix $source</a>} : "$source $version";
    if ($url) {
      $description = qq(<a href="$url">$description</a>);
    }
##
  }
  
  $version = ($version) ? " (release $version)" : '';
## EG  
  return ['Original source', sprintf('<p>%s%s%s</p>', $description, $version, $source_link ? " | $source_link" : '')];
##
}

1;
