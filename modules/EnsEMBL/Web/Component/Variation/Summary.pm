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

sub content {
  my $self               = shift;
  my $hub                = $self->hub;
  my $object             = $self->object;
  my $variation          = $object->Obj;
  my $vf                 = $hub->param('vf');
  my $variation_features = $variation->get_all_VariationFeatures;
  my ($feature_slice)    = map { $_->dbID == $vf ? $_->feature_Slice : () } @$variation_features; # get slice for variation feature
  my $avail              = $object->availability;  

  my $info_box;
  if ($variation->failed_description || (scalar keys %{$object->variation_feature_mapping} > 1)) { 
    ## warn if variation has been failed
    $info_box = $self->multiple_locations($feature_slice, $variation->failed_description); 
  }

  my $transcript_url  = $hub->url({ action => "Variation", action => "Mappings",    vf => $vf });
  my $genotype_url    = $hub->url({ action => "Variation", action => "Individual",  vf => $vf });
  my $phenotype_url   = $hub->url({ action => "Variation", action => "Phenotype",   vf => $vf });
  my $citation_url    = $hub->url({ action => "Variation", action => "Citations",   vf => $vf });
 
  my @str_array;
  push @str_array, sprintf('overlaps <a href="%s">%s %s</a>', 
                      $transcript_url, 
                      $avail->{has_transcripts}, 
                      $avail->{has_transcripts} eq "1" ? "transcript" : "transcripts"
                  ) if($avail->{has_transcripts});
  push @str_array, sprintf('has <a href="%s">%s individual %s</a>', 
                      $genotype_url, 
                      $avail->{has_individuals}, 
                      $avail->{has_individuals} eq "1" ? "genotype" : "genotypes" 
                  )if($avail->{has_individuals});
  push @str_array, sprintf('is associated with <a href="%s">%s %s</a>', 
                      $phenotype_url, 
                      $avail->{has_ega}, 
                      $avail->{has_ega} eq "1" ? "phenotype" : "phenotypes"
                  ) if($avail->{has_ega});  
  push @str_array, sprintf('is mentioned in <a href="%s">%s %s</a>', 
                      $citation_url, 
                      $avail->{has_citation}, 
                      $avail->{has_citation} eq "1" ? "citation" : "citations" 
                  ) if($avail->{has_citation});

  my $summary_table = $self->new_twocol(
    $self->variation_source,
    $self->alleles($feature_slice),
    $self->location,
    $feature_slice ? $self->co_located($feature_slice) : (),
    $self->most_severe_consequence($variation_features),
## EG    
    #$self->validation_status,
##    
    $self->evidence_status,
    $self->clinical_significance,
    $self->synonyms,
## EG
    $self->inter_homoeologues,
##
    $self->hgvs,
    $self->sets,
    @str_array ? ['About this variant', sprintf('This variant %s.', $self->join_with_and(@str_array))] : ()
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
    my $url     = $hub->url({ v => $name, vf => undef });
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
  warn $object;
  warn $object->source_description;
  ## parse description for links
  (my $description = $object->source_description) =~ s/(\w+) \[(http:\/\/[\w\.\/]+)\]/<a href="$2" class="constant">$1<\/a>/; 
  
  # Source link
  if ($source =~ /dbSNP/) {
    $sname       = 'DBSNP';
    $source_link = $hub->get_ExtURL_link("[View in dbSNP]", $sname, $name);
  } elsif ($source =~ /SGRP/) {
    $source_link = $hub->get_ExtURL_link("[About $source]", 'SGRP_PROJECT');
  } elsif ($source =~ /COSMIC/) {
    $sname       = 'COSMIC';
    my $cname = ($name =~ /^COSM(\d+)/) ? $1 : $name;
    $source_link = $hub->get_ExtURL_link("[View in $source]", "${sname}_ID", $cname);
  } elsif ($source =~ /HGMD/) {
    $version =~ /(\d{4})(\d+)/;
    $version = "$1.$2";
    my $pf          = ($hub->get_adaptor('get_PhenotypeFeatureAdaptor', 'variation')->fetch_all_by_Variation($object->Obj))->[0];
    my $asso_gene   = $pf->associated_gene;
       $source_link = $hub->get_ExtURL_link("[View in $source]", 'HGMD', { ID => $asso_gene, ACC => $name });
  } elsif ($source =~ /ESP/) {
    if ($name =~ /^TMP_ESP_(\d+)_(\d+)/) {
      $source_link = $hub->get_ExtURL_link("[View in $source]", $source, { CHR => $1 , START => $2, END => $2});
    }
    else {
      $source_link = $hub->get_ExtURL_link("[View in $source]", "${source}_HOME");
    }
  } elsif ($source =~ /LSDB/) {
    $version = ($version) ? " ($version)" : '';
    $source_link = $hub->get_ExtURL_link("[View in $source]", $source, $name);
  }  elsif ($source =~ /PhenCode/) {
     $sname       = 'PHENCODE';
     $source_link = $hub->get_ExtURL_link("[View in PhenCode]", $sname, $name);
  } else {
## EG
    #$source_link = $url ? qq{<a href="$url" class="constant">[View in $source]</a>} : "$source $version";
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
