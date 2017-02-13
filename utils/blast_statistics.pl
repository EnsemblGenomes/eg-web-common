#!/usr/local/bin/perl

use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Spec;
use Getopt::Long qw(GetOptions);
use Data::Dumper;

BEGIN {

    my @dirname = File::Spec->splitdir( dirname( Cwd::realpath(__FILE__) ) );
    my $code_path = File::Spec->catdir( splice @dirname, 0, -2 );

    # Load SiteDefs
    unshift @INC, File::Spec->catdir( $code_path, qw(ensembl-webcode conf) );
    eval { require SiteDefs; };
    if ($@) {
        print "ERROR: Can't use SiteDefs - $@\n";
        exit 1;
    }

    # Include all code dirs
    unshift @INC, reverse @{SiteDefs::ENSEMBL_LIB_DIRS};
    $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;
}

use EnsEMBL::Web::SpeciesDefs;

my $sd = EnsEMBL::Web::SpeciesDefs->new();

my $db = {
    'database' => $sd->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'},
    'host'     => $sd->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
    'port'     => $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
    'username' => $sd->multidb->{'DATABASE_WEB_TOOLS'}{'USER'}
      || $sd->DATABASE_WRITE_USER,
    'password' => $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PASS'}
      || $sd->DATABASE_WRITE_PASS,
};

my $input = '';
while ( $input !~ m/^(y|n)$/i ) {
    print sprintf
"\nThis will run queries on the following DB. Continue? %s\@%s:%s\nConfirm (y/n):",
      $db->{'database'}, $db->{'host'}, $db->{'port'};
    $input = <STDIN>;
}

close STDIN;

chomp $input;

die "Script aborted.\n" if $input =~ /n/i;

my $dbh = DBI->connect(
    sprintf(
        'DBI:mysql:database=%s;host=%s;port=%s',
        $db->{'database'}, $db->{'host'}, $db->{'port'}
    ),
    $db->{'username'},
    $db->{'password'} || ''
) or die('Could not connect to the database');

get_overall_count($dbh);
get_individual_count($dbh);
get_popular_species($dbh);
get_ticket_vs_job_frequencies($dbh);

####################################################################################

sub get_overall_count {
    my ($dbh) = @_;

    my $ticket_count = $dbh->prepare(
        "select count(*) from ticket where ticket_type_name = 'Blast'");
    $ticket_count->execute;

    my $jobs_count = $dbh->prepare(
	"select count(*) from ticket inner join job on ticket.ticket_id = job.ticket_id where ticket_type_name = 'Blast'"
    );
    $jobs_count->execute;

    printf "\n\nTotal number of Blast tickets on this server are: %s\n",
      $ticket_count->fetchrow_array;
    printf "Total number of Blast jobs on this server are: %s\n\n\n",
      $jobs_count->fetchrow_array;
}

sub get_individual_count {

    my ($dbh) = @_;

    my $sth_tickets = $dbh->prepare(
	"select ticket.site_type, count(*) as count from ticket where ticket.ticket_type_name = 'Blast' group by ticket.site_type order by site_type"
    );
    $sth_tickets->execute;
    my $tickets_count = $sth_tickets->fetchall_hashref('site_type');

    my $sth_jobs = $dbh->prepare(
	"select ticket.site_type, count(*) as count from ticket inner join job on ticket.ticket_id = job.ticket_id where ticket.ticket_type_name = 'Blast' 
	group by ticket.site_type order by count"
    );
    $sth_jobs->execute;
    my $jobs_count = $sth_jobs->fetchall_hashref('site_type');

    printf( "%-20s %-20s %-20s\n", "Site type", "Tickets", "Jobs" );
    print "------------------------------------------------\n";

    foreach my $each_site ( keys %{$tickets_count} ) {
        printf(
            "%-20s %-20s %-20s\n",
            $tickets_count->{$each_site}->{'site_type'},
            $tickets_count->{$each_site}->{'count'},
            $jobs_count->{$each_site}->{'count'}
        );
    }

}

sub get_popular_species {

    my ($dbh) = @_;

    print "\n\n\n------------------------------------------------\n";
    print "Popular species in each site type\n";
    print "------------------------------------------------\n";
    my $sth_site_type = $dbh->prepare("select distinct site_type from ticket");
    $sth_site_type->execute;

    my $site_types = $sth_site_type->fetchall_arrayref( {} );

    #warn Data::Dumper::Dumper($site_types);

    foreach my $site_type (@$site_types) {

        printf "\n\nSite type: %s\n", $site_type->{'site_type'};
        print "------------------------------\n";

        my $sth_jobs = $dbh->prepare(
	"select job.species, count(*) as count from ticket inner join job on ticket.ticket_id = job.ticket_id where ticket.ticket_type_name = 'Blast' and ticket.site_type=		       ? group by job.species order by count"
        );

        $sth_jobs->bind_param( 1, $site_type->{'site_type'} );

        $sth_jobs->execute;
        my $jobs_count = $sth_jobs->fetchall_arrayref( {} );

        #warn Data::Dumper::Dumper($jobs_count);
        my $count = 1;
        foreach my $species_count ( reverse @$jobs_count ) {

            printf( "%-40s %-40s\n",
                $species_count->{'species'},
                $species_count->{'count'} );
            $count > 5 ? last : $count++;

        }
    }

}

sub get_ticket_vs_job_frequencies {

    my ($dbh) = @_;

    print "\n\n\n------------------------------------------------\n";
    print "Jobs per ticket in each site type\n";
    print "------------------------------------------------\n";
#    printf(
#        "%-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n",
#        "One", "Two",   "Three", "Four", "Five",
#        "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen", "Twenty"
 #   );

    printf(
        "%-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s\n",
        "1", "2",   "3", "4", "5",
        "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30"
    );
    my $sth_site_type = $dbh->prepare("select distinct site_type from ticket");
    $sth_site_type->execute;

    my $site_types = $sth_site_type->fetchall_arrayref( {} );

    #warn Data::Dumper::Dumper($site_types);

    foreach my $site_type (@$site_types) {

        # printf "\n\nSite type: %s\n", $site_type->{'site_type'};
        printf "\n%s\n", $site_type->{'site_type'};

        print "------------------\n";

        my $sth_tickets_jobs = $dbh->prepare(
	"select ticket.ticket_id, count(*) as jobs_count from ticket inner join job on ticket.ticket_id = job.ticket_id where 
	 ticket.ticket_type_name = 'Blast' and ticket.site_type=? group by ticket.ticket_id order by jobs_count"
        );

        $sth_tickets_jobs->bind_param( 1, $site_type->{'site_type'} );

        $sth_tickets_jobs->execute;
        my $tickets_jobs_count = $sth_tickets_jobs->fetchall_arrayref( {} );

        #warn Data::Dumper::Dumper($tickets_jobs_count);

        my @ticket_job_stat;

        for ( my $frequency = 1 ; $frequency <= 30 ; $frequency++ ) {
            my $count = 0;

            foreach my $ticket (@$tickets_jobs_count) {

                if ( $frequency == $ticket->{'jobs_count'} ) {

                    $ticket_job_stat[$frequency] = ++$count;

                }

            }

        }

        for ( my $frequency = 1 ; $frequency <= 30 ; $frequency++ ) {
            printf( "%-8s ",
                $ticket_job_stat[$frequency] ? $ticket_job_stat[$frequency] : 0 );
        }
        print "\n";

        #warn Data::Dumper::Dumper(@ticket_job_stat);
    }

}

