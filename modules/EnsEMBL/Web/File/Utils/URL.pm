package EnsEMBL::Web::File::Utils::URL;


sub get_headers {
### Get one or all headers from a remote file 
### @param url - URL of file
### @param Args Hashref 
###         header (optional) String - name of header
###         hub EnsEMBL::Web::Hub
###         nice (optional) Boolean - see introduction
###         compression String (optional) - compression type
### @return Hashref containing results (single header or hashref of headers) or errors (ArrayRef)
  my ($file, $args) = @_;
  my $url = ref($file) ? $file->absolute_read_path : $file;
  my ($all_headers, $result, $error);

  if ($url =~ /^ftp/) {
    ## TODO - support FTP properly!
    return {'Content-Type' => 1};
  }
  else {
    my %params = ('timeout'       => 10);
    if ($args->{'hub'}->species_defs->ENSEMBL_WWW_PROXY) {
      $params{'proxy'} = $args->{'hub'}->species_defs->ENSEMBL_WWW_PROXY;
    }
    my $http = HTTP::Tiny->new(%params);

    my $response = $http->request('HEAD', $url);
    if ($response->{'success'}) {
      $all_headers = $response->{'headers'};
    }
    else {
      $error = _get_http_tiny_error($response);
    }
  }

  $result = $args->{'header'} ? $all_headers->{$args->{'header'}} : $all_headers;

  if ($args->{'nice'}) {
    return $error ? {'error' => [$error]} : {'headers' => $result};
  }
  else {
    if ($error) {
      throw exception('URLException', "Could not get headers.") unless $args->{'no_exception'};
      return 0;
    }
    else {
      return $result;
    }
  }
}

1;
