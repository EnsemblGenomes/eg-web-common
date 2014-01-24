package EnsEMBL::Web::Component::Variation::IndividualGenotypes;

use strict;
use warnings;

sub get_table_headings {
  return [
    { key => 'Individual', title => 'Individual<br />', 
        sort => 'html' },
    { key => 'Genotype', title => 'Genotype<br />(forward strand)', 
        sort => 'html' },
    { key => 'Description', title => 'Description',                    
        sort => 'html' }
	];
}

sub _get_tair_url {
  my $self = shift;
  my $sub_type = shift;
  my $name = shift;

  my $tair_url = '';

  if ($name ne '')
  {
      $tair_url = '<a href="http://www.arabidopsis.org/servlets/Search?' .
          'type=general&search_action=detail&method=1&show_obsolete=F' .
          "&name=$name" .
          "&sub_type=$sub_type" .
          '&SEARCH_EXACT=4&SEARCH_CONTAINS=1"' .
          ">$name</a>";
  }
  else
  {
      $tair_url = $name;
  }

  return($tair_url);
}

sub _get_tair_urls {
  my $self = shift;
  my $ind_name = shift;

  my $separator = ':';

  my ($ecotype, $germplasm, $pop) = split $separator, $ind_name;

  my $ind_url = '';

  $ind_url .= $self->_get_tair_url('ecotype', $ecotype);

  $ind_url .= $separator;

  $ind_url .= $self->_get_tair_url('germplasm', $germplasm);

  $ind_url .= "$separator$pop";

  return($ind_url);
}

sub get_row_data {
  my $self = shift;
  my $ind_name = shift;
  my $ind_gender = shift;
  my $genotype = shift;
  my $description = shift;
  my $pop_string = shift;
  
  return({
      Individual  => '<small>' . 
          ($self->object->species_defs->SPECIES_SCIENTIFIC_NAME eq 
          'Arabidopsis thaliana' ? 
              $self->_get_tair_urls($ind_name) : $ind_name) . 
          '</small>',
      Genotype    => '<small>' . 
          ($self->object->species_defs->SPECIES_SCIENTIFIC_NAME eq
          'Saccharomyces cerevisiae' ?
              substr($genotype, 0, index($genotype, '|')) : $genotype) . 
          '</small>',
      Description => "<small>$description</small>",
  });
}

sub summary_tables {
  my ($self, $all_pops, $rows, $ind_columns) = @_;
  my $hub          = $self->hub;
  my $od_table     = $self->new_table([], [], { data_table => 1, download_table => 1, sorting => [ 'Population asc' ] });
  my $hm_table     = $self->new_table([], [], { data_table => 1, download_table => 1, sorting => [ 'Population asc' ] });
  my $tg_table     = $self->new_table([], [], { data_table => 1, download_table => 1, sorting => [ 'Population asc' ] });
  my $ind_table    = $self->new_table([], [], { data_table => 1, download_table => 1, sorting => [ 'Individual asc' ] });
  my %descriptions = map { $_->dbID => $_->description } @{$hub->get_adaptor('get_PopulationAdaptor', 'variation')->fetch_all_by_dbID_list([ keys %$all_pops ])};
  my ($other_row_count, $html);
  
  foreach ($od_table, $hm_table, $tg_table) {
    $_->add_columns(
      { key => 'count',       title => 'Number of genotypes', width => '15%', sort => 'numeric', align => 'right'  },
      { key => 'view',        title => '',                    width => '5%',  sort => 'none',    align => 'center' },
      { key => 'Population',  title => 'Population',          width => '25%', sort => 'html'                       },
      { key => 'Description', title => 'Description',         width => '55%', sort => 'html'                       },
    );
  }
  
my $id=0;
$html .= qq{
<script type="text/javascript">
<!--
function switchMenu(obj) {
var el = document.getElementById(obj);
var moreless = document.getElementById("moreless");
if ( el.style.display != "none" ) {
el.style.display = 'none';
moreless.innerHTML = '..more';
}
else {
el.style.display = '';
moreless.innerHTML = '..less';
}
}
//-->
</script>
};

  my $more_desc;

  foreach my $pop (sort keys %$all_pops) {
    my $row_count   = scalar @{$rows->{$pop}};
    my $pop_name    = $all_pops->{$pop} || 'Other individuals';
    my $description = $descriptions{$pop} || '';
    my $full_desc   = $self->strip_HTML($description);
    
    if (length $description > 75 && $self->html_format) {
      while ($description =~ m/^.{75}.*?(\s|\,|\.)/g) {
        $description = substr($description, 0, (pos $description) - 1) ;
        $more_desc = substr($full_desc, length $description) || '';

        last;
      }
    }
    
    my $table;
    
    
    if ($pop_name =~ /cshl-hapmap/i) {        
      $table = $hm_table;
    } elsif($pop_name =~ /1000genomes/i) {        
      $table = $tg_table;
    } else {
      $table = $od_table;
      $other_row_count++;
    }
   
    my $show_more = qq{<a onclick="switchMenu('toggle$id');" id="moreless" style="cursor:pointer">..more</a><br><div id="toggle$id" style="display: none;">$more_desc</div>} if $more_desc; 
    $table->add_row({
      Population  => $pop_name,
      Description => qq{<span title="$full_desc">$description</span>}.$show_more,
      count       => $row_count,
      view        => $self->ajax_add($self->ajax_url(undef, { pop => $pop, update_panel => 1 }), $pop),
    });
    $id++;
  }    

  $html .= qq{<a id="$self->{'id'}_top"></a>};
  
  if ($tg_table->has_rows) {
    $tg_table->add_option('id', '1000genomes_table');
    $html .= '<h2>1000 Genomes</h2>' . $tg_table->render;      
  }
  
  if ($hm_table->has_rows) {
    $hm_table->add_option('id', 'hapmap_table');
    $html .= '<h2>HapMap</h2>' . $hm_table->render;
  }
  
  if ($od_table->has_rows && ($hm_table->has_rows || $tg_table->has_rows)) {
    if ($self->html_format) {
      $html .= $self->toggleable_table("Other populations ($other_row_count)", 'other', $od_table, 1);
    } else {
      $html .= '<h2>Other populations</h2>' . $od_table->render;
    }
  } else {     
    $html .= '<h2>Summary of genotypes by population</h2>' . $od_table->render;
  }
  
  # Other individuals table
  if ($rows->{'other_ind'}) {
    my $ind_count = scalar @{$rows->{'other_ind'}};
    
    $html .= $self->toggleable_table(
      "Other individuals ($ind_count)",'other_ind', 
      $self->new_table($ind_columns, $rows->{'other_ind'}, { data_table => 1, sorting => [ 'Individual asc' ] }), 
      0,
      qq{<span style="float:right"><a href="#$self->{'id'}_top">[back to top]</a></span><br />}
    );
  }
  
  return $html;
}

1;

