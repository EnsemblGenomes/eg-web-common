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

package EBeyeSearch::EBeyeWSWrapper;

use strict;
use Data::Dumper;
use SOAP::Lite;
use Scalar::Util qw(reftype);
use Carp qw(cluck);
use English;
use EnsEMBL::Web::SpeciesDefs;
our  $SPECIES_DEFS = EnsEMBL::Web::SpeciesDefs->new();
#use base qw( EnsEMBL::Web::Proxiable );
use Data::Dumper;


sub new {
    my ($class, $args) = @_;
    my  $self  = {};

    bless $self, $class;

    $args->{namespace} ||= 'http://www.ebi.ac.uk/EBISearchService';

#       $args->{endpoint} ||=  'http://ashdev-2.ebi.ac.uk:8888/ebisearch/service.ebi';
#       $args->{endpoint} ||=  'http://ash-10.ebi.ac.uk:8903/ebisearch/service.ebi';

    my $endpoint;

    if ($args->{endpoint}) {
	$endpoint = $args->{endpoint};
    } else {
	$endpoint = $SPECIES_DEFS->EBEYE_ENDPOINT;
    }


    die "[SOAP ENDPOINT NOT SET]" unless $endpoint;

    my $soap_connect = SOAP::Lite->proxy(
		  $endpoint,
		  timeout => 6000,    # HTTP connection timeout
		)->uri($args->{namespace})->on_fault(sub { 
      my($soap, $res) = @_; 
	    die ref $res ? join "\n", "--- SOAP FAULT ---", $res->faultcode, $res->faultstring, '' 
                   : join "\n", "--- TRANSPORT ERROR ---", $soap->transport->status, "Endpoint [ $args->{endpoint} ]", '';
    });

    $soap_connect->transport->agent("EBI-Sample-Client/1346 ('ebeye_soaplite.pl'; $OSNAME) " . $soap_connect->transport->agent());

    $self->WSproxy($soap_connect);
    $self->namespace($args->{namespace});
      #  warn Dumper $self;

    return $self;
}

sub _getRefToArrayOfStringArray {
    my ($self,$refWsValue, $sizeChunk) = @_;
    my @arrayOfArrays;
    while (my @chunk = splice (@$refWsValue, 0, $sizeChunk)  ) {
 	push @arrayOfArrays, \@chunk;
    }
    return \@arrayOfArrays;
}

# sub _getRefToHashOfString {
      #     my ($self, $refWsValue, $key) =@_;
#     die dump 

# }

# sub WSproxy :lvalue {
#   $_[0]->{'WSproxy'};
# }


sub WSproxy {
    my ($self, $arg) = @_;
    (defined $arg) && 
      ($self->{_proxy} = $arg);
    return $self->{_proxy};
}

sub namespace {
    my ($self, $arg) = @_;
    (defined $arg) && 
      ($self->{_namespace} = $arg);
    return $self->{_namespace};
}



=head2 listDomains
	Returns a list of all the domain identifiers which can be used in a query.
	Parameters: /	
	Return:     List of domain identifiers (strings).
=cut

sub listDomains() {
	my ($self) = @_;
	
	my $result = $self->WSproxy->listDomains();
	return $result->valueof('///arrayOfDomainNames/string');
}


=head2 getNumberOfResults
	Executes a query and returns the number of results found. 
	Parameters:
		domain (string) The id of the domain to search into (must be one of the 
			                domains returned by the listDomains() method)
		query (string)  The terms to look for.
	Return:
		Number of results (int).

=cut

sub getNumberOfResults{ 
	my ($self, $domain, $query) = @_;

	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->getNumberOfResults( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ), 
	                                     SOAP::Data->name( 'query' => $query )->attr( { 'xmlns' => $serviceNamespace } ) );



	return $result->valueof('//numberOfResults');
}

=head2 getResultsIds
	Executes a query and returns the list of identifiers for the entries found.
	Parameters:
		domain (string) The id of the domain to search into (must be one of the 
		                domains returned by the listDomains() method).
		query (string)  The terms to look for.
		start (int)     The index of the first entry in the results list to be returned.
		size  (int)     The number of entries to be returned (limit: 100).
	Return:
		List of identifiers (strings).
