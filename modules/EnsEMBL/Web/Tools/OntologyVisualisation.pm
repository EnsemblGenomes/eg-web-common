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

package EnsEMBL::Web::Tools::OntologyVisualisation;

use Data::Dumper;
use strict;

sub highlight_subsets{
    my $self=shift;
    my ($hss) = @_;
    $self->{_highlight_subsets}= $hss if ($hss);
    return $self->{_highlight_subsets} || {};
}

sub colours {
    my $self=shift;
    my ($cmap) = @_;
    $self->{_colours}= $cmap if ($cmap);
    return $self->{_colours} || {};
}

sub node_links {
    my $self=shift;
    my ($links) = @_;
    $self->{_links}= $links if ($links);
    return $self->{_links} || {};
}

sub node_title {
    my ($self, $id) = @_;
    return $id;
}

sub get_url{
  return '#'; # the link is handled by the Ontology JS panel
}

sub ontology_legend {
    my ($self, $hss) = @_;

    my $oMap = $self->highlight_subsets;

    my $html = qq(
<div>
<style>
.term-wrapper {
  border-radius:20px;
  padding:5px;
  border:2px solid lightgrey;
  padding-bottom:5px;
}

.term-span {
  margin:0;
  padding:0;
  position:relative;
  float:right;
  width:15px;
  height:10px;
}

.term-color {
    text-align:right;
  padding:0 20px 0 0;
}

.term-table {
  width:100%;
  padding:0 0 0 0;
  margin:0 0 0 0;
}

.term-key {
    text-align:center;
}
</style>

<table style= "white-space:nowrap">
<tr><th>Terms:</th></tr>
<tr><td nowrap="nowrap" style="padding:2px 2px 2px 10px;">
<div class="term-wrapper" style="background-color:lightblue">

<table style="width:100%" cellpadding="0" cellspacing="0">
<tr><td class="term-key">Annotated terms</td></td>
</table>
</div>

</td></tr>
    );
    
    if (@{$hss||[]}){
	foreach my $ss (@$hss) {
	    $html .= sprintf(        
' <tr><td style="font-size:50%;"><span style="height:3px">&nbsp;</span></td></tr>
<tr><td nowrap="nowrap" style="padding:2px 2px 2px 10px">
<div class="term-wrapper">

<table style="width:100%" cellpadding="0" cellspacing="0">
<tr><td class="term-key">%s terms</td></td>
<tr><td class="term-color"><div class="term-span" style="background-color:%s;">&nbsp;</div></td></tr>
</table>

</div>
</td>
</tr>',
				     $oMap->{$ss}->{label} || $ss, $oMap->{$ss}->{color});
	}
    }

  my $cmap = $self->colours;
    
  $html .= qq{<tr><th >Relations:</th></tr>};
  foreach my $rel (sort keys %{$cmap->{relations}||{}}) {
    $html .= sprintf(qq{ <tr><td><span style="color:%s;font-size:120%">&uarr; &nbsp;</span> %s </td></tr> }, $cmap->{relations}->{$rel}, $rel);
}
  $html .= qq{</table>
</div>
		};

    return $html;
}

sub render{
  my $self=shift;
  # EG: a selected accession is passed as a param; only the cluster which contains a term with this accession will be displayed
  my $chart = shift;
  my $root = shift;
  my $anc = shift;
  
  my $width = shift || 800;
  my $height = 500;
  # EG

  my $gwidth = $width;
  my $gheight = $height;

  my $fname = $self->create_json($chart, $root);


  my $html = qq{
 
    <script type="text/javascript" src="$fname"></script>    

<div id="dialog" class="window">
    <table id="dcontent" style="width:100%" cellpadding="0" cellspacing="0">
      <tr class="htitle"><td style="width:90%;vertical-align:bottom;"><b><span id="nodetitle">.</span></b></td>          
          <td style="width:20px;text-align:right;padding-top:5px"><span class="close"> <img src="/i/close.png" alt="Close" id="hideMenuDialog"/> </span></td>
      </tr>
    </table>
    <hr/>
    <span id="nodenote">  </span>    
</div>    

  };

  my $dhtml = $self->create_dot( $chart, $root, $gwidth );
  return $html.$dhtml;
}

