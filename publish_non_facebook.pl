#!/usr/bin/perl

# publish_non_facebook.pl

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

sub publish_non_facebook{
    my %entry = %{shift()};
    my %query = ();
    my @fld_cpy = ('itemid', 'event', 'subject');
    @query{@fld_cpy} = @entry{@fld_cpy};

    my $taglist = $entry{'props'}{'taglist'};
    my $fl_change = not ($taglist =~ m/из Facebook/);
    $query{'security'} = 'public';
    if ($fl_change){
        return \%query;
        }
    else{
        return undef;
        }
    }


process_entries(@entries, &publish_non_facebook);
exit 0;