=cut	

sub getResultsIds {
	my ($self, $domain, $query, $start, $size) = @_;
	my $serviceNamespace =  $self->namespace;

	my $result = $self->WSproxy->getResultsIds( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ),
					SOAP::Data->name( 'query' => $query )->attr( { 'xmlns' => $serviceNamespace } ),
					SOAP::Data->name( 'start' => $start )->attr( { 'xmlns' => $serviceNamespace } ),
					SOAP::Data->name( 'size' => $size )->attr( { 'xmlns' => $serviceNamespace } ) );
	#my $result = $self->WSproxy->getResultsIds($domain, $query, $start, $size);

	return $result->valueof('//arrayOfIds/string');
}

=head2 getAllResultsIds
	Executes a query and returns the list of all the identifiers for the entries found.
	Parameters:
		domain (string) The id of the domain to search into (must be one of the domains
		                returned by the listDomains() method).
		query (string)  The terms to look for.
	Return:
		List of identifiers (strings).
=cut
sub getAllResultsIds {
	my ($self, $domain, $query) = @_;
	my $serviceNamespace = $self->namespace;

	my $results = $self->WSproxy->getAllResultsIds( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ), 
								       SOAP::Data->name( 'query' => $query )->attr( { 'xmlns' => $serviceNamespace } ) );


	return $results->valueof('//arrayOfIds/string');


}

=head2 listFields
	Returns the list of fields that can be retrieved for a particular domain.
	Parameters:
		domain (string) The domain identifier (must be one of the domains returned 
			             by the listDomains() method).
	Return:
		List of fields (strings)
=cut

sub listFields {
	my ($self, $domain) = @_;
	my $serviceNamespace = $self->namespace;
	my $results = $self->WSproxy->listFields( SOAP::Data->name( 'domain' => $domain)->attr( { 'xmlns' => $serviceNamespace } ) );
	return $results->valueof('//arrayOfFieldNames/string');


}


=head2 getResults
	Executes a query and returns a list of results. Each result contains the
	values for each field specified in the 'fields' argument in the same order
	as they appear in the 'fields' list.

	Parameters:
		domain (string) The id of the domain to search into (must be one of the domains
		                returned by the listDomains() method).
		query (string)  The terms to look for.
		fields (Reference to an array of strings) A list of fields which data will be included in the results
		start (int)     The index of the first entry in the results list to be returned
		size (int)      The number of entries to be returned (limit: 100).
	Return:
		A ref. to an array of arrays of strings (['field1', 'field2', ...], ['field1', 'field2', ...], ...) 
=cut
sub getResults {
	my ($self, $domain, $query, $fields, $start, $size) = @_;

	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->getResults( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ), 
								 SOAP::Data->name( 'query' => $query )->attr( { 'xmlns' => $serviceNamespace } ),
								 SOAP::Data->name( 'fields' => \SOAP::Data->value(soap_to_arrayOfString( $fields ) ) )->attr( { 'xmlns' => $serviceNamespace } ),
								 SOAP::Data->name( 'start' => $start)->attr( { 'xmlns' => $serviceNamespace } ),
								 SOAP::Data->name( 'size' => $size)->attr( { 'xmlns' => $serviceNamespace } ) );





# 	my $wsResult = $self->WSproxy->getResults($domain, $query, $fields, $start, $size);

	my @wsValue = $result->valueof('//arrayOfEntryValues/ArrayOfString/string');
        return $self->_getRefToArrayOfStringArray(\@wsValue, scalar(@$fields));

}

sub soap_to_arrayOfString {
	my ( $items ) = @_;

	my (@stringArray) = ();
	foreach my $item (@$items) {
		push ( @stringArray, SOAP::Data->type( 'string' => $item)->name('string') );
	}
	return @stringArray;
}



