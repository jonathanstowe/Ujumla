#!/usr/bin/env raku

use v6;

use Test;
use Ujumla;


my $cfg = q:to/FOO/;
domain     b0fh.org
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
        config => "foo bar",
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
    {
        description => "here-doc",
        config => "foo <<EOF\nbar\nEOF\n",
        expect => {
            name    => "foo",
            value   => "<<EOF\nbar\nEOF\n",
        }
    },
);

for @tests -> $test {
    subtest {
        ok my $res = Ujumla::Grammar.parse($test<config>), "parse ok";
        is $res<config-content><config-line>[0]<name>, $test<expect><name>, "got the expected name";
        is $res<config-content><config-line>[0]<value>, $test<expect><value>, "got the expected value";
    }, $test<description>;
}

$cfg = $*PROGRAM.parent.add('data/example.cfg').slurp;

todo "can't quite parse everything";
ok Ujumla::Grammar.parse($cfg), "parse example";


done-testing;
# vim: expandtab shiftwidth=4 ft=raku
