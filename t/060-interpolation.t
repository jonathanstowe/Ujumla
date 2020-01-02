#!/usr/bin/env perl6

use v6;

use Test;

use Ujumla;

my $config-file = $*PROGRAM.parent.add('data/cfg.16').Str;

my Ujumla $config;

lives-ok { $config = Ujumla.new(:$config-file); }, "create Ujumla object";

is $config.get-item('pr'), 'blah/blubber', "interpolate in top level";
is $config.get-item('base'), '/opt', "we're left with the correct value";
ok my $etc = $config.get-section('etc'), "get the section with inner scoped item";
is $etc.get-item('base'), '/usr', "get scoped item";
is $etc.get-item('log'), '/usr/log/logfile', "got scoped interpolated item";
is $etc.get-item('users', 'home'), '/usr/home/max', "inner interpolated section";
ok my $zub = $config.get-section('zub'), "get the section with outer scoped item";
is $zub.get-item('log'), '/opt/log/logfile', "got scoped interpolated item";
is $zub.get-item('users', 'home'), '/opt/home/max', "inner interpolated section";
my @dirs;

lives-ok { @dirs = $config.get-sections('dir') }, "get sections with interpolated names";
is @dirs.elems, 3, "got the number of sections we expected";


ok my $tag-only = @dirs.grep(!*.sub-section.defined).first, "section with only interpolated name";
is $tag-only.get-item('bl'), 1, "got right item";

ok my $tag-fixed = @dirs.grep({ $_.sub-section.defined and ( $_.sub-section eq 'mono' )}).first, "section with interpolated name and fixed sub-section";
is $tag-fixed.get-item('bl'), 2, "got right item";

ok my $tag-variable = @dirs.grep({ $_.sub-section.defined && $_.sub-section eq 'teri'}).first, "section with interpolated name and interpolated sub-section";
is $tag-variable.get-item('bl'), 3, "got right item";

ok my $ss-variable = $config.get-section('text', 'teri'), "fix section name interpolated sub-section";
is $ss-variable.get-item('bl'), 3, "got right item";


done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
