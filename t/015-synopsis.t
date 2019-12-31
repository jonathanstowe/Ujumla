#!/usr/bin/env perl6

use v6;

use Test;

use Ujumla;

todo("not working yet");
lives-ok {
    my $config = Ujumla.new( config => q:to/EIEIO/);
    # Some comment
    name "something or other"
    <Section>
       section-name  whatever
    </Section>
    EIEIO

    is $config.get-item('name'), "something or other";
    is $config.get-item('Section', 'section-name'), 'whatever';
}, "parse and retrieve config";



done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
