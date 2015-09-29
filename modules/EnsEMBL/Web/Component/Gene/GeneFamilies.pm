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

package EnsEMBL::Web::Component::Gene::GeneFamilies;

### Displays gene families for this gene

use strict;
use base qw(EnsEMBL::Web::Component::Transcript);
use EnsEMBL::Web::TmpFile::Text;
use URI::Escape;

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}

sub content {
  my $self           = shift;
  my $hub            = $self->hub;
  my $species_defs   = $hub->species_defs;
  my $gene_family_id = $hub->param('gene_family_id');
  my $object         = $self->object;
  my $gene_stable_id = $object->stable_id;
  my $compara_db     = $object->database('compara');
  my $member_adaptor = $compara_db->get_GeneMemberAdaptor;
  my $family_adaptor = $compara_db->get_FamilyAdaptor;
  my $html;
  
  
  my $member = $member_adaptor->fetch_by_stable_id($gene_stable_id);
    
  my $families = [];
  $families = $family_adaptor->fetch_all_by_GeneMember($member) if $member;
  return "<p>There are no gene families for this gene</p>" unless $member and @$families;
 
  unless ($gene_family_id) {
    $gene_family_id = $families->[0]->stable_id;
    $hub->param('gene_family_id', $gene_family_id);
  }
 
  my ($family) = grep {$_->stable_id eq $gene_family_id} @$families;
  return "<p>Cannot find gene family $gene_family_id</p>" unless $family;
  
  if (@$families > 1) {       
    
    # family selector
    
    my $hidden_params = join('', map { 
      sprintf '<input type="hidden" name="%s" value="%s">', $_, $hub->param($_) 
    } (qw(g r t)) );
    
    my $options = join('', map { 
      sprintf '<option value="%s"%s>%s</option>', $_->stable_id, ($_->stable_id eq $gene_family_id ? 'selected' : ''), $_->stable_id . ($_->description ? ' (' . $_->description . ')' : '')
    } @$families);
    
    $html .= sprintf (
      qq{
        <div style="width: 330px; float:right; text-align: right;white">
          <form name="gene_family_form" method="get">
            %s
            <b>Gene family</b> 
            <select name="gene_family_id">
              %s
            </select>
            <input type="submit" value="Go" class="fbutton" />
          </form>
        </div>  
      }, 
      $hidden_params,
      $options
    );
  }
  
  my $data = $object->filtered_family_data($family);
  
  # family stats
    
  my $stats = $self->new_twocol;
  $stats->add_row('Gene family',   $family->stable_id);
  $stats->add_row('Description',   $family->description || 'n/a');
  $stats->add_row('Species count', $data->{is_filtered} ? "showing $data->{species_count} of $data->{total_species_count}" : $data->{species_count});
  $stats->add_row('Gene count',    $data->{is_filtered} ? "showing $data->{member_count} of $data->{total_member_count}" : $data->{member_count});
  $html .= $stats->render;  

  # filter buttons

  $html .= '<p>';
  $html .= sprintf '<a class="fbutton modal_link" href="%s">Filter gene family</a> ', $hub->url('Component', { action => 'Web', function => 'GeneFamilySelector/ajax' }, undef, 1);
  if ($data->{is_filtered}) {
    $html .= sprintf (
      '<a class="fbutton" href="%s">Clear filter</a> ',
      $hub->species_path($hub->data_species) . "/Gene/Gene_families/SaveFilter?gene_family_id=$gene_family_id;redirect=" . uri_escape($hub->url)
    );
  }
  $html .= sprintf '<a class="fbutton" target="_blank" href="%s">Download protein sequences</a> ', $hub->url({ action => 'Gene_families', function => 'Sequence', _format => 'Text', gene_family_id => $gene_family_id });
  $html .= '</p>';

  # member table
  
  my $table = $self->new_table(
    [
      { key => 'id',          title => 'Gene stable ID', width => '15%', align => 'left', sort => 'html'   },
      { key => 'name',        title => 'Name',           width => '10%', align => 'left', sort => 'html'   },
      { key => 'description', title => 'Description',    width => '25%', align => 'left', sort => 'string' },
      { key => 'taxon_id',    title => 'Taxon ID',       width => '10%', align => 'left', sort => 'string' },
      { key => 'species',     title => "Species",        width => '40%', align => 'left', sort => 'html'   },
    ], 
    [], 
    { 
      sorting => [ 'species asc' ], 
      class => 'no_col_toggle',
      data_table => 1, 
      data_table_config => { iDisplayLength => 25, aLengthMenu => [[25, 50, 100, -1], [25, 50, 100, "All"]] },
    }
  );
  
  foreach my $member (@{$data->{members}}) {
    #my $species_path = $species_defs->species_path($member->{species});  ### Too slow with 16,000 members!!
    my $species_path = '/' . $member->{species};

    $table->add_row({
      id          => '<a href="' . $species_path. '/Gene/Summary?db=core;g=' . $member->{id} . '">' . $member->{id} . '</a>',
      name        => $member->{name},
      taxon_id    => $member->{taxon_id},
      description => $member->{description},
      species     => '<a href="' . $species_path . '">' . $species_defs->species_display_label($member->{species}) . '</a>',
    });
  }
   
  return $html . $table->render;
}

sub ajax_url {
  my $self     = shift;
  my $function = shift;
  my $params   = shift || {};
  my (undef, $plugin, undef, undef, $module) = split '::', ref $self;
  
  $module .= "/$function" if $function && $self->can("content_$function");
  
  return $self->hub->url('Component', { action => $plugin, function => $module, %$params }, undef, !$params->{'__clear'});
}

1;
