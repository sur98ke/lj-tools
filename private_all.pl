#!/usr/bin/perl

# private_all.pl

use warnings;
use strict;
use Data::Dumper;
$Data::Dumper::Indent = 1;

use Sur_Lj_XMLRPC qw( 
    xmlrpc_call_with_auth 
    current_datetime 
    get_all_entries
    process_entries
    );
use MiscUtils qw (
    &uniq
    &print_outerr
    );

{
print STDERR 'Login ? ';
chomp (my $login = <>);
print STDERR 'Password (will be echoed on this screen) ? ';
chomp (my $password = <>);

Sur_Lj_XMLRPC::set_login($login, $password);
}

my @entries = get_all_entries();

#print_outerr "\n", "Entries' ItemIDs:\n";
#print_outerr join (',', @entries), "\n";

sub private_all{
    my %entry = %{shift()};
    my %query = ();
    my @fld_cpy = ('itemid', 'event', 'subject');
    @query{@fld_cpy} = @entry{@fld_cpy};

    $query{'security'} = 'private';
    return \%query;
    }


process_entries(@entries, &private_all);
exit 0;


