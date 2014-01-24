# $Id: StaticTabs.pm,v 1.1 2013-09-04 11:09:00 jh15 Exp $

package EnsEMBL::Web::Document::Element::StaticTabs;

# Generates the global context navigation menu, used in static pages

use strict;

sub _tabs {
  return {
#EG remove tabs
    tab_order => [],#qw(website genome data docs about)],
#/EG
    tab_info  => {
      about     => {
                    title => 'About us',
                    },
      data      => {
                    title => 'Data access',
                    },
      docs      => {
                    title => 'API & software',
                    },
      genome    => {
                    title => 'Annotation & prediction',
                    },
      website   => {
                    title => 'Using this website',
                    },
    },
  };
}

1;
