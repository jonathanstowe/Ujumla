#!/usr/bin/env perl6

use v6;

use Grammar::Debugger;
use Test;
use Ujumla;


my $cfg = q:to/FOO/;
domain	 b0fh.org
domain = l0pht.com
/*
foo
*/
domain   infonexus.com
# comment
<Foo>
    bar baz
</Foo>
yada <<HERE
some bunch of stuff
across a bunch of lines
HERE
FOO

ok Ujumla::Grammar.parse($cfg), "canary test of parsing";

my @tests = (
    {
        description => "simplest key <space> value",
        config => "foo bar\n",
        expect => {
            name    => "foo",
            value   => 'bar',
        }
    },
    {
        description => "simplest key <space> value (with spaces)",
        config => 'foo bar baz',
        expect => {
            name    => "foo",
            value   => 'bar baz',
        }
    },
    {
        description => "key <space> quoted value",
        config => 'foo "bar baz"',
        expect => {
            name    => "foo",
            value   => '"bar baz"',
        }
    },
    {
        description => "key = value",
        config => 'foo = bar',
        expect => {
            name    => "foo",
            value   => 'bar',
        }
    },
    {
        description => "key=value",
        config => 'foo=bar',
        expect => {
            name    => "foo",
            value   => 'bar',
        }
    },
);

for @tests -> $test {
    subtest {
        ok my $res = Ujumla::Grammar.parse($test<config>), "parse ok";
        todo "not the right part of the match", 2;
        is $res<config-line>[0]<name>, $test<expect><name>, "got the expected name";
        is $res<config-line>[0]<value>, $test<expect><value>, "got the expected value";
    }, $test<description>;


}


done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
