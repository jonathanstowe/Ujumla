NAME
====

Ujumla - Read Apache/Config-General style configuration

SYNOPSIS
========

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

DESCRIPTION
===========

This module aims to be able to read those configuration files that can be read by the Perl 5 module [Config::General](https://metacpan.org/release/Config-General) which in itself supports a superset of the [Apache httpd configuration syntax](https://httpd.apache.org/docs/2.4/configuring.html#syntax).

CONFIGURATION FORMAT
--------------------

The configuration consists of key/value pairs and named sections.

### KEYS AND VALUES

The key/value pairs may be either whitespace or equals sign ('=') separated. The keys must be valid Raku identifiers, consisting of alphanumeric, underscore pr hyphen characters and the values can be any appropriate value, either quoted or unquoted, terminating at whitespace before the end of a line or the shell comment character ('#').

Additionally multi-line values can be formed by using a here-document like syntax:

       foo  <<FOO
         multi
         line
         value
       FOO

There is also rudimentary value interpolation whereby a key prefixed by '$' will be replaced by the value associated with that key, such that:

        me=blah
        pr=$me/blubber

Will give `pr` a value of `blah/blubber`. If the key is not defined by the time it is used this way it will not be replaced at all. You can also choose to interpolate environment variables and provide some default values from the application.

### NAMED SECTIONS

Named sections are tag-like structures, where the tag "name" is the section name and which may have a "sub-section name", they can contain key/value pairs and further nested sections:

        <Name Subname>
            key=value
        </Name>

The name of a section need not be unique, however duplicate names are more useful if there are sub-section names (which could be considered as a value in themselves,) similar to the notion of `Location` sections in an Apache HTTP config. The precise semantics of sections/sub-sections are open to be defined by the application.

A section will introduce a new scope to the interpolation mechanism described earlier, keys defined outside the section can be accessed but they can also be redefined without effecting the value outside the section.

### INCLUSION

Further configuration files can be included into the current one by use of a special include *tag*:

        <<include included-file.cfg>>

The bare `include` key as found in Apache configuration does **not** work.

The included configuration is merged into the current scope within the configuration as if the content was pasted at that location in the configuration file, this means that its keys will become available for later interpolation and similarly the previously defined keys are available for interpolation in the included file.

METHODS
-------

### new

    method new(Str :$config-test, :$config-file, Str :@search-path, :%initial-variables, Bool :$include-env = False, Ujumla::FileHelper :$file-helper)

Creates a new `Ujumla` object, the configuration text can be supplied as `:$config-text` or read from `:$config-file` which can either be an absolute path or found in the list of directories specified by `:@search-path` (but see the description of `Ujumla::FileHelper` below.) `:%initial-variables` specifies a `Hash` which will be interpolated in the configuration as if they had been specified at the beginning of the configuration. If `:include-env` is specified then environment variables can be interpolated into the configuration in the same way as keys in the configuration or specified in the `:%initial-variables`, it is off by default as this could be a security risk if you are not in complete control of the environment the program is started in.

### config

    method config( --> Ujumla::Config)

This is the actual representation of the parsed configuration, to which the following methods are delegated.

### get-item

    multi method get-item(Str $key --> Str)
    multi method get-item(Str $section-name, Str $key --> Str)

This returns the value of the item specified by `$key` in the top level of the configuration, or in the section named `$section-name` in the second variant, returning the Str type object if there is no such item. This does not recurse nested sections to find the item: you may want to retrieve the section separately if you need to do that.

### get-section

    multi method get-section(Str:D $section --> Ujumla::Section )
    multi method get-section(Str:D $section, Str:D $sub-section --> Ujumla::Section )

This returns the `Section` named `$section` and optionally with the `$sub-section` or an undefined value if none found. Because there is no constraint on duplicate section names, if more than one is found with the supplied name a warning will be issued and the first one found returned. If you are expecting duplicate names then you can use `get-sections` and provide your own logic for handling them as appropriate.

A `Section` is simply an `Ujumla::Config` with an additional role that provides the name and sub-section attributes so any of these methods (`get-item`, `get-section` and `get-sections`) can be called on it.

### get-sections

    method get-sections(Str:D $section)

This will return a list of `Section` objects that have the name `$section` (or an empty list,) as mentioned aboved the `Section` is an `Ujumla::Config` with an additional role, so this will enable you to provide your own logic for dealing with multiple sections with the same name. The section has the additional attributes `name` and `sub-section` so you can work with them as appropriate.

### merge

    method merge(Ujumla::Config $config)

This is not delegated, so needs to be called on the config object. This is the method that underlies the inclusion mechanism but is exposed if you want to implement some more complicated inclusion logic, say deciding on which configuration file to include based on inputs that are not available until runtime.

Ujumla::FileHelper
------------------

An instance of a sub-class of `Ujumla::FileHelper` can be supplied to the constructor as `:$file-helper` if you want to alter the way that the configuration files are found and loaded. By default the `Ujumla::FileHelper` instance is created with the `:@search-path` that is passed to the `Ujumla` constructor, and the methods `full-search-path`, `resolve-file`, and `get-config-text` are used to find and read the configuration for the main and included files, you can over-ride them as required in a sub-class if you need to change the behaviour.

### new

    method new(Str :@search-path, IO::Path :@full-search-path --> Ujumla::FileHelper)

Creates a new object of the class, `:@search-path` is a list of additional directory names that will be searched for the configuration files, `:@full-search-path` is the complete list of locations as `IO::Path` objects, typically this will be populated in its accessor method but can be provided if you only want a pre-determined list of locations.

### full-search-path

    method full-search-path( --> IO::Path @)

This returns a list of `IO::Path` objects which should be directories which will be search to locate a configuration file. By default it combines the `search-path` provided to the constructor, the current working directory of the process and those directories provided as a colon separated list in the environment variable `UJUMLA_PATH`. You may want to over-ride this (or provide `full-search-path` to the constructor,) if you are not in full control of the environment that your program is started in, so as to prevent the injection of untrusted configuration.

### resolve-file

    method resolve-file(Str() $file-name --> IO::Path)

This returns an `IO::Path` object representing `$file-name` or throws an `X::Ujumla::NoFile` if the file does not exist. The default implementation will return the `IO::Path` directly if `$file-name` is *absolute* (as per the semantic of the filesystem,) and otherwise iterate over `full-search-path` until the file is found, appending `$file-name` to each path.

You may want to over-ride this if you want to perform additional checks on the properties of the file, such as making sure it isn't world or group writeable.

### get-config-text

    method get-config-text(Str:D $file-name --> Str )

This returns the text of the configuration given `$file-name` it will call `resolve-file` to locate the file, you may want to over-ride this if, for example, you have encrypted or compressed your file, but you may want to call `callsame` to get the text before further processing.

