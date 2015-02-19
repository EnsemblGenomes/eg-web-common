package EnsEMBL::Web::Component::VariationTable;


sub make_table {
  my ($self, $table_rows, $consequence_type) = @_;
  my $hub      = $self->hub;
  my $glossary = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub)->fetch_glossary_lookup;
  
  # Using explicit wdiths speeds things up and makes layout more predictable
  # u = 1unit, where unit is calculated so that total width is 100%
  my $columns = [
    { key => 'ID',       width => '12u', sort => 'html',                                                      help => 'Variant identifier'                     },
    { key => 'chr' ,     width => '10u', sort => 'hidden_position', label => 'Chr: bp',                       help => $glossary->{'Chr:bp'}                    },
    { key => 'Alleles',  width => '16u', sort => 'string',          label => "Alle\fles",  align => 'center', help => 'Alternative nucleotides'                },
    { key => 'class',    width => '11u', sort => 'string',          label => 'Class',      align => 'center', help => $glossary->{'Class'}                     },
    { key => 'Source',   width => '8u',  sort => 'string',          label => "Sour\fce",                      help => $glossary->{'Source'}                    },
    { key => 'status',   width => '9u',  sort => 'string',          label => "Evid\fence", align => 'center', help => $glossary->{'Evidence status (variant)'} },
    { key => 'clinsig',  width => '6u',  sort => 'string',          label => "Clin\f sig",                    help => 'Clinical significance'                  },
    { key => 'snptype',  width => '12u', sort => 'position_html',   label => 'Type',                          help => 'Consequence type'                       },
    { key => 'aachange', width => '6u',  sort => 'string',          label => 'AA',         align => 'center', help => 'Resulting amino acid(s)'                },
    { key => 'aacoord',  width => '6u',  sort => 'position',        label => "AA co\ford", align => 'center', help => 'Amino Acid Co-ordinate'                 }
  ];
  
  # submitter data for LRGs
  splice @$columns, 5, 0, { key => 'Submitters', width => '10u', sort => 'string', align => 'center', export_options => { split_newline => 2 } } if $self->isa('EnsEMBL::Web::Component::LRG::VariationTable');

  # HGVS
  splice @$columns, 3, 0, { key => 'HGVS', width => '10u', sort => 'string', title => 'HGVS name(s)', align => 'center', export_options => { split_newline => 2 } } if $hub->param('hgvs') eq 'on';

  # add SIFT 
  push @$columns, (
      { key => 'sift',     sort => 'position_html', width => '6u', label => "SI\aFT",     align => 'center', help => $glossary->{'SIFT'} });

  if ($hub->type ne 'Transcript') {
    push @$columns, { key => 'Transcript', sort => 'string', width => '11u', help => $glossary->{'Transcript'} };
  }

  return $self->new_table($columns, $table_rows, { data_table => 1, sorting => [ 'chr asc' ], exportable => 1, id => "${consequence_type}_table", class => 'cellwrap_inside fast_fixed_table' });
} 

1;
