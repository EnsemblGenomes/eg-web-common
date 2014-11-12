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

package ENASearch;

use strict;
use LWP::UserAgent;
use XML::Simple;
use HTTP::Cookies;
use Data::Dumper;
use EnsEMBL::Web::DBSQL::DBConnection;
use Bio::EnsEMBL::Slice;

sub new {
    my($class, $params) = @_;
    
    my $cookie_jar = HTTP::Cookies->new(
					file => "lwp_cookies.dat",
					autosave => 1,
					);
               
    my $endpoint = 'http://www.ebi.ac.uk/ena/web-service/search/services/SearchService';

    my $dbc = EnsEMBL::Web::DBSQL::DBConnection->new( undef, $params->{_species_defs} );
    my $dba;
    eval {
	my $db_info = $params->{'_species_defs'}->multidb->{DATABASE_BLAST} ||
	    die( "No blast database in MULTI" );
	$dba = $dbc->_get_database( $db_info, 'Bio::EnsEMBL::External::ENAAdaptor' );
    };

    if ($@) {
	warn "ERROR: $@";
    }

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(POST => $endpoint);
    $ua->cookie_jar($cookie_jar);
    $req->content_type('text/xml');

    my $self = bless {
	req => $req,
	ua => $ua,
	_masking => 'No_Masking',
	_splicing => 0,
	_collection_id => 30, # Ensembl Genomes
	_dba => $dba,
	_dbc => $dbc,
	}, $class;

    foreach my $p (keys %$params) {
	$self->{$p} = $params->{$p};
    }
  
    return $self;
}

# All sequences 1
# All ensembl genomes 30
# Bacteria 201
# Plants 224
# Fungi 221
# Metazoa 223
# Protists 222

sub collection :lvalue {$_[0]->{'_collection_id'}};

# No_Masking | Soft_Masking
sub masking :lvalue {$_[0]->{'_masking'}};

# 0 | 1
sub splicing :lvalue {$_[0]->{'_splicing'}};

sub _request {
    my $self = shift;
    return $self->{req};
}

sub _ua {
    my $self = shift;
    return $self->{ua};
}

my %queryType = (
		 'default' => 'gapped',
		 'dna-0' => 'gapped',
		 'dna-1' => 'est2genome',
		 'pep-0' => 'protein2dna',
		 'pep-1' => 'protein2genome',
		 );

