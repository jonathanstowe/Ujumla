# Ujumla

Read Apache/Config-General config files in Raku

![Build Status](https://github.com/jonathanstowe/Ujumla/workflows/CI/badge.svg)

## Synopsis

```raku

use Ujumla;

my $config = Ujumla.new( config-text => q:to/EIEIO/);
# Some comment
name "something or other"
<Section>
   section-name  whatever
</Section>
EIEIO

say $config.get-item('name'); # "something or other"
say $config.get-item('Section', 'section-name'); # "whatever"

```


## Description

This module aims to be able to read those configuration files that can be read
by the Perl 5 module [Config::General](https://metacpan.org/release/Config-General)
which in itself supports a superset of the [Apache httpd configuration syntax](https://httpd.apache.org/docs/2.4/configuring.html#syntax).

I haven't named it `Config::General` because I wouldn't want to take the name from someone who might
be able to do better and because I don't want to raise the expectation that this is a *port* of the Perl 5
module - the interface and options are likely to differ wildly from that module.  It is instead named for
the first search result for *"Swahili for General"*.

You can find the fuller documentation [here](Documentation.md).

## Installation

Assuming you have a working Rakudo compiler you should be able to install this with *zef* :

    zef install Ujumla

    # Or from a local clone

    zef install .


## Support

If you have any suggestions, complaints or patches please direct them to [Github](https://github.com/jonathanstowe/Ujumla/issues)

The chances are that this won't parse every conceivable configuration file, so if you find something that
you think it should parse but doesn't a failing test case would be much appreciated.


## Licence & Copyright

This is free software please see the [LICENCE](LICENCE) file.

© Jonathan Stowe 2020 - 2021
