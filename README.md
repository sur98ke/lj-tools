# lj-tools

Some scripts and routines to automate LiveJournal entries' posting and modifications

Written in Perl

## Installation

To use these scripts and routines you should:

1. Install Perl5

   * Windows - you could use [Strawberry perl](http://strawberryperl.com/)
   
   * Linux - should be installed from start on most modern distributions. Try `perl --version` in shell. If `command not found` then you should refer to your distribution's manual how to install package `perl`

2. Install `XMLRPC::Lite` from CPAN

According to [instuctions](https://www.cpan.org/modules/INSTALL.html):

In root/admin console type
```
cpan App::cpanminus

cpanm XMLRPC::Lite
```

3. Just clone/download this repo :)

## Contents

### MiscUtils.pm

Just some util subroutines

#### sub print_outerr

This allows you to have debug output both on the console and redirected to file by sending printed content both into STDOUT and STDERR

That's why you still see output if you type

```
perl test.pl > test.log
```

### Sur_Lj_XMLRPC.pm

Main routines to manage journal

#### First BLOCK `{ # sub xmlrpc_call ...`

Encapsulates XMLRPC query creation and processing.
**Do not use** `sub xmlrpc_call` from this block. 
Use `sub xmlrpc_call_with_auth` from next block instead.

#### Second BLOCK `{ # sub xmlrpc_call_with_auth ...`

Encapsulates XMLRPC query with authentication to Livejournal server.
Your login and password are kept here during runtime of your script. They are not accessible from outside this BLOCK.

According to [Livejournal manual](https://www.livejournal.com/doc/server/ljp.csp.auth.challresp.html) challenge-responce authentication is used.

You should just call `sub set_login` once and then call `sub xmlrpc_call_with_auth` for each query you want to do.

Refer to `test.pl` for examples

#### sub current_datetime

returns hash with keys `min` `hour` `day` `mon` `year` useful in `postevent` query

#### sub get_all_entries

returns list of all journal entries' `itemid`s

#### sub process_entries

allows you to automatically process any set of your entries using your own subroutine

### test.pl

just some demos and tests :)

### private_all.pl

Make all entries `private` (friends only)

### publish_non_facebook.pl

Make `public` all entries except those having given tag (e.g. `из Facebook`)