sub submit {
    my $self = shift;
    my $seq =  shift; # dna sequnce or peptide sequence

    $seq =~ s/(\r|\n|\s)//g;

    $seq = uc($seq);
    my $nt_count = ($seq =~ tr/[ACGTN]//);
    my $acgt = $nt_count / length($seq);

    
    my $seqType = ((($acgt > 0.9) && ($seq =~ /^([AGCTNYRWSKMDVHB]+)$/)) ? 'dna-' : 'pep-').$self->splicing;

    my $masking = $self->masking;
    my $exType =  $queryType{$seqType} || $queryType{'default'};

    my $req = $self->_request;

    my $cid = $self->{_collection_id} || 30; # By default search all Ensembl Genomes
    my $soapxml = qq{
  <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <SOAP-ENV:Body>
 <ns1:SearchParameter xmlns:ns1="http://www.ebi.ac.uk/SearchService/">
                  <queryCollection>
                     <QueryCollectionId>$cid</QueryCollectionId>
                     <Name>All Sequences</Name>
                     <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
                     <OrderNumber>0</OrderNumber>
                     <ParentId>1</ParentId>
                    <Level>2</Level>
                  <FullPath>/All Sequences/Ensembl Genomes</FullPath>
                 </queryCollection>
                  <exonerateClientParameterName>$exType</exonerateClientParameterName>
                  <maskingOption>$masking</maskingOption>
                  <sequence>$seq</sequence>
               </ns1:SearchParameter>
	       </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
};
 
    $req->content($soapxml); 
    my $res = $self->_ua->request($req);
    my (@rr) = split /\?\>/, $res->as_string;
    my $xs = XML::Simple->new();
    my $ref = $xs->XMLin($rr[1]);

    my $response = $ref->{'soapenv:Body'}->{'ns1:SubmitSearchResponse'} || {};
  
    my $jobId = $response->{JobId} || return {}; 
    my $jobxml = qq{
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<SOAP-ENV:Body>
	<m:JobID xmlns:m="http://www.ebi.ac.uk/SearchService/">$jobId</m:JobID>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
};
  
    $req->content($jobxml);
    $self->{_isearch} = $response;

    $self->{_dba}->create_job($jobId);

    return $response->{JobId}; 
}


sub status {
    my $self = shift;
    my $status = $self->_status;
    my $progress = $self->_progress;
     
    my $response = $self->{_isearch};
    my $jobId = $response->{JobId} || return {}; 
    $self->{_dba}->update_state($jobId, $status, $progress);

    return $status;
}

sub _status {
    my $self = shift;

    my $req = $self->_request;

    $req->header('SOAPAction' => "http://www.ebi.ac.uk/SearchService/getSearchStatus");
    my $res = $self->_ua->request($req);  
    select(undef, undef, undef, 0.5); # Sleep for 0.25 sec
    my $str = $res->as_string;
    my $ret = "ERROR";
  
    if ($str =~ />(\w+)\<\/ns1\:SearchStatus\>/) {
	$ret = $1;
    } else {
	warn "RES : [$str]\n";
    }
    
    return $ret;
}

sub _progress {
    my $self = shift;

    my $req = $self->_request;

    $req->header('SOAPAction' => "http://www.ebi.ac.uk/SearchService/getExecutedServerCount");
    my $res = $self->_ua->request($req);  
    my $str = $res->as_string;
    my $ret = -1;
  
    if ($str =~ />(\d+)\<\/ns1\:ExecutedServerCount\>/) {
#	$ret = sprintf ("%.0f\%", $1 / $self->{_isearch}->{ServerCount} * 100);
	$ret = sprintf ("%d", $1 / $self->{_isearch}->{ServerCount} * 100);
    } else {
	warn "RES2 : [$str]\n";
    }
    return $ret;
}

sub new_alignments {
    my $self = shift;
    my $maxval = shift || 1;
    my $req = $self->_request;

    $req->header('SOAPAction' => "http://www.ebi.ac.uk/SearchService/getNewAlignments");
    my $res = $self->_ua->request($req);  
    my $str = $res->as_string;
  
    my (@rr) = split /\?\>/, $res->as_string;
    my $xs = XML::Simple->new();
    my $ref = $xs->XMLin($rr[1], 'ForceArray' => ['Alignment']);
  
    my $response = $ref->{'soapenv:Body'}->{'ns1:ArrayOfAlignments'} || {};
  
    if ($response) {
	my @result;
	foreach my $a (@{$response->{Alignment}}) {
	    next unless $a->{EValue} <= $maxval;
	    my $desc = '';
	    $desc .= sprintf(qq{Query Range: %ld - %ld <br/>}, $a->{queryStart} , $a->{queryEnd});
	    $desc .= sprintf(qq{Target Range: %ld - %ld <br/>}, $a->{targetStart} , $a->{targetEnd});
	    $desc .= sprintf(qq{Raw Score: %.02f <br/>}, $a->{RawScore});
	    $desc .= sprintf(qq{Bit Score: %.02f <br/>}, $a->{BitScore});
	    $desc .= sprintf(qq{E-Value: %.0E <br/>}, $a->{EValue});
	    $desc .= sprintf(qq{Identity: %.02f\% <br/>}, $a->{Identity});
	    $desc .= formatAlignment($a->{QueryString}, $a->{ConsensusString}, $a->{TargetString}, $a->{queryStart}, $a->{queryEnd}, $a->{targetStart}, $a->{targetEnd}, 60);
	    $a->{Description} = $desc;

	    my ($species, $region) = split(':',$a->{Accession}, 2);
	    $a->{Accession} = $region;

	    $a->{Location} = $a->{targetStart} >  $a->{targetEnd} ? sprintf("%s:%ld-%ld:-1", $a->{Accession}, $a->{targetEnd}, $a->{targetStart}) : sprintf("%s:%ld-%ld:1", $a->{Accession}, $a->{targetStart}, $a->{targetEnd});
            if ($a->{Organism} && ref $a->{Organism} ne 'HASH') {
		$a->{Species} = $a->{Organism};
		$a->{QuerySetName} = 'ena';
	    } else {

#		$a->{Species} = $self->{_species_defs}->get_config(ucfirst($a->{QuerySetName}), 'SPECIES_SCIENTIFIC_NAME') || $self->{_species_defs}->get_config($a->{QuerySetName}, 'SPECIES_SCIENTIFIC_NAME');
#		$a->{Species} ||= $a->{QuerySetName};
		$a->{Species} = $self->{_species_defs}->get_config(ucfirst($species), 'SPECIES_SCIENTIFIC_NAME') || $self->{_species_defs}->get_config($species, 'SPECIES_SCIENTIFIC_NAME')|| $species;
		$a->{QuerySetName} = $species;


	    }
	    push @result, $a;
	}

	my $jobId = $self->{_isearch}->{JobId} || return {}; 
	$self->{_dba}->store_alignments($jobId, \@result);

	return $response->{Alignment};
    }
  
    return undef;
}

sub formatAlignment{
	my ($q, $c, $t, $qstart, $qend, $tstart, $tend, $width) = @_;

	my $str = qq{<table>};

	my $tsize = ($q =~ /^([acgtACGT]+)$/) ? 1 : 3; # check if it is dna search or peptide

	my $qi = $qstart;
	my $ti = $tstart;
	my @q = unpack("(a60)*", $q);
	my @c = unpack("(a60)*", $c);
	my @t = unpack("(a60)*", $t);

	while (my $eq = shift @q) {
	  my $et = shift @t;	
	  my $t2= "$eq<br/>";
	  $t2 .= (shift @c). "<br/>";
	  $t2 .=  "$et<br/>";
	  my $qgap = ($eq =~ tr/-//);
	  my $tgap = ($et =~ tr/-//);
		my $t1 = qq{Query:$qi<br/> <br/>Sbjct:$ti<br/>};
		$ti += $width -1 -$tgap;
		$qi += $width/$tsize -1 -$qgap;
		my $t3 = qq{Query:$qi<br/> <br/>Sbjct:$ti<br/>};
		$str .= qq{<tr><td><pre>$t1</pre></td><td><pre>$t2</pre></td><td><pre>$t3</pre></td></tr>};
		$ti++;
		$qi++;
	}	
	$str .= qq{</table>};
	return $str;
}


1;

## All Sequences
#                  <queryCollection>
#                     <QueryCollectionId>1</QueryCollectionId>
#                     <Name>All Sequences</Name>
#                     <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
#                     <OrderNumber>0</OrderNumber>
#                     <ParentId>0</ParentId>
#                     <Level>1</Level>
#                     <FullPath>/All Sequences</FullPath>
#                  </queryCollection>
## All Sequences / Ensembl Genomes
#                <QueryCollection>
#                  <QueryCollectionId>30</QueryCollectionId>
#                  <Name>Ensembl Genomes</Name>
#                  <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
#                  <OrderNumber>0</OrderNumber>
#                  <ParentId>1</ParentId>
#                  <Level>2</Level>
#                  <FullPath>/All Sequences/Ensembl Genomes</FullPath>
#                  </QueryCollection>
## Bacteria
#               <QueryCollection>
#                  <QueryCollectionId>201</QueryCollectionId>
#                  <Name>Bacteria</Name>
#                  <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
#                  <OrderNumber>0</OrderNumber>
#                  <ParentId>30</ParentId>
#                  <Level>3</Level>
#                  <FullPath>/All Sequences/Ensembl Genomes/Bacteria</FullPath>
#               </QueryCollection>
## Fungi               <QueryCollection>
#                  <QueryCollectionId>221</QueryCollectionId>
#                  <Name>Fungi</Name>
#                  <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
#                  <OrderNumber>0</OrderNumber>
#                  <ParentId>30</ParentId>
#                  <Level>3</Level>
#                  <FullPath>/All Sequences/Ensembl Genomes/Fungi</FullPath>
#               </QueryCollection>
## Metazoa               <QueryCollection>
#                  <QueryCollectionId>223</QueryCollectionId>
#                  <Name>Metazoa</Name>
#                  <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
#                  <OrderNumber>0</OrderNumber>
#                  <ParentId>30</ParentId>
#                  <Level>3</Level>
#                  <FullPath>/All Sequences/Ensembl Genomes/Metazoa</FullPath>
#               </QueryCollection>
##Plants               <QueryCollection>
#                  <QueryCollectionId>224</QueryCollectionId>
#                  <Name>Plants</Name>
#                  <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
#                 <OrderNumber>0</OrderNumber>
#                  <ParentId>30</ParentId>
#                  <Level>3</Level>
#                  <FullPath>/All Sequences/Ensembl Genomes/Plants</FullPath>
#               </QueryCollection>
## Protists               <QueryCollection>
#                  <QueryCollectionId>222</QueryCollectionId>
#                  <Name>Protists</Name>
#                  <Description xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="1" />
#                  <OrderNumber>0</OrderNumber>
#                  <ParentId>30</ParentId>
#                  <Level>3</Level>
#                  <FullPath>/All Sequences/Ensembl Genomes/Protists</FullPath>
#               </QueryCollection>
