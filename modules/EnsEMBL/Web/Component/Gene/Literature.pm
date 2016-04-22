=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::Literature;
use strict;
use base qw(EnsEMBL::Web::Component::Gene);
use Data::Dumper;
use URI::Escape;
use JSON;
use LWP::UserAgent;

# TODO: move EuropePMC functionality into stand-alone web-service module

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $html;
  
  my $query = sprintf '(FULL_EXACT:"%s") AND SPECIES="%s"', join('" OR FULL_EXACT:"', @{$self->get_gene_names}),$hub->species_defs->SPECIES_SCIENTIFIC_NAME;
  my ($articles, $error) = $self->europe_pmc_articles($query.'&pageSize=50');

  if ($error) {
  
    $html .= $self->_info_panel('error', 'Failed to fetch articles from EuropePMC', $error);
  
  } else {

    my $table = $self->new_table(
      [
        { key => 'pubmed_id', title => 'PubMed&nbsp;ID', width => '6%',  align => 'left', sort => 'html' },
        { key => 'title',     title => 'Title',          width => '50%', align => 'left', sort => 'string' },
        { key => 'authors',   title => 'Authors',        width => '22%', align => 'left', sort => 'html' },
        { key => 'journal',   title => 'Journal',        width => '22%', align => 'left', sort => 'string' },
      ], 
      [], 
      { 
        class      => 'no_col_toggle',
        data_table => 1, 
        exportable => 0,
        data_table_config => {
            iDisplayLength => 10
        },
      }
    );

    foreach (@$articles) {
      my @authors = split /\s*,\s+|\s*and\s+/, $_->{authorString};
      @authors = map {sprintf '<a href="http://europepmc.org/search?page=1&query=%s">%s</a>', uri_escape(qq(AUTH:"$_")), $_  } @authors;

      $table->add_row({
        pubmed_id => sprintf( '<a href="%s" style="white-space:nowrap">%s</a>', $hub->get_ExtURL('PUBMED', $_->{pmid}), $_->{pmid} ),
        title     => $_->{title},
        authors   => join(', ', @authors),
        journal   => sprintf '%s %s(%s) %s', $_->{journalTitle}, $_->{journalVolume}, $_->{issue}, $_->{pubYear}
      });
    }

    $html .= scalar(@$articles) == 0 ?
             sprintf '<p>There are no hits for this gene from <a href="https://europepmc.org/search?query=%s">Europe PubMed Central</a></p>', uri_escape($query) : 
             sprintf '<p>Showing the top %d hits from <a href="https://europepmc.org/search?query=%s">Europe PubMed Central</a></p>', scalar(@$articles), uri_escape($query);
    $html .= $table->render;  
  }

  return $html;
}

sub get_gene_names {
  my $self   = shift;
  my $obj    = $self->object->Obj;
  my @names  = ($obj->display_id);

  if ($obj->can('display_xref')) {
    if (my $xref = $obj->display_xref) {
      push @names, $xref->display_id;
      #push @names, @{$xref->get_all_synonyms}
    }
  }
  
  return \@names;
}

sub europe_pmc_articles {
  my ($self, $query) = @_;
  my $articles = [];
  my $error    = 0;
  my $uri      = 'http://www.ebi.ac.uk/europepmc/webservices/rest/search/format=json&query=' . uri_escape($query);
  my $response = $self->_user_agent->get($uri);

  if ($response->is_success) {
    my $content = $response->content;
    $content =~ s/^jsonp\((.*)\)$/$1/ if $content =~ /^jsonp/;
    eval { $articles = from_json($content)->{resultList}->{result} };
    $error = $@ if $@;
  } else {
    $error = $response->status_line;
  }

  return $articles, $error;  
}

sub _user_agent {
  my $self = shift;
  my $ua = LWP::UserAgent->new;
  $ua->agent($SiteDefs::SITE_NAME . ' ' . $SiteDefs::SITE_RELEASE_VERSION);
  $ua->env_proxy;
  return $ua;
}

1;

