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

package EnsEMBL::Web::ZMenu::Contig;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self            = shift;
  my $hub             = $self->hub;
  my $threshold       = 1000100 * ($hub->species_defs->ENSEMBL_GENOME_SIZE||1);
  my $slice_name      = $hub->param('region');
  my $db_adaptor      = $hub->database('core');
  my $slice           = $db_adaptor->get_SliceAdaptor->fetch_by_region('seqlevel', $slice_name);
  my $slice_type      = $slice->coord_system_name;
  my $top_level_slice = $slice->project('toplevel')->[0]->to_Slice;
  my $action          = $slice->length > $threshold ? 'Overview' : 'View';
 
  # check if chromosome contiguous not showing center on contig link
  my $sa = $db_adaptor->get_adaptor('slice');
  my $no_center_on_contig = 0;
  foreach my $cs (@{$db_adaptor->get_CoordSystemAdaptor->fetch_all || []}) {
    #fetch all contigs
    if ($cs->name eq 'contig'){
      my @regions = @{$sa->fetch_all('contig')};
      $no_center_on_contig = 1 if scalar @regions == 1;
    }
  }
 
  $self->caption($slice_name);
  
  $self->add_entry({
    label => "Centre on $slice_type $slice_name",
    link  => $hub->url({ 
      type   => 'Location', 
      action => $action, 
      region => $slice_name 
    })
  }) unless $no_center_on_contig;
  
  $self->add_entry({
    label      => "Export $slice_type sequence/features",
    link_class => 'modal_link',
    link       => $hub->url({ 
      type     => 'Export',
      action   => 'Configure',
      function => 'Location',
      r        => sprintf '%s:%s-%s', map $top_level_slice->$_, qw(seq_region_name start end)
    })
  });

  foreach my $cs (@{$db_adaptor->get_CoordSystemAdaptor->fetch_all || []}) {
# in EG we want to get 

    next if $cs->name =~ /^chromosome|plasmid$/; # don't allow breaking of site by exporting all chromosome features
    my $path;
    eval { $path = $slice->project($cs->name); };
    
    next unless $path && scalar @$path == 1;

    my $new_slice        = $path->[0]->to_Slice->seq_region_Slice;
    my $new_slice_type   = $new_slice->coord_system_name;
    my $new_slice_name   = $new_slice->seq_region_name;
    my $new_slice_length = $new_slice->seq_region_length;

    $action = $new_slice_length > $threshold ? 'Overview' : 'View';

 # in EG we want these links for contigs as well   

    if (my $attrs = $new_slice->get_all_Attributes('external_db')) {
    	foreach my $attr (@$attrs) {

  	    my $ext_db = $attr->value;

  	    if( my $link = $hub->get_ExtURL($ext_db, $new_slice_name)) {
      		$self->add_entry({
      		  type     => $ext_db,
      		  label    => $new_slice_name,
      		  link     => $link, 
      		  external => 1
      		});
      		
      		(my $short_name = $new_slice_name) =~ s/\.[\d\.]+$//;
      		
      		$self->add_entry({
      		  type     => "$ext_db (latest version)",
      		  label    => $short_name,
      		  link     => $hub->get_ExtURL($ext_db, $short_name),
      		  external => 1
      		});
    	  }
    	}
    	next;
    }


    if (0 && $cs->name eq 'contig') {
      (my $short_name = $new_slice_name) =~ s/\.[\d\.]+$//;
      
      $self->add_entry({
        type     => 'ENA',
        label    => $new_slice_name,
        link     => $hub->get_ExtURL('EMBL', $new_slice_name),
        external => 1
      });
      
      $self->add_entry({
        type     => 'ENA (latest version)',
        label    => $short_name,
        link     => $hub->get_ExtURL('EMBL', $short_name),
        external => 1
      });
      next;
    }

    next if $cs->name eq $slice_type;  # don't show the slice coord system twice    

    $self->add_entry({
      label => "Centre on $new_slice_type $new_slice_name",
      link  => $hub->url({
        type   => 'Location', 
        action => $action, 
        region => $new_slice_name
      })
    });

    # would be nice if exportview could work with the region parameter, either in the referer or in the real URL
    # since it doesn't we have to explicitly calculate the locations of all regions on top level
    $top_level_slice = $new_slice->project('toplevel')->[0]->to_Slice;

    $self->add_entry({
      label      => "Export $new_slice_type sequence/features",
      link_class => 'modal_link',
      link       => $hub->url({
        type     => 'Export',
        action   => $action,
        function => 'Location',
        r        => sprintf '%s:%s-%s', map $top_level_slice->$_, qw(seq_region_name start end)
      })
    });
 # in EG we want these links for contigs as well   


    if ($cs->name eq 'clone') {
      (my $short_name = $new_slice_name) =~ s/\.\d+$//;
    
      $self->add_entry({
        type     => 'EMBL',
        label    => $slice_name,
        link     => $hub->get_ExtURL('EMBL', $slice_name),
        external => 1
      });
      
      $self->add_entry({
        type     => 'EMBL (latest version)',
        label    => $short_name,
        link     => $hub->get_ExtURL('EMBL', $short_name),
        external => 1
      });
    }
  }
}

1;
