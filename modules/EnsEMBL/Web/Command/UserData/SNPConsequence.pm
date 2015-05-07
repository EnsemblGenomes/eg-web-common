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

package EnsEMBL::Web::Command::UserData::SNPConsequence;

sub process {
  my $self   = shift;
  my $object = $self->object;
  my $hub    = $self->hub;
  my $species_defs = $hub->species_defs;
  my $session      = $hub->session;
  my $url    = $object->species_path($object->data_species) . '/UserData/SelectOutput';

  my @files  = ($hub->param('convert_file'));
  my $size_limit =  $hub->param('variation_limit');
  my $species    = $hub->param('species') || $hub->species;
  my @temp_files;
  my $output;

  my $param  = {
    _time    => $hub->param('_time') || '',
    species  => $species,
    consequence_mapper  => $hub->param('consequence_mapper') || 0,
    __clear             => 1,
  };
 
  my $formats = { 'snp' => 'Ensembl default' , 'vep_vcf' => 'VCF', 'pileup' => 'Pileup' };
  my $fileformat = $hub->param('format') && exists $formats->{$hub->param('format')} ? " '" . $formats->{$hub->param('format')} . "'" : "";

  my $mismatch_flag = 0; 

  foreach my $file_name (@files) {
    next unless $file_name;
    my ($file, $name) = split ':', $file_name;

    my ($results, $nearest, $file_count);
    eval { ($results, $nearest, $file_count) = $object->calculate_consequence_data($file, $size_limit); };

    if (ref($results) ne 'HASH') {
      $mismatch_flag = "The uploaded file doesn't match the selected Input file format".$fileformat.". See <a target=_blank href='/info/docs/variation/vep/index.html'>here</a> for more details.";
      next;
    }
    my $table = $object->consequence_table($results);

    # Output new data to temp file
    my $temp_file = new EnsEMBL::Web::TmpFile::Text(
      extension    => 'txt',
      prefix       => 'user_upload',
      content_type => 'text/plain; charset=utf-8',
    );
    
    $temp_file->print($table->render_Text);
    
    push @temp_files, $temp_file->filename . ':' . $name;
 
    ## Resave this file location to the session
    my ($type, $code) = split '_', $file, 2;
    my $session_data  = $session->get_data(type => $type, code => $code);

    $session_data->{'filename'} = $temp_file->filename;
    $session_data->{'filesize'} = length $temp_file->content;
    $session_data->{'filetype'} = 'Variant Effect Predictor';
    $session_data->{'format'}   = 'VEP_OUTPUT';
    $session_data->{'md5'}      = $temp_file->md5;
    $session_data->{'nearest'}  = $nearest;
    $session_data->{'assembly'} = $species_defs->get_config($species, 'ASSEMBLY_NAME');
    $session_data->{'name'} = $hub->param('name') ? $hub->param('name') : 'Data';
    $session_data->{'file'} = 'user_upload/'.$temp_file->filename;
    $session_data->{'no_attach'} = 0;


    $session->set_data(%$session_data);

    $param->{'code'} = $code;
    $param->{'count'} = $file_count;
    $param->{'size_limit'} = $size_limit;
  }

  if ($mismatch_flag) {
      $hub->session->add_data(
          'type'  => 'message',
          'code'  => 'Variation map',
          'message' => $mismatch_flag,
          function => '_error');
                                                                                                                                                                                 
      $url    = $object->species_path($object->data_species) . '/UserData/UploadVariations';       

  } else {
    $param->{'convert_file'} = \@temp_files;
    $url = $self->url($url, $param);
  }

  $self->ajax_redirect($url);
}

1;

