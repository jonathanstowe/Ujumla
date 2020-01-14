#!/usr/bin/env perl6

use v6;

use Test;
use Ujumla;

my $config;

lives-ok { $config = Ujumla.new(search-path => ( $*PROGRAM.parent.add('data').Str,), config-file => 'include.cfg') }, "get from file with search path";

is $config.get-item('foo'), 'bar', "direct item from top level";
is $config.get-item('zub'), 'bar/included', "item from include with interpolated outer item";
is $config.get-item('bar'), 'blam', 'included item';
is $config.get-item('baz'), 'bar/included', "item with the interpolated item from included interpolated";

done-testing();
# vim: ft=perl6
