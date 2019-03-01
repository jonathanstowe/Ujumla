#!/usr/bin/env perl6

use v6;

use Test;
use Ujumla;

for $*PROGRAM.parent.add('data').dir( test => /^cfg/ ) -> $d {
    my $cfg = $d.slurp;
    subtest {
        ok Ujumla::Grammar.parse($cfg), "parses ok";
    }, $d.basename;
}

done-testing;

# vim: ft=perl6
