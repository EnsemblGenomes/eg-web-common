# $Id: Export.pm,v 1.2 2011-02-15 17:59:19 it2 Exp $

package EnsEMBL::Web::Configuration::Export;

sub modify_tree {
  my $self = shift; 
  my %config = ( availability => 1, no_menu_entry => 1 );
  $self->create_node("VCFView", '', [ 'vcf_view', 'EnsEMBL::Web::Component::Export::VCFView' ], \%config);  
}

1;
