# $Id: Transcript.pm,v 1.4 2013-03-06 16:09:35 jk10 Exp $

package EnsEMBL::Web::ZMenu::Transcript;

use strict;

use base qw(EnsEMBL::Web::ZMenu);
use Data::Dumper;

sub content {
  my $self        = shift;
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $stable_id   = $object->stable_id;
  my $transcript  = $object->Obj;
  my $translation = $transcript->translation;
  my @xref        = $object->display_xref;
  $self->caption($xref[0] ? "$xref[3]: $xref[0]" : !$object->gene ? $stable_id : 'Novel transcript');
  $self->add_entry({
    type  => 'Transcript',
    label => $stable_id, 
    link  => $hub->url({ type => 'Transcript', action => 'Summary' })
  });
  

  my $urls             = $hub->ExtURL;
  if (my $g = $object->gene) {
      if (my @attrs = @{ $g->get_all_Attributes() }) {


# do reverse so the latest added ( more important :) attribs are displayed first 
	  foreach my $attr (reverse @attrs) {
#	      warn join ' * ', $attr->code, $attr->value, "\n";

	      if ($attr->code eq 'external_db') { # if want to display xrefs to the external db for this gene
		  my $aname = uc($attr->value);
		  if ($urls && $urls->is_linked($aname)) {
		      if (my $dblinks = $object->transcript->get_all_DBLinks($aname)) {
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
# and it should not have spaces thus the regex
		  ( my $v = $attr->value ) =~ s/\_/ /g;

		  $self->add_entry({
		      type       => $attr->name,
		      label_html => $v
		      });       
	      
	      }
	  }
      }
  }

  # Only if there is a gene (not Prediction transcripts)
  if ($object->gene) {
    $self->add_entry({
      type  => 'Gene',
      label => $object->gene->stable_id,
      link  => $hub->url({ type => 'Gene', action => 'Summary' }),
      position => 2,
    });
    
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
        r      => $object->seq_region_name . ':' . $object->seq_region_start . '-' . $object->seq_region_end
      })
    });
    
    $self->add_entry({
      type  => 'Gene type',
      label => $object->gene_stat_and_biotype
    });
  }
  
  if ($object->transcript_type) {
    $self->add_entry({
      type  => 'Transcript type',
      label => $object->transcript_type
    });
  }
  
  $self->add_entry({
    type  => 'Strand',
    label => $object->seq_region_strand < 0 ? 'Reverse' : 'Forward'
  });
  
  $self->add_entry({
    type  => 'Base pairs',
    label => $self->thousandify($transcript->seq->length)
  });
  
  # Protein coding transcripts only
  if ($translation) {
    $self->add_entry({
      type     => 'Protein product',
      label    => $translation->stable_id || $stable_id,
      link     => $self->hub->url({ type => 'Transcript', action => 'ProteinSummary' }),
      position => 3
    });
    
    $self->add_entry({
      type  => 'Amino acids',
      label => $self->thousandify($translation->length)
    });
  }

  if ($object->analysis) {
    $self->add_entry({
      type  => 'Analysis',
      label => $transcript->analysis->display_label,
    });

    $self->add_entry({
      type  => 'Prediction method',
      label_html => $transcript->analysis->description
    });
  }

}

1;