sub getResultsAsHashArray {
	my ($self, $domain, $query, $fields, $start, $size) = @_;

	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->getResults( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ), 
								 SOAP::Data->name( 'query' => $query )->attr( { 'xmlns' => $serviceNamespace } ),
								 SOAP::Data->name( 'fields' => \SOAP::Data->value(soap_to_arrayOfString( $fields ) ) )->attr( { 'xmlns' => $serviceNamespace } ),
								 SOAP::Data->name( 'start' => $start)->attr( { 'xmlns' => $serviceNamespace } ),
								 SOAP::Data->name( 'size' => $size)->attr( { 'xmlns' => $serviceNamespace } ) );


	my @wsValue = $result->valueof('//arrayOfEntryValues/ArrayOfString');

	my $all_hits;

	foreach my $hit (@wsValue) {
	    my ($values) = values %{$hit};
	    my $hit_hash;
	    for (my $i = 0; $i< @$fields; $i++) {
		$hit_hash->{@$fields[$i]} = $values->[$i];

	    }
	    push @$all_hits, $hit_hash;

	}
	return $all_hits;
}


=head2 getEntry
	Search for a particular entry in a domain and returns the values for some 
	of the fields of this entry. 
	The result contains the values for each field specified in the 'fields' 
	argument in the same order as they appear in the 'fields' list.

	Parameters:
		domain (string)  The id of the domain to search into (must be one of the domains 
		                 returned by the listDomains() method).
		entry  (string)  The entry identifier.
		fields (Reference to a array of strings) A list of fields which data will be included in the results
	Return:
		list of the fields' values (strings).
=cut

sub getEntry{

	my ($self, $domain, $entry, $fields) = @_;

	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->getEntry( SOAP::Data->name( 'domain' => $domain)->attr( { 'xmlns' => $serviceNamespace } ),
							   SOAP::Data->name( 'entry' => $entry)->attr( { 'xmlns' => $serviceNamespace } ), 
							   SOAP::Data->name( 'fields' => \SOAP::Data->value(soap_to_arrayOfString( $fields ) ) )->attr( { 'xmlns' => $serviceNamespace } ) );


	return $result->valueof('//entryValues/string');
}


=head2 getEntries
	Search for entries in a domain and returns the values for some of the 
	fields of these entries. The result contains the values for each field 
	specified in the 'fields' argument in the same order as they appear in 
	the 'fields' list.
		
	Parameters:
		domain  (string)  The id of the domain to search into (must be
		                  one of the domains returned by the listDomains() method)
		entries (ref. to an array of strings) The list of entry identifiers.
		fields  (ref. to an array of string)  A list of fields which data will be included in the results.
	Return:
		A reference to an array of arrays of strings.
=cut


sub getEntries {
	my ($self, $domain, $entries, $fields) = @_;
	die "getEntries expects array ref of entries got: [$entries]" unless ref $entries eq 'ARRAY';
	die "getEntries expects array ref of fields got: [$fields]" unless ref $fields eq 'ARRAY';
	my $serviceNamespace = $self->namespace;

	my $wsResult = $self->WSproxy->getEntries( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ),
							     SOAP::Data->name( 'entries' => \SOAP::Data->value(soap_to_arrayOfString( $entries ) ) )->attr( { 'xmlns' => $serviceNamespace } ),
							     SOAP::Data->name( 'fields' => \SOAP::Data->value(soap_to_arrayOfString( $fields ) ) )->attr( { 'xmlns' => $serviceNamespace } ) );


	my @wsValue = $wsResult->valueof('//arrayOfEntryValues/ArrayOfString/string');

	return $self->_getRefToArrayOfStringArray(\@wsValue, scalar @$fields);


}


sub getDomainsReferencedInDomain{
	my($self, $domain) =@_;

	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->getDomainsReferencedInDomain( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ) );

	return $result->valueof('//arrayOfDomainNames/string');
}


=head2 getDomainsReferencedInEntry
	Returns the list of domains with entries referenced in a particular domain entry. 
	These domains are indexed in the EB-eye.
	Parameters:
		domain (string) The domain identifier (must be one of the domains returned 
		                by the listDomains() method).
		entry (string)  The entry identifier.
	Return:	
		The list of domains
=cut

sub getDomainsReferencedInEntry {
	my ($self, $domain, $entry) = @_;

	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->getDomainsReferencedInEntry( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ),
												  SOAP::Data->name( 'entry' => $entry )->attr( { 'xmlns' => $serviceNamespace } ) );

	return $result->valueof('//arrayOfDomainNames/string');
}


