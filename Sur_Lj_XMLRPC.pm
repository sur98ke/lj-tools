package Sur_Lj_XMLRPC;

use warnings;
use strict;
use Data::Dumper;

use MiscUtils qw (
    &uniq
    &print_outerr
    );

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw( 
    &xmlrpc_call &xmlrpc_call_with_auth 
    &current_datetime
    &get_all_entries
    &process_entries
    );

our $DEBUG = 1;

{ # sub xmlrpc_call
use XMLRPC::Lite;
my $xmlrpc = new XMLRPC::Lite;
$xmlrpc->proxy("http://livejournal.com/interface/xmlrpc");

sub xmlrpc_call($$) {
    my ($method, $req) = @_;
    my $res = $xmlrpc->call($method, { 
        %$req ,
        'ver' => '1',
        });
    if ($res->fault()) {
        print_outerr "Error:\n".
        " String: " . $res->faultstring() . "\n" .
        " Code: " . $res->faultcode() . "\n";
        exit 1;
        }
    return $res->result();
    }
} # sub xmlrpc_call

{ # sub xmlrpc_call_with_auth
use Digest::MD5 qw(md5_hex);
my $user;
my $pass;

sub set_login($$){
    ($user, $pass) = @_;
    }

sub xmlrpc_call_with_auth($$) {
    my ($method, $req) = @_;
    my $get_chal = xmlrpc_call("LJ.XMLRPC.getchallenge", {});
    my $chal = $get_chal->{'challenge'};
    #print_outerr "chal: $chal\n";
    my $response = md5_hex($chal . md5_hex($pass));
    
    my $result = xmlrpc_call ($method, { 
        %$req ,
        'username' => $user,
        'auth_method' => 'challenge',
        'auth_challenge' => $chal,
        'auth_response' => $response,
        });
    return $result;
    }
} # sub xmlrpc_call_with_auth

sub current_datetime(){
    use Time::Local;
    my %res;
    @res{qw( sec min hour day mon year )} = localtime();
    $res{'mon'} += 1;
    $res{'year'} += 1900;
    delete $res{'sec'};
    return %res;
    }

sub get_all_entries (){
    my @entries;
    my @other;
    my $lastsync = '';
    my $total;
    while (1) {
        my %syncitems_arg;
        if ($lastsync){
            $syncitems_arg{'lastsync'} = $lastsync;
            }
        my $syncitems_rslt = xmlrpc_call_with_auth('LJ.XMLRPC.syncitems', 
            \%syncitems_arg);
        print_outerr "Dumper(\$syncitems_rslt);\n"      if $DEBUG;
        print_outerr Dumper($syncitems_rslt)            if $DEBUG;
        unless ($lastsync){
            $total = $syncitems_rslt->{'total'};
            }
        foreach my $item (@{ $syncitems_rslt->{'syncitems'} }){
            if ($lastsync lt $item->{'time'}){
                $lastsync =  $item->{'time'};
                }
            if ($item->{'item'} =~ /^L-(\d+)$/) {
                push @entries, $1;
                }
            else {
                push @other, $item->{'item'};
                }
            }
        last if $syncitems_rslt->{'count'} == $syncitems_rslt->{'total'};
        }
    scalar MiscUtils::uniq(@entries) == scalar @entries
        or die "get_all_entries: non-unique entries in syncitems";
    scalar MiscUtils::uniq(@other) == scalar @other
        or die "get_all_entries: non-unique other in syncitems";
    scalar @entries + scalar @other == $total
        or die "get_all_entries: number of items got != total in syncitems";
    return @entries;
    }

