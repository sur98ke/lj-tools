package MiscUtils;

use warnings;
use strict;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( 
    &uniq
    &print_outerr
    );


# sub uniq (c) Gabor Szabo https://perlmaven.com/unique-values-in-an-array-in-perl
sub uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
    }

sub print_outerr(@){
    print STDOUT @_;
    if (not -t STDOUT and -t STDERR){
        print STDERR @_;
        }
    }

1;
