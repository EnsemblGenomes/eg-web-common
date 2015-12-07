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

package EnsEMBL::Web::Command::UserData::AddFile;

## Attaches or uploads a file and does some basic checks on the format

use strict;

use List::Util qw(first);

use EnsEMBL::Web::File::AttachedFormat;
use EnsEMBL::Web::File::Utils::URL qw(chase_redirects file_exists);

sub check_for_index {
  my ($self, $url) = @_;

  my $args = {'hub' => $self->hub, 'nice' => 1};
  my $ok_url = chase_redirects($url, $args);
  my ($index_exists, $error);

  if (ref($ok_url) eq 'HASH') {
    $error = $ok_url->{'error'}[0];
  }
  else {
    my $check = file_exists($ok_url, $args);    
    if ($check->{'error'}) {
      $error = $check->{'error'}[0];
    }
    else {
      $index_exists = $check->{'success'};
    }
  }
## EG fix for ENSWEB-2126  
## Fixed in EG30(E83) see https://github.com/Ensembl/ensembl-webcode/commit/fc104087754e19f03e89f69b20baa4d691edf799

  if ($error) {
    $self->hub->session->add_data(
      type     => 'message',
      code     => 'userdata_upload',
      message  => "Your file has no tabix index, so we have attempted to upload it. If the upload fails (e.g. your file is too large), please provide a tabix index and try again.",
      function => '_info'
    );
  }

  return $index_exists;  
##
}

1;