sub process_entries(\@\&;%){
    use Storable qw(dclone);
    my @entry_itemids = @{shift()};
    my $modification_sub = shift();
    my %opts = @_;
    my @n_entries_processed_to_pause = 
        @{ (delete $opts{'n_entries_processed_to_pause'}) || 
            [1, 5, 10, 50, 100, 200, 500, 1000]};
    my $DUMP_ENTRY_BEFORE = 
        (delete $opts{'DUMP_ENTRY_BEFORE'}) || 1;
    my $DUMP_CHANGE_QUERY = 
        (delete $opts{'DUMP_CHANGE_QUERY'}) || 1;
    my $DUMP_CHANGE_RESP = 
        (delete $opts{'DUMP_CHANGE_RESP'}) || 1;
    my $allow_delete_entry = 
        (delete $opts{'allow_delete_entry'}) || 0;
    my $allow_change_entry_text = 
        (delete $opts{'allow_change_entry_text'}) || 0;
    my $allow_delete_entry_subj = 
        (delete $opts{'allow_delete_entry_subj'}) || 0;
    my $allow_change_entry_subj = 
        (delete $opts{'allow_change_entry_subj'}) || 0;
    if (%opts){
        die "process_entries: unknown options: " . join(', ', keys %opts);
        }
    
    my $n_entries_processed = 0;
    foreach my $entry_itemid (@entry_itemids){
        my %getevents_arg = (
            'selecttype' => 'one',
            'itemid' => $entry_itemid,
            );
        my $getevents_rslt = xmlrpc_call_with_auth('LJ.XMLRPC.getevents', 
            \%getevents_arg);
        my $entry_obj = $getevents_rslt->{'events'}[0];
        if ($DUMP_ENTRY_BEFORE){
            my $entry_obj_cpy = dclone($entry_obj);
            $entry_obj_cpy->{'event'} = substr $entry_obj_cpy->{'event'}, 0, 60;
            print_outerr "\n", Data::Dumper->Dump([$entry_obj_cpy], ['<<<recv<<< $entry_obj_cpy']);
            }

        my $modif_entry = $modification_sub->(dclone($entry_obj));
        if (not $modif_entry) {
            print_outerr "NOT modifying this entry with id $entry_itemid\n";
            next;
            }
        
        print_outerr     "!!! modifying this entry with id $entry_itemid\n";
        
        if (not $modif_entry->{'itemid'} or
                $modif_entry->{'itemid'} ne $entry_obj->{'itemid'}){
            die "process_entries: modification_sub tried to change itemid";
            }
        if (not $modif_entry->{'event'}){
            unless ($allow_delete_entry){
                die "process_entries: modification_sub tried to delete entry " .
                    "and \$opts{'allow_delete_entry'} is false";
                }
            print_outerr "DELETING this entry with id $entry_itemid\n";
            print_outerr "Full entry text was:\n\n";
            print_outerr $entry_obj->{'event'},
            print_outerr "\n\n";
            }
        if ($modif_entry->{'event'} ne $entry_obj->{'event'}){
            unless ($allow_change_entry_text){
                die "process_entries: modification_sub tried to change entry text " .
                    "and \$opts{'allow_change_entry_text'} is false";
                }
            print_outerr "MODIFYING this entry with id $entry_itemid\n";
            print_outerr "Full entry text was:\n\n";
            print_outerr $entry_obj->{'event'},
            print_outerr "\n\n";
            }
        if (not $modif_entry->{'subject'} and $entry_obj->{'subject'}){
            unless ($allow_delete_entry_subj){
                die "process_entries: modification_sub tried to clear entry subject " .
                    "and \$opts{'allow_delete_entry_subj'} is false";
                }
            }
        if ($modif_entry->{'subject'} ne $entry_obj->{'subject'}){
            unless ($allow_change_entry_subj){
                die "process_entries: modification_sub tried to change entry subject " .
                    "and \$opts{'allow_change_entry_subj'} is false";
                }
            }
        
        if ($DUMP_CHANGE_QUERY){  
            my $modif_entry_cpy = dclone($modif_entry);
            $modif_entry_cpy->{'event'} = substr $modif_entry_cpy->{'event'}, 0, 60;
            print_outerr "\n", Data::Dumper->Dump([$modif_entry_cpy], ['>>>send>>> $modif_entry_cpy']);
            }
        
        my $editevent_rslt = xmlrpc_call_with_auth('LJ.XMLRPC.editevent', $modif_entry);
        
        if ($DUMP_CHANGE_RESP) {
            print_outerr "\n", Data::Dumper->Dump([$editevent_rslt], ['<<<recv<<< $editevent_rslt']);
            }
        
        ++$n_entries_processed;
        print_outerr "By now modified total $n_entries_processed entries\n";
        if (@n_entries_processed_to_pause){
            while($n_entries_processed_to_pause[0] < $n_entries_processed){
                shift @n_entries_processed_to_pause;
                }
            if ($n_entries_processed_to_pause[0] == $n_entries_processed){
                print_outerr
                    "Please check that everything is OK and hit Enter\n",
                    "OR hit Ctrl+C to interrupt processing\n";
                <>;
                }
            }
        }
    }



1;
