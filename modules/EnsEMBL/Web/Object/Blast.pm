=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Object::Blast;

## The aim is to create an object which can be updated to
## use a different queuing mechanism, without any need to
## change the user interface. Where possible, therefore,
## public methods should accept the same arguments and
## return the same values

use strict;
use warnings;

use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);

use EnsEMBL::Web::BlastConstants qw(CONFIGURATION_FIELDS);
use previous qw(get_edit_jobs_data);

sub get_blast_form_options {
  ## Gets the list of options for dropdown fields in the blast input form
  my $self = shift;

  # return if already cached
  return $self->{'_form_options'} if $self->{'_form_options'};

  my $hub             = $self->hub;
  my $sd              = $self->species_defs;
  my @species         = $sd->tools_valid_species;
  my $blast_types     = $sd->multi_val('ENSEMBL_BLAST_TYPES');              # hashref with keys as BLAT, NCBIBLAST etc
  my $query_types     = $sd->multi_val('ENSEMBL_BLAST_QUERY_TYPES');        # hashref with keys dna, peptide
  my $db_types        = $sd->multi_val('ENSEMBL_BLAST_DB_TYPES');           # hashref with keys dna, peptide
  my $blast_configs   = $sd->multi_val('ENSEMBL_BLAST_CONFIGS');            # hashref with valid combinations of query_type, db_type, sources, search_type (and program for the search_type)
  my $sources         = $sd->multi_val('ENSEMBL_BLAST_DATASOURCES');        # hashref with keys as blast type and value as a hashref of data sources type and label
  my $sources_ordered = $sd->multi_val('ENSEMBL_BLAST_DATASOURCES_ORDER');  # hashref with keys as blast type and value as a ordered array if data sources type
  my $search_types    = [ map { $_->{'search_type'} } @$blast_configs ];    # NCBIBLAST_BLASTN, NCBIBLAST_BLASTP, BLAT_BLAT etc

  my $options         = {}; # Options for different dropdown fields
  my $missing_sources = {}; # List of missing source files per species

  # Species, query types and db types options
## EG - don't need full species list here - too slow in Bacteria 
  $options->{'species'}        = [ $sd->PRIMARY_SPECIES ];#[ sort { $a->{'caption'} cmp $b->{'caption'} } map { 'value' => $_, 'caption' => $sd->species_label($_, 1) }, @species ];
##  
  $options->{'query_type'}     = [ map { 'value' => $_, 'caption' => $query_types->{$_} }, keys %$query_types ];
  $options->{'db_type'}        = [ map { 'value' => $_, 'caption' => $db_types->{$_}    }, keys %$db_types    ];

  # Search type options
  foreach my $search_type (@$search_types) {
    my ($blast_type, $search_method) = $self->parse_search_type($search_type);
    push @{$options->{'search_type'}}, { 'value' => $search_type, 'caption' => $search_method };
  }

  # DB Source options
  foreach my $source_type (@$sources_ordered) {
    for (@$blast_configs) {
      if (grep { $source_type eq $_ } @{$_->{'sources'}}) {
        push @{$options->{'source'}{$_->{'db_type'}}}, { 'value' => $source_type, 'caption' => $sources->{$source_type} };
        last;
      }
    }
  }

  # Find the missing source files
  for (@species) {
    my $available_sources = $sd->get_available_blast_datasources($_);
    if (my @missing = grep !$available_sources->{$_}, keys %$sources) {
      $missing_sources->{$_} = \@missing;
    }
  }

  return $self->{'_form_options'} = {
    'options'         => $options,
    'missing_sources' => $missing_sources,
    'combinations'    => $blast_configs
  };
}

sub get_edit_jobs_data {
  my $self      = shift;
  my $sd        = $self->hub->species_defs;
  my $jobs_data = $self->PREV::get_edit_jobs_data(@_);

  $_->{'species'} = ucfirst($_->{'species'}) for @$jobs_data;

  return $jobs_data;
}


1;
