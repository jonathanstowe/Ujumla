#!/usr/bin/env perl6

use v6;

use Test;
use Ujumla;

my @tests = (
    {
        description => "simplest key <space> value",
        config => 'foo bar',
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
        #diag $res.perl;
        is $res<config-line>[0]<name>, $test<expect><name>, "got the expected name";
        is $res<config-line>[0]<value>, $test<expect><value>, "got the expected value";
    }, $test<description>;


}


done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
