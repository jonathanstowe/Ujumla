#!/usr/bin/env perl6

use v6;

use Test;

use Ujumla;


lives-ok {
    my $config = Ujumla.new( config-text => q:to/EIEIO/);
    # Some comment
    name "something or other"
    <Section>
       section-name  whatever
    </Section>
    EIEIO

    is $config.get-item('name'), "something or other", 'got item in top level';
    is $config.get-item('Section', 'section-name'), 'whatever', 'got item in section';
}, "simple config";



done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
