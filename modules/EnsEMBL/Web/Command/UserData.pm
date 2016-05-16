=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Command::UserData;

use strict;

## ENSWEB-2542 - backport assembly hashing fix for EG31 (will be in released in E85)
## see https://github.com/Ensembl/ensembl-webcode/commit/62b36a7a41b4ff92925be4e0e521869443ccd09d
## and https://github.com/Ensembl/ensembl-webcode/commit/bafbceee608cf145c600867e8c747a43270ac1b2
sub attach {
### Attach a remote file and return the parameters needed for a redirect
### @param attachable EnsEMBL::Web::File::AttachedFormat object
### @return array - redirect action plus hashref of parameters
  my ($self, $attachable, $filename) = @_;
  my $hub = $self->hub;

  ## For datahubs, pass assembly info so we can check if there's suitable data
  my $ensembl_assemblies = $hub->species_defs->assembly_lookup;

  my ($url, $error, $options) = $attachable->check_data($ensembl_assemblies);
  my ($redirect, $params);

  if ($error) {
    $redirect = 'SelectFile';

    $hub->session->add_data(
                        type     => 'message',
                        code     => 'AttachURL',
                        message  => $error,
                        function => '_error'
                      );
  } 
  else {
    ## This next bit is a hack - we need to implement userdata configuration properly! 
    my $extra_config_page = $attachable->extra_config_page;
    my $name              = $hub->param('name') || $options->{'name'} || $filename;
    $redirect             = $extra_config_page || 'RemoteFeedback';

    delete $options->{'name'};

    my $assemblies = $options->{'assemblies'} || [$hub->species_defs->get_config($hub->data_species, 'ASSEMBLY_VERSION')];

    my ($flag_info, $code);

    foreach (@$assemblies) {

      ## Try with and without species name, as it depends on format
      my ($current_species, $assembly, $is_old) = @{$ensembl_assemblies->{$_}
                                                    || $ensembl_assemblies->{$hub->species.'_'.$_} || []};
      


      ## This is a bit messy, but there are so many permutations!
      if ($assembly) {
        if ($current_species eq $hub->param('species')) {
          $flag_info->{'species'}{'this'} = 1;
          if ($is_old) {
            $flag_info->{'assembly'}{'this_old'} = 1;
          }
          else {
            $flag_info->{'assembly'}{'this_new'} = 1;
          }
        }
        else {
          $flag_info->{'species'}{'other'}++;
          if ($is_old) {
            $flag_info->{'assembly'}{'other_old'} = 1;
          }
          else {
            $flag_info->{'assembly'}{'other_new'} = 1;
          }
        }

        unless ($is_old) {
          my $data = $hub->session->add_data(
                                        type        => 'url',
                                        code        => join('_', md5_hex($name . $current_species . $assembly . $url), 
                                                                  $hub->session->create_session_id),
                                        url         => $url,
                                        name        => $name,
                                        format      => $attachable->name,
                                        style       => $attachable->trackline,
                                        species     => $current_species,
                                        assembly    => $assembly,
                                        timestamp   => time,
                                        %$options,
                                        );

          $hub->session->configure_user_data('url', $data);

          $code = $data->{'code'};
    
          $self->object->move_to_user(type => 'url', code => $data->{'code'}) if $hub->param('save');
        }
      }
    }   

    ## For datahubs, work out what feedback we need to give the user
    my ($species_flag, $assembly_flag);
    if ($flag_info->{'species'}{'other'} && !$flag_info->{'species'}{'this'}) {
      $species_flag = 'other_only';
    }

    if ($flag_info->{'assembly'}{'this_new'} && $flag_info->{'assembly'}{'this_old'}) {
      $assembly_flag = 'old_and_new';
    }
    elsif (!$flag_info->{'assembly'}{'this_new'} && !$flag_info->{'assembly'}{'other_new'}) {
      $assembly_flag = 'old_only';
    }

    $params = {
                format          => $attachable->name,
                name            => $name,
                species         => $hub->param('species') || $hub->species,
                species_flag    => $species_flag,
                assembly_flag   => $assembly_flag,
                code            => $code,
                };
  }

  return ($redirect, $params);
}
##

1;