=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::ViewNav;

use strict;

## ENSEMBL-4620 / ENSEMBL-4718 polyploid view currently disabled
 sub content {
   my $self        = shift;
   my $hub         = $self->hub;
   my $image_width = $self->image_width . 'px';
   my $r           = $hub->create_padded_region()->{'r'} || $hub->param('r');
   my $url         = $hub->url({'type' => 'Location', 'action' => 'View', 'r' => $r});

 ## EG  
   my $polyploid_link = '';
   if ($hub->species_defs->POLYPLOIDY) {
     $polyploid_link = sprintf(
       '<p><a href="%s">View genomic alignments of all homoeologues</a></p>', 
       $hub->url({'type' => 'Location', 'action' => 'MultiPolyploid'})
     );
   }

   my $annotation_link = '';
   if (my $annotation_url = $hub->species_defs->ANNOTATION_URL) {
     my $object = $self->object;
     my ($sr, $start, $end) = ($object->seq_region_name, $object->seq_region_start, $object->seq_region_end);
     $annotation_url =~ s/###SEQ_REGION###/$sr/;
     $annotation_url =~ s/###START###/$start/;
     $annotation_url =~ s/###END###/$end/;
   
     $annotation_link = sprintf(
       '<br /><a href="%s"><img src="/i/48/webapollo.png" title="Go to WebApollo to curate gene models" style="border:1px solid #ccc;margin:5px 8px 0px 8px;vertical-align:middle" /></a>
       Go to <a href="%s">WebApollo</a> to curate gene models (community annotation)', 
       $annotation_url,
       $annotation_url
     );
   }

   return qq{
       <div class="navbar print_hide" style="width:$image_width">
         <a href="$url"><img src="/i/48/region_thumb.png" title="Go to Region in Detail for more options" style="border:1px solid #ccc;margin:0 8px;vertical-align:middle" /></a> Go to <a href="$url" class="no-visit">Region in Detail</a> for more tracks and navigation options (e.g. zooming)
         $annotation_link
       </div>
   };
 }

1;
