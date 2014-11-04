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

package EnsEMBL::Web::Component::Variation::IndividualGenotypes;

use strict;
use warnings;

sub get_table_headings {
  return [
    { key => 'Individual',  title => 'Individual<br />',               sort => 'html' },
    { key => 'Genotype',    title => 'Genotype<br />(forward strand)', sort => 'html' },
    { key => 'Description', title => 'Description',                    sort => 'html' }
	];
}

sub _get_tair_url {
  my ($self, $sub_type, $name) = @_;
  my $tair_url = '';

  $tair_url = sprintf(
    '<a href="http://www.arabidopsis.org/servlets/Search?type=general&search_action=detail&method=1&show_obsolete=F&name=%s&sub_type=%s&SEARCH_EXACT=4&SEARCH_CONTAINS=1">%s</a>',
    $name, $sub_type, $name
  ) if $name;

  return $tair_url;
}

sub _get_tair_urls {
  my ($self, $ind_name) = @_;
  my ($ecotype, $germplasm, $pop) = split ':', $ind_name;

  return join ':', $self->_get_tair_url('ecotype', $ecotype), $self->_get_tair_url('germplasm', $germplasm), $pop;
}

sub content {
  my $self         = shift;
  my $object       = $self->object;
  my $hub          = $self->hub;
  my $selected_pop = $hub->param('pop');
  
  
  my $pop_obj  = $selected_pop ? $self->hub->get_adaptor('get_PopulationAdaptor', 'variation')->fetch_by_dbID($selected_pop) : undef;
  my %ind_data = %{$object->individual_table($pop_obj)};

  return sprintf '<h3>No individual genotypes for this SNP%s %s</h3>', $selected_pop ? ' in population' : '', $pop_obj->name unless %ind_data;

  my (%rows, %all_pops, %pop_names);
  my $flag_children = 0;
  my $allele_string = $self->object->alleles;
  my $al_colours = $self->object->get_allele_genotype_colours;
  
  foreach my $ind_id (sort { $ind_data{$a}{'Name'} cmp $ind_data{$b}{'Name'} } keys %ind_data) {
    my $data     = $ind_data{$ind_id};
    my $genotype = $data->{'Genotypes'};
    
    next if $genotype eq '(indeterminate)';
    
    my $father      = $self->format_parent($data->{'Father'});
    my $mother      = $self->format_parent($data->{'Mother'});
    my $description = $data->{'Description'} || '-';
    my %populations;
    
    my $other_ind = 0;
    
    foreach my $pop(@{$data->{'Population'}}) {
      my $pop_id = $pop->{'ID'};
      next unless ($pop_id);
     
      $pop->{'Name'}=~ s/population/collection/g;
 
      if ($pop->{'Size'} == 1) {
        $other_ind = 1;
      }
      else {
        $populations{$pop_id} = 1;
        $all_pops{$pop_id}    = $self->pop_url($pop->{'Name'}, $pop->{'Link'});
        $pop_names{$pop_id}   = $pop->{'Name'};
      }
    }
    
    # Colour the genotype
    foreach my $al (keys(%$al_colours)) {
      $genotype =~ s/$al/$al_colours->{$al}/g;
    } 

## EG - ENSEMBL-3455
    my $display_name     = $hub->species eq 'arabidopsis_thaliana'     ? $self->_get_tair_urls($data->{'Name'}) : $data->{'Name'};
    my $display_genotype = $hub->species eq 'aaccharomyces_cerevisiae' ? substr($genotype, 0, index($genotype, '|')) : $genotype;
    
    my $row = {
      Individual  => "<small id=\"$data->{'Name'}\">$display_name</small>",
      Genotype    => "<small>$display_genotype</small>",
      Description => "<small>$description</small>",
    };
##    

    my @children = map { sprintf "<small><a href=\"#$_\">$_</a> (%s)</small>", substr($data->{'Children'}{$_}[0], 0, 1) } keys %{$data->{'Children'}};
    
    if (@children) {
      $row->{'Children'} = join ', ', @children;
      $flag_children = 1;
    }
    
    if ($other_ind == 1 && scalar(keys %populations) == 0) {  
      push @{$rows{'other_ind'}}, $row;
      ## need this to display if there is only one genotype for a sequenced individual
      $pop_names{"other_ind"} = "single individuals";
    }
    else {
      push @{$rows{$_}}, $row foreach keys %populations;
    }
  }
  
  my $columns = $self->get_table_headings;
  
  push @$columns, { key => 'Children', title => 'Children<br /><small>(Male/Female)</small>', sort => 'none', help => 'Children names and genders' } if $flag_children;
    
  
  if ($selected_pop || scalar keys %rows == 1) {
    $selected_pop ||= (keys %rows)[0]; # there is only one entry in %rows
      
    return $self->toggleable_table(
      "Genotypes for $pop_names{$selected_pop}", $selected_pop, 
      $self->new_table($columns, $rows{$selected_pop}, { data_table => 1, sorting => [ 'Individual asc' ] }),
      1,
      qq{<span style="float:right"><a href="#$self->{'id'}_top">[back to top]</a></span><br />}
    );
  }
  
  return $self->summary_tables(\%all_pops, \%rows, $columns);
}

1;

