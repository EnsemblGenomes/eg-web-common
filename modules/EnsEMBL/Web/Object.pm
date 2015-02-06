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

package EnsEMBL::Web::Object;
use Data::Dumper;

sub get_ontology_chart {
  my $self = shift ;
  my $obj = $self->Obj;

  # The array will have the list of ontologies mapped 
  my $ontologies = $self->species_defs->DISPLAY_ONTOLOGIES || return {};

  my $dbname_to_match = shift;
  if ($dbname_to_match) {
      if ( (ref $obj) =~ /Gene/) {
	  $dbname_to_match .= "\|${dbname_to_match}_to_gene"; # include the gene-level xrefs
      }
  } else {
      $dbname_to_match =  join '|', @$ontologies;
  }

  my ($ancestor, $termid, $add_relation) = @_;

  my %chart;
  
  my $goadaptor = $self->hub->get_databases('go')->{'go'};
  my $goa = $goadaptor->get_OntologyTermAdaptor;
  
  my $aterm;  
  eval { 
      $aterm = $goa->fetch_by_accession($ancestor); 
  };
  
  return {} unless $aterm;
  my $namespace = $aterm->{namespace};

  if ($termid) {
      my $term;
      eval { 
	  $term = $goa->fetch_by_accession($termid); 
      };
      next unless $term->{namespace} eq $namespace;

      my $talist = $goa->_fetch_ancestor_chart($term);
      foreach my $t (keys %{$talist || {}}) {
	       my $ta = $talist->{$t};
	       my %ss = map { $_ => 1}  @{$ta->{term}->{subsets} || []};
	       $chart{$t} = {
		   'dbid' => $ta->{term}->{dbID},   
	         'id' => $t,
	         'name' => $ta->{term}->{name}, 
	         'def' => $ta->{term}->{definition},
	         'subsets' => \%ss,
	       };
	  
	       my @relations = grep { $_ !~ /term/ } keys %$ta;
       
	       foreach my $tp (@relations) {
	         if ($ta->{$tp}) {
		     push @{$chart{$t}->{rels}}, map { "$tp $_->{accession}" } @{$ta->{$tp}}; 
	         }
	       }         
      }
      $chart{$ancestor}->{root} = 1;
      $chart{$termid}->{selected} = 1;          

     if ($add_relation) {
      my %myids = map { $chart{$_}->{dbid} => $_ } keys %chart;
      my @dbids = sort keys %myids;
      my $rlist = $goa->_find_relations($add_relation, \@dbids);

      foreach my $r (@$rlist) {
	  my $term = $myids{$r->{child_term_id}};
	  my $parent = $myids{$r->{parent_term_id}};
	  my $rel = $r->{name};
	  if ($add_relation->{$rel}) {
	      push @{$chart{$term}->{rels}}, "$rel $parent";
	  }
      }
  }


      return \%chart;
  }

  return {} unless $obj->can('get_all_DBLinks');
  my @goxrefs = @{$obj->get_all_DBLinks};

  foreach my $goxref ( @goxrefs ) {
    my $go = $goxref->display_id;
    next unless ($goxref->dbname =~ /^($dbname_to_match)$/);    
    my $term;
    eval { 
        $term = $goa->fetch_by_accession($go); 
    };

    next unless $term->{namespace} eq $namespace;

    next if (exists $chart{$go} && $chart{$go}->{selected});
    if (! exists $chart{$go} ) {    
      my $talist = $goa->_fetch_ancestor_chart($term);

      foreach my $t (keys %{$talist || {}}) {
	next if (exists $chart{$t});
        my $ta = $talist->{$t};
        my %ss = map { $_ => 1}  @{$ta->{term}->{subsets} || []};

        $chart{$t} = {
	 'dbid' => $ta->{term}->{dbID},   
         'id' => $t,
         'name' => $ta->{term}->{name}, 
         'def' => $ta->{term}->{definition},
         'subsets' => \%ss,
        };
       
        my @relations = grep { $_ !~ /term/ } keys %$ta;
        foreach my $tp (@relations) {
         if ($ta->{$tp}) {
          push @{$chart{$t}->{rels}}, map { "$tp $_->{accession}" } @{$ta->{$tp}}; 
         }
       }         
      }
  }

    if ($goxref->info_type eq 'PROJECTION') {
      push @{$chart{$go}->{notes}}, ["Projection", $goxref->info_text]; 
    }
    
    if ($goxref->isa('Bio::EnsEMBL::OntologyXref')) {
      if (my $evidence = join ', ', @{$goxref->get_all_linkage_types}) {
        push @{$chart{$go}->{notes}}, ["Evidence", $evidence ];
      } 

       my $sources;    

      foreach my $ext (@{ $goxref->get_extensions() }) {
	  push @{$chart{$go}->{extensions}} , $ext;
      }

       foreach my $e (@{$goxref->get_all_linkage_info}) {
          my ($linkage, $xref) = @{$e || []};
          next unless $xref; 
          my ($id, $db, $db_name, $db_id) =  ($xref->display_id, $xref->dbname, $xref->db_display_name, $xref->primary_id);
          push @{$chart{$go}->{notes}}, ["Source", "$db_name: " . $self->hub->get_ExtURL_link("$id", $db, $db_id) ];
      }
    }
    $chart{$go}->{selected} = 1;          
}

  if ($chart{$ancestor}) {
      $chart{$ancestor}->{root} = 1;

      if (! $chart{$ancestor}->{id}) { # when only the root term is annotated
	  $chart{$ancestor}->{'id'} = $aterm->{accession};
	  $chart{$ancestor}->{'dbid'} = $aterm->{dbID};
          $chart{$ancestor}->{'name'} = $aterm->{name}; 
          $chart{$ancestor}->{'def'} = $aterm->{definition};
         
          my %ss = map { $_ => 1}  @{$aterm->{subsets} || []};
          $chart{$ancestor}->{'subsets'} = \%ss;   
      }
  }
  if ($add_relation) {
      my %myids = map { $chart{$_}->{dbid} => $_ } keys %chart;
      my @dbids = sort keys %myids;
      my $rlist = $goa->_find_relations($add_relation, \@dbids);

      foreach my $r (@$rlist) {
	  my $term = $myids{$r->{child_term_id}};
	  my $parent = $myids{$r->{parent_term_id}};
	  my $rel = $r->{name};
	  if ($add_relation->{$rel}) {
	      push @{$chart{$term}->{rels}}, "$rel $parent";
	  }
      }
  }

  return \%chart;
}

sub get_target_slice {
  my $self = shift;
  my $hub = $self->hub;
  my $align_param = $hub->param('align');
  my $target_slice;

  #target_species and target_slice_name_range may not be defined so split separately
  #target_species but not target_slice_name_range is defined for pairwise compact alignments. 
  my ($align, $target_species, $target_slice_name_range) = split '--', $align_param;

## EG VB-3405 regex should allow dots in seq region name e.g. 'supercont1.186'  
  my ($target_slice_name, $target_slice_start, $target_slice_end) = $target_slice_name_range ?
    $target_slice_name_range =~ /([\w\.]+):(\d+)-(\d+)/ : (undef, undef, undef);
##

  #Define target_slice
  if ($target_species && $target_slice_start) {
      my $target_slice_adaptor = $hub->database('core', $target_species)->get_SliceAdaptor;
      $target_slice = $target_slice_adaptor->fetch_by_region('toplevel', $target_slice_name, $target_slice_start, $target_slice_end);
  }

  return $target_slice;
}

1;
