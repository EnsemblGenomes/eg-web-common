#!/usr/bin/env perl

use strict;
use warnings;
use DBI qw( :sql_types );
use Getopt::Long;
use Data::Dumper;

my ($rdbname, $version, $host, $port, $user, $pass);

my $create = 0;
my $create_index = 0;

# from this id the species ids from collections will start 
# they will follow this rule : $collectionOffset + collectionID * 1000
my $collectionOffset = 1000; 
my %group_objects = (
    core => {
	Exon => 1,
	Gene => 1,
	Transcript => 1,
	Translation => 1,
	Operon => 1,
#                 OperonTranscript => 1, # these are in transcript table anyway
	GeneArchive => 1,
	TranscriptArchive => 1,
	TranslationArchive => 1,
    },
# otherfeatures can be skipped for now as plant reuse the same ids in core and otherfeatures
    otherfeatures => {
	Gene => 1,
	Transcript => 1,
	Translation => 1,
    },
# not sure these are supposed to work - genetrees and families can't have species ids .. 
# in fact in eg_23_76 there are no compara ids in the stable_id_lookup
    compara => {
	GeneTree => 1, 
	Family => 1,
    }
);


GetOptions( "host|h=s" => \$host,
            "port|p=i" => \$port,
            "user|u=s" => \$user,
            "pass=s" => \$pass,
            "dbname|db=s" =>\$rdbname,
            "create!" => \$create,
            "create_index!" => \$create_index,
            "version|v=s" => \$version,
            "help" ,     \&usage,
);

usage() if (!defined $host || !defined $port || !defined $user || !defined $version); 

$rdbname ||= "ensemblgenomes_stable_ids_$version";
create_db($rdbname) if $create;

my ($dba_species, $lastSID) = get_loaded_species($rdbname);

process_dbs();

$create_index = 1 if ($create);
create_index($rdbname) if $create_index;


sub create_index {
    my $dbname = shift;
    print "Creating index for $dbname\n";

    my $startAt = time;
    eval {
	my $cmd = "mysql -h $host";
	if ($port) {
	    $cmd .= " -P $port";
	}
	$cmd .= " -u $user --password=$pass $dbname < ./sql/indices.sql";
	system($cmd) == 0 or die("error encountered when creating index for database $dbname\n");
    };
    
    if ($@) { 
	die("An SQL error occured while creating database $dbname:\n$@");
    }
    my $took = time - $startAt;
    my $s = $took % 60;
    my $m = ($took / 60) % 60;
    my $h = $took / 3600;

    warn sprintf("Indexed in %02d:%02d:%02d\n", $h, $m, $s);

    
}

sub create_db {
    my ($dbname) = @_;

    my $dbh = db_connect('test');
    print "Creating database $dbname\n";

    eval {
	
	$dbh->do("drop database if exists $dbname");
	$dbh->do("create database $dbname");
	
	my $cmd = "mysql -h $host";
	if ($port) {
	    $cmd .= " -P $port";
	}
	$cmd .= " -u $user --password=$pass $dbname < ./sql/tables.sql";
	system($cmd) == 0 or die("error encountered when creating schema for database $dbname\n");
	
	$dbh->do("use $dbname");
	
	$dbh->do("INSERT INTO meta(species_id,meta_key,meta_value) VALUES (NULL,'schema_version','$version')");
	
    };
    
    if ($@) { 
	die("An SQL error occured while creating database $dbname:\n$@");
    }

    $dbh->disconnect();
}


sub process_dbs {
    my $out = `mysql -h $host -P $port -u $user -p$pass -e 'show databases'`;

    my @dbs = split /\n/, $out;

    my $startAt = time;

    foreach my $db (@dbs) {
#    warn "$db\n";
#    if ($db =~ /([\w\_]+)_(core|otherfeatures)_([\d\_\w]+)/) { # disable otherfeatures for now as in plants core and otherfeatures might share the ids .. 
	if ($db =~ /([\w\_]+)_(core)_([\d\_\w]+)/) {
	    my ($species, $dbtype, $dbversion) = ($1, $2, $3);
	    if ($dbversion =~ /^$version/) {
		if (exists $dba_species->{$species}) {
		    if (exists $dba_species->{$species}->{ID}) {
			warn "* $species : LOADED\n";
			next;
		    }
		}
#	    warn "* $species : $dbtype ($lastSID) \n";
		if ($species =~ /\w+_(\d+)_collection/) {
		    my $cid = $1;
		    add_collection_db($db, $cid);
		} else {
		    add_species_db($db, $lastSID);
		}
	    }
	} elsif ($db =~ /([\w\_]+)_(compare)_([\d\_\w]+)/) {
	    my ($division, $dbtype, $dbversion) = ($1, $2, $3);
	    if ($dbversion =~ /^$version/) {
		add_compara_db($db);
	    }
	}

    }

    my $took = time - $startAt;
    my $s = $took % 60;
    my $m = ($took / 60) % 60;
    my $h = $took / 3600;

    warn sprintf("Loaded in %02d:%02d:%02d\n", $h, $m, $s);
}