sub create_dot{
  my ($self, $chart, $root, $gwidth) = @_;
#  warn Dumper $chart;

  my $dot = new EnsEMBL::Web::TmpFile::Text( extenstion => 'dot', $self->{'species_defs'} );  
#  warn "Creating DOT file in $dot->{full_path} \n";

  my $cmap = $self->colours;
#  warn Dumper $cmap;
  
  print $dot "digraph G {
  node [shape=record, style=\"rounded,filled\", margin=\"0.05,0.05\", width=0.02, height=0.02, fontsize=10, fillcolor=transparent, fontname=Arial];
  edge [dir=back, arrowsize=0.5, concentrate=true];
  ratio = compressed;
  ranksep = 0.15;
  nodesep = 0.1;
";

  my @terms = keys %{$chart||{}};

  my $edges;
  my $nodes;

  my $hss = $self->highlight_subsets;

  foreach my $tid (@terms) {
    my $term = $chart->{$tid};
  
    if ($term->{id}) {
      my $tid = $term->{id};
    
      my $def = $term->{def};    
      $def =~ s/\"//;
      $def =~ s/\".+//;
      my $source = '';
      if ($term->{def} =~ /\[([^\]]+)\]/) {      
        $source = qq{, src: "$1"};
      }
    
      my $subsets = $term->{subsets} ? qq{, ss:"$term->{subsets}"} :  '';
    
 #   warn "SS:$subsets\n";
    
      my @name = split /\s|\_|\:|-|\/|\\/, $term->{name};
      my $label= shift @name;
      my $h = 1;
      my $pn = $label;
      foreach my $n (@name){
        my $tmp = "$pn $n";
        if (length($tmp) > 20) {
          $label .= '\n'.$n;
          $pn = $n;
          $h++;
        } else {
          $pn = $tmp;
          $label .= " $n";
        }
      }
      my $ntype = $term->{selected} ? ", t: 2" : '';
      my $htype = $h > 2 ? ", h: $h" : '';
    
      my $notes = '';


      my @na;
      if (my @notes = @{$term->{notes}||[]}) {
      foreach my $note (@notes) {
        my ($k, $v) = @$note;
        $v = uri_escape($v);
        push @na, "$k=$v";        
      }      
      }
     
      if (@na) {
        $notes .= qq{, note: "}. (join '#', @na).qq{" };      
      }
#      my $line = sprintf $node_tmpl, $tid, $label, $def, $htype, $ntype, $source, $subsets, $notes;

      my $f = 0;
      if ($term->{subsets}) {
	  my @sss;
	  foreach my $ss (keys %$hss) {
	      if ( $term->{subsets}->{$ss}) {
		  push @sss, $hss->{$ss}->{color} || 'yellow';
		  $hss->{$ss}->{count} += 1;
	      }
	  }
	  if (@sss) {
	      push @{$nodes->{subset}}, [ $tid, $label, $term->{selected} ? 1 : 0, \@sss ];
	      $f = 1;
	  }
      }

      push @{$nodes->{common}}, [ $tid, $label, $term->{selected} ? 1 : 0 ] unless $f;


#     print G sprintf("%s [label=\"%s\"];\n", $tid, $label);


     if (my @rel = @{$term->{rels}||[]}){
       foreach my $r (grep {$_} @rel) {
        $r =~ s/\!.+//;
        my ($link, $tgt) = split /\s/, $r;
        $tgt =~ s/\s//g;
        my $src = $term->{id};
	$src =~ s/^.+\://;
	$tgt =~ s/^.+\://;
	push @{$edges->{$link}}, [$tgt, $src];
      }
    }
    }
  }

  print $dot sprintf(" node [color=%s];\n", $cmap->{'border'});

  foreach my $e (@{$nodes->{'common'} || []}) {
    (my $tid = $e->[0]) =~ s/^.+\://;

#    print $dot sprintf("%s [tooltip=\"%s\",label=\"%s\",URL=\"javascript:nodeMenu(\'%s\')\"%s];\n", $tid, $e->[0], $e->[1], $e->[0], $e->[2] ? ',fillcolor=lightblue' : '');

    print $dot sprintf("%s [tooltip=\"%s\",label=\"%s\",URL=\"%s\"%s];\n", $tid, $self->node_title($e->[0]), $e->[1], $self->get_url($e->[0]), $e->[2] ? ',fillcolor=lightblue' : '');
  }

  foreach my $e (@{$nodes->{'subset'} || []}) {
    (my $tid = $e->[0]) =~ s/^.+\://;
    my $sshtml = '';
    foreach my $ss (@{$e->[3] ||[]}) {
	$sshtml .= qq{<td align=\"right\" fixedsize=\"true\" height=\"5px\" width=\"5px\" bgcolor=\"$ss\"> </td>\n};
    }
    (my $label = $e->[1]) =~ s/\\n/\<br\/\>/g;
    print $dot sprintf("%s [tooltip=\"%s\",label=<
<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">
<tr>
<td colspan=\"10\">
%s
</td></tr>
<tr>
<td> </td>
<td> </td>
<td>
<table border=\"0\"><tr>
$sshtml
</tr>
</table>
</td>
</tr>
</table>
>,URL=\"%s\"%s];\n", $tid, $self->node_title($e->[0]), $label, $self->get_url($e->[0]), $e->[2] ? (',fillcolor='.$cmap->{selected_node}) : '');
  }


  foreach my $linktype (keys %$edges) {
     print $dot sprintf(" edge [color=%s,tooltip=\"%s\"];\n", $cmap->{'relations'}->{$linktype} || 'red', $linktype);
     foreach my $e (reverse @{$edges->{$linktype} || []}) {
         print $dot sprintf("  %s -> %s;\n", $e->[0], $e->[1]);
     }
  }

  print $dot "\n}";
  $dot->save;


  my $image = new EnsEMBL::Web::TmpFile::Image( $self->{'species_defs'} );
  $image->save();

  my $ofile = $image->{full_path};
  my $cmd = "dot -Tpng $dot->{full_path} -o $ofile 2> /dev/null"; # create the file and do not log the warnings
  `$cmd`;

  my $imgsrc = $image->URL; 
  my $cmd = "dot -Tcmap $dot->{full_path} 2> /dev/null"; # create the file and do not log the warnings
  my $imap = `$cmd`;


  my @hss = grep { $hss->{$_}->{count} } keys %$hss;

  my $lhtml = $self->ontology_legend(\@hss);
#  warn $imap;

  my $phtml = qq(
<table width="100%">
<tr>
 <td style="width:200px">
    $lhtml
 </td>
<td>
 <div style="width:100%; text-align:center;">
 <img  id="oimage" usemap="#mapOntology" src="${imgsrc}" />
 <map id="mapOntology" name="mapOntology">
$imap
</map>
 </div>
</td>
</tr>
</table>
		 ); 
#  warn "HTML: $phtml \n";
#    my $iw = $image->width;
#    my $ih = $image->height;

#    warn "$_ : $iw * $ih \n";

  return $phtml;
}


sub create_json{
  my $self = shift;
  
  my $chart = shift;
  my $root = shift;

  my $jsfile = new EnsEMBL::Web::TmpFile::Text( extension => 'js', $self->{'species_defs'} );  
  
#  warn "Creating json file in $jsfile->{full_path} \n";

  

  my $extlinks = $self->node_links;    
#  warn Dumper "E2", Dumper $extlinks;

  print $jsfile '
var ontology_settings = {
  extlinks: [
  ';
  
  foreach my $txt (keys %{$extlinks || {}}) {
    print $jsfile '
          { name : "'.$txt.'",  
            link : "'.$extlinks->{$txt}.'"
          },'
    ;
  }
  
 print $jsfile '
  ]
};  
  ';
  
  print $jsfile '
var ontology_data = {
';
        	
  my $node_tmpl = '"%s":{ name: "%s", def: "%s" %s %s %s %s %s %s %s},'; 

  my @terms = grep {$_ ne $root} sort keys %{$chart||{}};
  unshift @terms, $root;

  foreach my $tid (@terms) {
    my $term = $chart->{$tid};
    
  if ($term->{id}) {
    my $tid = $term->{id};
    
    my $def = $term->{def};    
    $def =~ s/\"//;
    $def =~ s/\".+//;
    my $source = '';
    if ($term->{def} =~ /\[([^\]]+)\]/) {      
      $source = qq{, src: "$1"};
#      warn "SRC:$source\n";
    }
    
    
   my $subsets = $term->{subsets} ? (qq{, ss:"}. (join  ', ', sort keys %{$term->{subsets}}).qq{"}) :  '';
# my $subsets = '';   
 #   warn "SS:$subsets\n";
    
    my @name = split /\s|\_/, $term->{name};
    my $label= shift @name;
    my $h = 1;
    my $pn = $label;
    foreach my $n (@name){
      my $tmp = "$pn $n";
      if (length($tmp) > 15) {
        $label .= '\n'.$n;
        $pn = $n;
        $h++;
      } else {
        $pn = $tmp;
        $label .= " $n";
      }
    }
    my $ntype = $term->{selected} ? ", t: 2" : '';
    my $htype = $h > 2 ? ", h: $h" : '';
    
    my $notes = '';


    my @na;
    if (my @notes = @{$term->{notes}||[]}) {
      foreach my $note (@notes) {
        my ($k, $v) = @$note;
        $v = uri_escape($v);
        push @na, "$k=$v";        
      }      
    }
    
    
    if (@na) {
      $notes .= qq{, note: "}. (join '#', @na).qq{" };      
    }

    my $extensions = '';
    if (my @exts = @{$term->{extensions} || []}) {      
	my @extjs = ();
	foreach my $e (@exts) {
#	    push @extjs, sprintf ("%s;%s;%s", uri_escape($e->{description}), $e->{evidence}, uri_escape($e->{source}));
	    push @extjs, sprintf ("%s", uri_escape($e->{description}));
	}
	$extensions = qq{, ext: "} . (join '#', @extjs).qq{" };      
#	warn "EXT:$extensions\n";
    }


    my $line = sprintf $node_tmpl, $tid, $label, $def, $htype, $ntype, $source, $subsets, $notes, $extensions;
    
    print $jsfile "$line\n";
  }
}
  
print $jsfile ' 
    
 };
';

  $jsfile->save;
  return $jsfile->URL;
}


1;
