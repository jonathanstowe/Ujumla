#!/usr/bin/env raku

use v6;

use Test;
use Ujumla;

for $*PROGRAM.parent.add('data').dir( test => /^cfg/ ) -> $d {
    my $cfg = $d.slurp;
    my $desc;
    my  Bool $todo = False;

    if $cfg ~~ /^^'#'/ {
        $desc = $cfg.lines.head.subst(/^'#'\s*/, '');
        if $desc ~~ /TODO/ {
            $todo = True;
            $desc.subst-mutate(/'TODO: '/,'');
        }
    }
    else {
        $desc = $d.basename;
    }
    todo("Not quite there yet") if $todo;
    subtest {
        ok my $res = Ujumla::Grammar.parse($cfg), "parses ok";
    }, $desc;
}

done-testing;

# vim: ft=raku