sub add_compara_db {
    my ($dbname) = @_;
# not sure what is supposed to happen to compara IDs - they do not have species_id
    warn "- Skipping $dbname\n";
    
    

}

sub add_species_db {
    my ($dbname, $offset) = @_;
# 1 comes from species_id = 1 in meta table
    warn "- Adding species $dbname (Species ID: ", 1 + $offset, ")\n";

    if ($dbname =~ /([\w\_]+)_(core|otherfeatures)_([\d\_\w]+)/) {
	my ($species, $dbtype, $dbversion) = ($1, $2, $3);

	my $t1 = time;
	my $dba = db_connect($dbname) ;

	load_ids($dba, $dbtype, $offset);
	if ($dbtype eq 'core') {
	    load_species($dba, $offset, $dbname);
	    $lastSID++;
	}

	$dba->disconnect();

	warn "+ Loaded in ", time - $t1, "s\n";
    }
}

sub add_collection_db {
    my ($dbname, $cid) = @_;
    my $offset = $cid * 1000 + $collectionOffset;

    warn "- Adding collection $dbname (from Species ID $offset)\n";
    if ($dbname =~ /([\w\_]+)_(core|otherfeatures)_([\d\_\w]+)/) {
	my ($species, $dbtype, $dbversion) = ($1, $2, $3);

	my $t1 = time;
	my $dba = db_connect($dbname) ;

	load_ids($dba, $dbtype, $offset);
	load_species($dba, $offset, $dbname);

	$dba->disconnect();
	warn "+ Loaded in ", time - $t1, "s\n";
    }
}

# the func relies on the fact that in single species species_id = 1
sub load_species {
    my $dbh = shift;
    my $offset = shift;
    my $dbname = shift;
    my $sqlName = qq{SELECT species_id + $offset, meta_value FROM meta WHERE meta_key = "species.production_name"};
    my $sqlTaxon = qq{SELECT species_id + $offset, meta_value FROM meta WHERE meta_key = "species.taxonomy_id"};

    my $shash = {};

    my $sthN = $dbh->prepare($sqlName);
    $sthN->execute();
    while ( my ($sid, $name) = $sthN->fetchrow_array()) {
	$shash->{$sid}->{Name} = $name;
    }
    $sthN->finish();

    my $sthT = $dbh->prepare($sqlTaxon);
    $sthT->execute();
    while ( my ($sid, $taxid) = $sthT->fetchrow_array()) {
	$shash->{$sid}->{TaxID} = $taxid;
    }
    $sthT->finish();

    my @slist;
    my $insertSQL = qq{ INSERT INTO $rdbname.species (species_id, name, taxonomy_id) VALUES };
    my @tuples;

    foreach my $sid (sort keys %{$shash || {}}) {
	push(@tuples, sprintf(q{(%s, %s, %s)}, $sid, $dbh->quote($shash->{$sid}->{Name}), $dbh->quote($shash->{$sid}->{TaxID}))) ;
    }

# Add the collection as well so if restart the script it does not load this collection again
    if ($dbname =~ /([\w\_]+_collection)_(core|otherfeatures)_([\d\_\w]+)/) {
	my ($species, $t, $v) = ($1, $2, $3);
	push @tuples, sprintf(q{(%s, %s, 0)}, $offset, $dbh->quote($species)) ;
    }

    eval { 
	$dbh->do( $insertSQL . join(',', @tuples) ) ;
	if ($DBI::err) {	    
	    warn $insertSQL . join(',', @tuples) , "\n" ;
	    die "ERROR: ", $DBI::errstr;
	}
    };
}