=head2 listAdditionalReferenceFields
	Returns the list of fields corresponding to databases referenced in the 
	domain but not included as a domain in the EB-eye.
	Parameters:
		domain (string) The domain identifier (must be one of the domains returned 
		                by the listDomains() method).
	Return:
		The list of fields
=cut
sub listAdditionalReferenceFields {
	my ($self, $domain) = @_;
	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->listAdditionalReferenceFields( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ) );
	
	return $result->valueof('///arrayOfFieldNames/string');
}


=head2 getReferencedEntries
	Returns the list of referenced entry identifiers from a domain referenced 
	in a particular domain entry.
	Parameters:
		domain (string) The domain identifier (must be one of the domains returned 
		                by the listDomains() method).
		entry (string)  The entry identifier.
		referencedDomain (string) The identifier for the domain referenced in the 
	   	                        entry (must be one of the domains returned by the 
											getDomainsReferencedInEntry(domain, entry) method).
	Return:
		The list of referenced entry identifiers.
=cut

sub getReferencedEntries {
	my ($self, $domain, $entry, $referencedDomain) = @_;

	my $serviceNamespace = $self->namespace;
	my $result = $self->WSproxy->getReferencedEntries( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ),
										   SOAP::Data->name( 'entry' => $entry )->attr( { 'xmlns' => $serviceNamespace } ),
										   SOAP::Data->name( 'referencedDomain' => $referencedDomain )->attr( { 'xmlns' => $serviceNamespace } ) );




	return $result->valueof('//arrayOfEntryIds/string');
}


 sub getDetailedNumberOfResults {
     my ($self, $domain, $query, $flat) = @_;

     $flat ||= 'true';
     my $serviceNamespace = $self->namespace;

     my $results = $self->WSproxy->getDetailledNumberOfResults( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ),
							                      SOAP::Data->name( 'query' => $query )->attr( { 'xmlns' => $serviceNamespace } ), 
							                      SOAP::Data->name( 'flat' => $flat )->type('xsi:boolean')->attr( { 'xmlns' => $serviceNamespace } ) );

     return $results->valueof('//detailledNumberOfResults/subDomainsResults/DomainResult');




}

sub getFacets {
  my ($self, $domain, $query) = @_;

  my $serviceNamespace = $self->namespace;
  my $result = $self->WSproxy->getFacets( SOAP::Data->name( 'domain' => $domain )->attr( { 'xmlns' => $serviceNamespace } ),
                                          SOAP::Data->name( 'query' => $query )->attr( { 'xmlns' => $serviceNamespace } ) );

  return $result->valueof('//arrayOfFacets/Facet');
}



######################################################################
# below are methods provide by the webservice that are currently     #
# unused by ensemblgenomes. They remain unconverted to the new syntax#
# and XPATHs required after the conversion of the EBeye webservice   #
# from XFIRE to CXF     sk. 5/Feb/2010                               #
######################################################################


# =head2 getReferencedEntriesSet
# 	Returns the list of referenced entries from a domain referenced in a set of entries. 
# 		     The result will be returned as a list of objects, each representing an entry reference.
		 
# 	Parameters:
# 		domain (string)           The domain identifier (must be one of the domains 
# 		                          returned by the listDomains() method).
# 		entries (Ref. to an array of string) The entry identifiers.
# 		referencedDomain (string) The identifier for the domain referenced in the entry
# 		                          (must be one of the domains returned by the 
# 										  getDomainsReferencedInEntry(domain, entry) method).
# 		fields (Ref to an array of strings) A list of fields which data will be included in the results.
# 	Return:
# 		A dictionary : {entryId1:[ [fields],[fields],...], entryId2:[ [fields],[fields],...]}
# =cut

# sub getReferencedEntriesSet {
# 	my ($self, $domain, $entries, $referencedDomain, $refFields) = @_;
# 	my @fieldValues = ();
# 	my $dict;
# 	my $nbFields = @$refFields;
# 	my $wsResult = $self->WSproxy->getReferencedEntriesSet($domain, $entries, $referencedDomain, $refFields);
# 	my @entries  = $wsResult->valueof('//getReferencedEntriesSetResponse/arrayOfEntryValues/EntryReferences/entry');
# 	my $i = 1;
# 	foreach my $entry (@entries) {
# 		my @fieldValues = $wsResult->valueof("//getReferencedEntriesSetResponse/arrayOfEntryValues/[$i]/references/ArrayOfString/string");
# 		$dict->{$entry} = $self->_getRefToArrayOfStringArray(\@fieldValues, $nbFields);
# 		$i++;
# 	}
# 		return $dict;	 
# }

