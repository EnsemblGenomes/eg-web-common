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

# $Id: Gene.pm,v 1.6 2013-12-13 12:46:48 jh15 Exp $

package EnsEMBL::Web::ZMenu::Gene;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $object       = $self->object;
  my @xref         = $object->display_xref;
  my $g            = $hub->param('g');

  $self->caption($xref[0] ? "$xref[3]: $xref[0]" : 'Novel transcript');

  my $zmenu_label = $object->stable_id;
  if ($species_defs->GENOMIC_UNIT eq 'bacteria') {
    $zmenu_label = $xref[0] ? $xref[0]." (".$object->stable_id.")" : $object->stable_id;
  }
  
  $self->add_entry({
    type  => 'Gene',
    label => $zmenu_label,
    link  => $hub->url({
      type => 'Gene',
      action => 'Summary',
      g => $g,
#     __clear => '1' #gets rid of the url variation data in order to avoid a bug                                      
    })
  });

  my $urls             = $hub->ExtURL;
  if (my $g = $object->Obj) {
      if (my @attrs = @{ $g->get_all_Attributes() }) {
	  foreach my $attr (reverse @attrs) {
	      if ($attr->code eq 'external_db') { # if want to display xrefs to the external db for this gene
		  my $aname = uc($attr->value);
		  if ($urls && $urls->is_linked($aname)) {
		      if (my $dblinks = $g->get_all_DBLinks($aname)) {
			  if (my $xref = shift @$dblinks) {
			      my $alink = $urls->get_url($aname, $xref);
			      $self->add_entry({
				  type       => $attr->value,
				  label_html => sprintf(qq{<a href="%s">%s</a>}, $alink, $xref->display_id)
				  });       
			  }
		      }
		  }
	      } else {
# for phibase the value of the phibase attribute is also used to pick the gene / transcript colour
# and it should not spaces thus the regex
		  ( my $v = $attr->value ) =~ s/\_/ /g;

		  $self->add_entry({
		      type       => $attr->name,
		      label_html => $v
		      });       
	      
	      }
	  }
      }
  }

  
  $self->add_entry({
    type  => 'Location',
    label => sprintf(
      '%s: %s-%s',
      $self->neat_sr_name($object->seq_region_type, $object->seq_region_name),
      $self->thousandify($object->seq_region_start),
      $self->thousandify($object->seq_region_end)
    ),
    link  => $hub->url({
      type   => 'Location',
      action => 'View',
      r      => $object->seq_region_name . ':' . $object->seq_region_start . '-' . $object->seq_region_end,
      g      => $g,
      __clear => '1' #gets rid of the url variation data in order to avoid a bug                                               
    })
  });
  
  $self->add_entry({
    type  => 'Gene type',
    label => $object->gene_type
  });
  
  $self->add_entry({
    type  => 'Strand',
    label => $object->seq_region_strand < 0 ? 'Reverse' : 'Forward'
  });
  
  if ($object->analysis) {
    $self->add_entry({
      type  => 'Analysis',
      label => $object->analysis->display_label, 
    });
    
    $self->add_entry({
      type       => 'Annotation method',
      label_html => $object->analysis->description
    });
  }

warn "AN URL " . $species_defs->ANNOTATION_URL;

  if (my $annotation_url = $species_defs->ANNOTATION_URL) {
    
    my ($sr, $start, $end) = ($object->seq_region_name, $object->seq_region_start, $object->seq_region_end);
    $annotation_url =~ s/###SEQ_REGION###/$sr/;
    $annotation_url =~ s/###START###/$start/;
    $annotation_url =~ s/###END###/$end/;

    $self->add_entry({
      type  => 'Community annotation',
      label => 'Click here to annotate',
      link  => $annotation_url,
    });
  }

  
}

1;