sub load_ids {
    my $dbh = shift;
    my $dbtype = shift;
    my $offset = shift;



    my @stable_id_objects = keys %{$group_objects{$dbtype} || {}};
#    my $t = time;
    foreach my $object_name (@stable_id_objects) {
	my $object = lc($object_name);
	my $sql;
	if ($object_name =~ /([A-Za-z]+)Archive/) {
            my $object = $1;
            my $lc_object = lc($object);

            my $sql = qq(INSERT INTO $rdbname.archive_id_lookup SELECT DISTINCT old_stable_id, species_id + $offset, '$dbtype', '$object' FROM stable_id_event
                                        WHERE old_stable_id IS NOT NULL
                                          AND type = '$lc_object'
                                          AND old_stable_id NOT IN (SELECT stable_id FROM $lc_object));
# Archive IDs will not work as we dont have species_id column populated
	    next;
	} elsif ($object_name =~ /Translation/) {
	    $sql = qq{INSERT INTO $rdbname.stable_id_lookup SELECT DISTINCT o.stable_id, cs.species_id + $offset, '$dbtype', '$object_name' FROM $object o LEFT JOIN transcript t USING (transcript_id) LEFT JOIN seq_region sr USING(seq_region_id) LEFT JOIN coord_system cs USING(coord_system_id)};

	} else {
	    $sql = qq{INSERT INTO $rdbname.stable_id_lookup SELECT DISTINCT o.stable_id, cs.species_id + $offset, '$dbtype', '$object_name' FROM $object o LEFT JOIN seq_region sr USING(seq_region_id) LEFT JOIN coord_system cs USING(coord_system_id)};
	}
#	warn "\t SQL: $sql\n";
	eval {
	    $dbh->do($sql);
	    if ($DBI::err) {
		next if ($DBI::errstr =~ /Duplicate entry/);
		die "ERROR: ", $DBI::errstr;
	    }
	};
#	warn "\t $object_name ", time - $t, "s\n";
    }
}

sub get_species {
    my $dbh = shift;
    my $offset = shift;
    my $sql = qq{SELECT species_id, meta_value FROM meta WHERE meta_key = "species.production_name"};
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my ($sid, $name) = $sth->fetchrow_array()) {
	$dba_species->{$name}->{ID} = $sid + $offset;
    }
    $sth->finish();
}

sub db_connect {
    my ($dbname) = @_;

    my $dsn = "DBI:mysql:host=$host;";
    if ($port) {
	$dsn .= "port=$port;";
    }
    $dsn .= "database=$dbname";

    my $dbh = DBI->connect( $dsn, $user, $pass,
		     { 'PrintError' => 1, 'RaiseError' => 1 } );

    if (!$dbh) {
	die "ERROR: $DBI::errstr";
    }

    return $dbh;
}

sub get_loaded_species {
    my $dbname = shift;
    my $shash = {} ;
    my $ssid = 0;
    
    my $dbh = db_connect($dbname);
    my $sth = $dbh->prepare("SELECT species_id, name FROM species");
    $sth->execute();
    while ( my ($sid, $name) = $sth->fetchrow_array()) {
	$shash->{$name}->{ID} = $sid;
	if ($sid > $ssid && $sid < $collectionOffset) {
	    $ssid = $sid;
	}
    }
    $sth->finish();
    $dbh->disconnect();
    return ($shash, $ssid);
}

sub usage {
  my $indent = ' ' x length($0);
  print <<EOF; exit(0);

The script populates a stable_id lookup database with all stable ids found in databases 
on a specified server for a specified db release.
Stable ids are copied for objects listed in hash %group_objects

Options -host -port -user -pass -version are mandatory and specify the credentials for the server on which a stable id lookup database exists or is to be created (if using option -create). If an argument for option -ldbname is not provided, the default name for the database wil be used: 'ensemblgenomes_stable_id_lookup_xx', where xx is the database release (option -version).

To run the script cd into the directory where the script lives eg:
cd eg-web-common/utils/stable_id_lookup/


This command will create database ensemblgenomes_stable_ids_lookup_24_77 on server ens-staging1 for release 24 databases found on ens-staging1:

populate_stable_id_lookup.pl -host ens-staging1 -user ensadmin -port 5306 -pass xxxx -create -version 24_77


Usage:

  $0 -host host_name -port port_number -user user_name -pass password -version db_version
  $indent [-create] [-dbname database_name] 
  $indent [-help]  
  

  -h|host              Database host 

  -u|user              Database user 

  -P|port              Database port 

  -p|pass              Database password 

  -v|version           EG version to match, e.g 24_77

  -db|dbname           Database name for the stable id lookup database, e.g ensemblgenomes_stable_ids_24_77

  -create              Create the stable id lookup database using sql source ./sql/tables.sql

  -help                This message


EOF

}
