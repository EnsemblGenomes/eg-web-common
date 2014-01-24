# $Id: ExternalData.pm,v 1.2 2011-03-25 17:06:10 nl2 Exp $

package EnsEMBL::Web::ViewConfig::ExternalData;

use strict;

sub form {
  my ($view_config, $object) = @_;
  
  $view_config->add_fieldset('DAS sources');
  
  my $view    = $object->__objecttype . '/ExternalData';
  my @all_das = sort { lc $a->label cmp lc $b->label } grep {$_->is_on($view) and $_->renderer !~ /^S4DAS/} values %{$view_config->hub->get_all_das};
  
  foreach my $das (@all_das) {
    $view_config->add_form_element({
      type  => 'DASCheckBox',
      das   => $das,
      name  => $das->logic_name,
      value => 'yes'
    });
  }
}

1;
