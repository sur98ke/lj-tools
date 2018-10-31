#!/usr/bin/perl

# test.pl

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

### basic tests
my $login_rslt = xmlrpc_call_with_auth('LJ.XMLRPC.login', {});
print_outerr "\n", Data::Dumper->Dump([$login_rslt], ['<<<recv<<< $login_rslt']);
exit 0;

# my $posteventargs = {
#     'event' => 'Lorem imsum ...',
#     'subject' => 'First entry',
#     current_datetime(),
#     };

{ # sub post_test_entries()

my @test_tags = (
    'Превед медвед', 'веселое', 'jokes', '42', 
    'из Facebook', 'hello world', 'лулз', 'йцукен', 'teh end', 
    );

my $text = 'Lorem ipsum dolor sit amet, 
consectetur adipiscing elit, 
sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Ut enim ad minim veniam, 
quis nostrud exercitation ullamco laboris nisi ut aliquip 
ex ea commodo consequat. Duis aute irure dolor in reprehenderit 
in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
Excepteur sint occaecat cupidatat non proident, 
sunt in culpa qui officia deserunt mollit anim id est laborum.';

sub post_test_entries(){
    my $cnt = 100;
    my $start = 1;
    for (my $i = $start; $i < $cnt; ++$i){
        my @tags = ();
        my $j = -1;
        while (1){
            $j += 1 + int(rand 4) + int(rand 4);
            last if $j >= @test_tags;
            push @tags, $test_tags[$j];
            }
        my $posteventargs = {
            'event' => "$i $text",
            'subject' => "Test entry No $i",
            'security' => 'private',
            'props' => { 'taglist' => join(',', @tags) }, 
            current_datetime(),
            };
        print_outerr "\n", Data::Dumper->Dump([$posteventargs], ['>>>send>>> $posteventargs']);
        my $post_rslt = xmlrpc_call_with_auth('LJ.XMLRPC.postevent', $posteventargs);
        print_outerr "\n", Data::Dumper->Dump([$post_rslt], ['<<<recv<<< $post_rslt']);
        sleep (5);
        }
    }

#post_test_entries();
#exit 0;

}

my @entries = get_all_entries();

#print_outerr "\n", "Entries' ItemIDs:\n";
#print_outerr join (',', @entries), "\n";

sub fix_tag_facebook{
    my %entry = %{shift()};
    my %query = ();
    my @fld_cpy = ('itemid', 'event', 'subject');
    @query{@fld_cpy} = @entry{@fld_cpy};
    # $query{'event'} .= ' 0';
    my $taglist = $entry{'props'}{'taglist'};
    my $fl_change = $taglist =~ s/Из facebook/из Facebook/;
    $query{'props'}{'taglist'} = $taglist;
    #'props' => { 'taglist' => join(',', @tags) }, 
    if ($fl_change){
        return \%query;
        }
    else{
        return undef;
        }
    }


#process_entries(@entries, &fix_tag_facebook);
#exit 0;

if (0){ # test 
    my $getevents_arg = {
        'selecttype' => 'one',
        'itemid' => '52',
        };
    my $getevents_rslt = xmlrpc_call_with_auth('LJ.XMLRPC.getevents', 
        $getevents_arg);
    my $entry_obj = $getevents_rslt->{'events'}[0];


    my $editevent_args = {
        'itemid' => '52',
        'event' => $entry_obj->{'event'},
        'subject' => $entry_obj->{'subject'},
        'security' => 'public',
        #'props' => { 'taglist' => join(',', @tags) }, 
        #current_datetime(),
        };
    print_outerr "\n", Data::Dumper->Dump([$editevent_args], ['>>>send>>> $editevent_args']);
    my $editevent_rslt = xmlrpc_call_with_auth('LJ.XMLRPC.editevent', $editevent_args);
    print_outerr "\n", Data::Dumper->Dump([$editevent_rslt], ['<<<recv<<< $editevent_rslt']);
}