# =head2
# 	Returns the list of referenced entries from a domain referenced in a set 
# 	of entries. The result will be returned as a flat table corresponding to
# 	the list of results where, for each result, the first value is the original 
# 	entry identifier and the other values correspond to the fields values.
# 	Parameters:
# 		domain (string)            The domain identifier (must be one of the domains 
# 		                           returned by the listDomains() method).
# 		entries (ref. to an array of strings) The entry identifiers
# 		referencedDomain (string)  The identifier for the domain referenced in the entry 
# 		                           (must be one of the domains returned by the 
# 											getDomainsReferencedInEntry(domain, entry) method).
# 		fields (ref. to anarray of strings)  A list of fields which data will be included in the results.
# 	Return:
# 		The ref. to the list of referenced entries : [ [entryId1, field1, field2, ...], [entryId2, field1, field2, ...]
# =cut

# sub getReferencedEntriesFlatSet {
# 	my ($self, $domain, $refEntries, $referencedDomain, $refFields) = @_;
# 	my $nbFields = @$refFields;
# 	my $result   = $self->WSproxy->getReferencedEntriesFlatSet($domain, $refEntries, $referencedDomain, $refFields);
# 	my @wsValue  = $result->valueof('//getReferencedEntriesFlatSetResponse/arrayOfEntryValues/ArrayOfString/string');
# 	return $self->_getRefToArrayOfStringArray(\@wsValue, $nbFields + 1);
# }



# =head2 getEntryFieldUrls
# 	Search for a particular entry in a domain and returns the urls configured 
# 	for some of the fields of this entry. The result contains the urls for each 
# 	field specified in the 'fields' argument in the same order as they appear 
# 	in the 'fields' list.		 
# 	Parameters:
# 		domain (string) The id of the domain to search into (must be one of the 
# 		                domains returned by the listDomains() method).
# 		entry (string)  The entry identifier.
# 		fields (Ref. to an array of strings) A list of fields which corresponding urls will 
# 		                                     be included in the results.
# 	Return:
# 		List of urls
# =cut

# sub getEntryFieldUrls {
# 	my ($self, $domain, $entry, $refFields) = @_;


	
# 	my $result = $self->WSproxy->getEntryFieldUrls($domain, $entry, $refFields);
# 	return $result->valueof('//getEntryFieldUrlsResponse/entryUrlsValues/string');
# }

# =head2
# 	Search for a list of entries in a domain and returns the urls configured 
# 	for some of the fields of these entries. Each result contains the url for 
# 	each field specified in the 'fields' argument in the same order as they 
# 	appear in the 'fields' list.
# 	Parameters:
# 		domain (string)            The id of the domain to search into (must be 
# 		                           one of the domains returned by the listDomains() method).
# 		entries (ref. to an array of strings) The list of entry identifiers.
# 		fields  (ref. to an array of strings) A list of fields which corresponding urls will 
# 		                           be included in the results
# 		Return:
# 			A reference to an array of arrays of strings.
# =cut

# sub getEntriesFieldUrls {
# 	my ($self, $domain, $refEntries, $refFields) = @_;
# 	my $nbFields = @$refFields;
# 	my $wsResult = $self->WSproxy->getEntriesFieldUrls($domain, $refEntries, $refFields);
	
# 	my @wsValue = $wsResult->valueof('//getEntriesFieldUrlsResponse/arrayOfEntryUrlsValues/ArrayOfString/string');
# 	return $self->_getRefToArrayOfStringArray(\@wsValue, $nbFields);
# }

# =head2
# 	Returns the list of domains with entries referenced in a particular domain.
# 	These domains are indexed in the EB-eye.
# 	Parameter:
# 		domain (string) The domain identifier (must be one of the domains returned 
# 		by the listDomains() method)
# 	Return:
# 		The list of domains
# =cut






;
