#!/usr/bin/env perl6

use v6;

use Test;

use Ujumla;

my $config-file = $*PROGRAM.parent.add('data/cfg.19').Str;

my Ujumla $config;

lives-ok { $config = Ujumla.new(:$config-file); }, "create Ujumla object";


my @tests = (
    {
        item    =>  'msg1',
        value   =>  'Das ist ein Test',
        name    =>  'item with = preceded by empty config line',
    },
    {
        item    =>  'msg2',
        value   =>  "Das = ein Test",
        name    =>  'item with = with = in the value',
    },
    {
        item    =>  'msg3',
        value   =>  "Das ist ein Test",
        name    =>  'item with white space separator',
    },
    {
        item    =>  'msg4',
        value   =>  "Das = ein Test",
        name    =>  'item with white space separator with = in value',
    },
    {
        item    =>  'msg6',
        value   =>  "Das = ein Test",
        name    =>  'here-doc with = separator with = in value',
    },
    {
        item    =>  'msg7',
        value   =>  "Das = ein Test",
        name    =>  'here-doc with white space separator with = in value and the same delimiter',
    },
);

for @tests -> $test {
    ok my $item = $config.get-item($test<item>), "get-item '{ $test<item> }'";
    is $item, $test<value>, $test<name>;
}

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
