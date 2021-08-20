use v6;

=begin pod

=head1 NAME

Ujumla -  Read Apache/Config-General style configuration

=head1 SYNOPSIS

=begin code

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

=end code

=head1 DESCRIPTION

This module aims to be able to read those configuration files that can be read
by the Perl 5 module L<Config::General|https://metacpan.org/release/Config-General>
which in itself supports a superset of the L<Apache httpd configuration syntax|https://httpd.apache.org/docs/2.4/configuring.html#syntax>.

=head2 CONFIGURATION FORMAT

The configuration consists of key/value pairs and named sections.

=head3 KEYS AND VALUES

The key/value pairs may be either whitespace or equals sign ('=') separated.  The keys must be valid Raku identifiers, consisting of
alphanumeric, underscore pr hyphen characters and the values can be any appropriate value, either quoted or unquoted, terminating
at whitespace before the end of a line or the shell comment character ('#').

Additionally multi-line values can be formed by using a here-document like syntax:

=begin code

   foo  <<FOO
     multi
     line
     value
   FOO

=end code

There is also rudimentary value interpolation whereby a key prefixed by '$' will be replaced by the value associated with that key,
such that:

=begin code

    me=blah
    pr=$me/blubber

=end code

Will give C<pr> a value of C<blah/blubber>. If the key is not defined by the time it is used this way it will not be replaced at all.
You can also choose to interpolate environment variables and provide some default values from the application.

=head3 NAMED SECTIONS

Named sections are tag-like structures, where the tag "name" is the section name and which may have a "sub-section name", they can
contain key/value pairs and further nested sections:


=begin code

    <Name Subname>
        key=value
    </Name>

=end code

The name of a section need not be unique, however duplicate names are more useful if there are sub-section names (which could be
considered as a value in themselves,) similar to the notion of C<Location> sections in an Apache HTTP config. The precise semantics
of sections/sub-sections are open to be defined by the application.

A section will introduce a new scope to the interpolation mechanism described earlier, keys defined outside the section can be
accessed but they can also be redefined without effecting the value outside the section.

=head3 INCLUSION

Further configuration files can be included into the current one by use of a special include I<tag>:

=begin code

    <<include included-file.cfg>>

=end code

The bare C<include> key as found in Apache configuration does B<not> work.

The included configuration is merged into the current scope within the configuration as if the content was pasted at
that location in the configuration file, this means that its keys will become available for later interpolation and
similarly the previously defined keys are available for interpolation in the included file.

=head2 METHODS

=head3 new

    method new(Str :$config-text, :$config-file, Str :@search-path, :%initial-variables, Bool :$include-env = False, Ujumla::FileHelper :$file-helper)

Creates a new C<Ujumla> object, the configuration text can be supplied as C<:$config-text> or read from C<:$config-file> which can either be an absolute
path or found in the list of directories specified by C<:@search-path> (but see the description of C<Ujumla::FileHelper> below.)  C<:%initial-variables>
specifies a C<Hash> which will be interpolated in the configuration as if they had been specified at the beginning of the configuration.  If C<:include-env>
is specified then environment variables can be interpolated into the configuration in the same way as keys in the configuration or specified in the
C<:%initial-variables>, it is off by default as this could be a security risk if you are not in complete control of the environment the program is started in.

=head3 config

    method config( --> Ujumla::Config)

This is the actual representation of the parsed configuration, to which the following methods are delegated.

=head3 get-item

    multi method get-item(Str $key --> Str)
    multi method get-item(Str $section-name, Str $key --> Str)

This returns the value of the item specified by C<$key> in the top level of the configuration, or in the section named C<$section-name>
in the second variant, returning the Str type object if there is no such item.  This does not recurse nested
sections to find the item:  you may want to retrieve the section separately if you need to do that.

=head3 get-section

    multi method get-section(Str:D $section --> Ujumla::Section )
    multi method get-section(Str:D $section, Str:D $sub-section --> Ujumla::Section )

This returns the C<Section> named C<$section> and optionally with the C<$sub-section> or an undefined value if none found.
Because there is no constraint on duplicate section names, if more than one is found with the supplied name a warning will
be issued and the first one found returned. If you are expecting duplicate names then you can use C<get-sections> and
provide your own logic for handling them as appropriate.

A C<Section> is simply an C<Ujumla::Config> with an additional role that provides the name and sub-section attributes so
any of these methods (C<get-item>, C<get-section> and C<get-sections>) can be called on it.

=head3 get-sections

    method get-sections(Str:D $section)

This will return a list of C<Section> objects that have the name C<$section> (or an empty list,) as mentioned aboved the
C<Section> is an C<Ujumla::Config> with an additional role, so this will enable you to provide your own logic for dealing
with multiple sections with the same name.  The section has the additional attributes C<name> and C<sub-section> so you
can work with them as appropriate.

=head3 merge

    method merge(Ujumla::Config $config)

This is not delegated, so needs to be called on the config object.  This is the method that underlies the inclusion mechanism
but is exposed if you want to implement some more complicated inclusion logic, say deciding on which configuration file to
include based on inputs that are not available until runtime.

=head2 Ujumla::FileHelper

An instance of a sub-class of C<Ujumla::FileHelper> can be supplied to the constructor as C<:$file-helper> if you want to
alter the way that the configuration files are found and loaded.  By default the C<Ujumla::FileHelper> instance is created
with the C<:@search-path> that is passed to the C<Ujumla> constructor, and the methods C<full-search-path>, C<resolve-file>,
and C<get-config-text> are used to find and read the configuration for the main and included files, you can over-ride them
as required in a sub-class if you need to change the behaviour.

=head3 new

    method new(Str :@search-path, IO::Path :@full-search-path --> Ujumla::FileHelper)

Creates a new object of the class, C<:@search-path> is a list of additional directory names that will be searched for the configuration
files, C<:@full-search-path> is the complete list of locations as C<IO::Path> objects, typically this will be populated in its accessor
method but can be provided if you only want a pre-determined list of locations.

=head3 full-search-path

    method full-search-path( --> IO::Path @)

This returns a list of C<IO::Path> objects which should be directories which will be search to locate a configuration file.
By default it combines the C<search-path> provided to the constructor, the current working directory of the process and those
directories provided as a colon separated list in the environment variable C<UJUMLA_PATH>. You may want to over-ride this (or provide
C<full-search-path> to the constructor,) if you are not in full control of the environment that your program is started in, so as to
prevent the injection of untrusted configuration.

=head3 resolve-file

    method resolve-file(Str() $file-name --> IO::Path)

This returns an C<IO::Path> object representing C<$file-name> or throws an C<X::Ujumla::NoFile> if the file does not exist. The default
implementation will return the C<IO::Path> directly if C<$file-name> is I<absolute> (as per the semantic of the filesystem,) and otherwise
iterate over C<full-search-path> until the file is found, appending C<$file-name> to each path.

You may want to over-ride this if you want to perform additional checks on the properties of the file, such as making sure it isn't world or
group writeable.

=head3  get-config-text

    method get-config-text(Str:D $file-name --> Str )

This returns the text of the configuration given C<$file-name> it will call C<resolve-file> to locate the file, you may want to over-ride
this if, for example, you have encrypted or compressed your file, but you may want to call C<callsame> to get the text before further
processing.


=end pod


class Ujumla {

    class X::Ujumla::NoFile is Exception {
        has Str $.file-name is required;
        method message( --> Str ) {
            "File '{ $!file-name }' cannot be found";
        }
    }

    class FileHelper {
        has Str @.search-path;

        has IO::Path @.full-search-path;

        method full-search-path() {
            if not @!full-search-path.elems {
                @!full-search-path = ($*CWD, |@!search-path, |(%*ENV<UJUMLA_PATH> ?? %*ENV<UJUMLA_PATH>.split(":") !! ())).map(*.IO);
            }
            @!full-search-path;
        }

        method resolve-file(Str() $file-name --> IO::Path) {
            my IO::Path $file;

            if $file-name.IO.is-absolute && $file-name.IO.f {
                $file = $file-name.IO;
            }
            else {
                for @.full-search-path.map(-> $v { $v.add($file-name) }) -> $try-file {
                    if $try-file.f {
                        $file = $try-file;
                    }
                }
            }
            $file;
        }

        method get-config-text(Str:D $file-name --> Str ) {
            if self.resolve-file($file-name) -> $file {
                $file.slurp;
            }
            else {
                X::Ujumla::NoFile.new(:$file-name).throw;
            }
        }
    }

    subset Filename of Str where { $_.IO.f };

    has Str $.config-file;

    has Str $.config-text;

    has Str @.search-path;

    has FileHelper $.file-helper;

    has %.initial-variables;

    has Bool $.include-env = False;

    method file-helper( --> FileHelper ) handles <get-config-text> {
        $!file-helper //= FileHelper.new(:@!search-path);
    }

    method config-text( --> Str ) {
        $!config-text //= self.get-config-text($!config-file);
    }

    role Section[ :$name, :$sub-section ] {
        has Str $.name = $name;
        has Str $.sub-section = $sub-section;
    }

    class Config {
        has %.items;
        has Section @.sections;

        proto method get-item(|c) { * }

        multi method get-item(Str:D $key --> Str ) {
            %!items{$key} // Str;
        }

        multi method get-item(Str:D $section, Str:D $key --> Str ) {
            my $item;
            if self.get-section($section) -> $s {
                $item = $s.get-item($key);
            }
            $item // Str;
        }

        proto method get-section(|c) { * }

        multi method get-section(Str:D $section) {
            my @sections = @!sections.grep(*.name eq $section);
            if @sections.elems > 1 {
                warn "there are more than one sections named '$section'";
            }
            @sections[0];
        }

        multi method get-section(Str:D $section, Str:D $sub-section ) {
            my @sections = @!sections.grep({ $_.name eq $section && $_.sub-section.defined && $_.sub-section eq $sub-section });
            if @sections.elems > 1 {
                warn "there are more than one sections named '$section' with sub-section '$sub-section'";
            }
            @sections[0];
        }

        method get-sections(Str:D $section) {
            my @sections = @!sections.grep(*.name eq $section);
            @sections;
        }

        method merge(Config:D $other-config) {
            @!sections.append: $other-config.sections;

            for $other-config.items.kv -> $k, $v {
                %!items{$k} = $v;
            }
        }
    }

    grammar Grammar {
        rule TOP {
            <config-content>
        }
        rule  config-content {
            [ <.comment> || <config-line> || <config-section> || <include> || <.empty-or-blank>  ]+
        }
        token name { <[\S] - [<>=]>+ }
        token section-name { <[\S] - [/<>=]>+ }
        token quote { <['"]> }
        token env-name { <.alpha>+ }
        token include-name {
            <[\S] - [>]>+
        }
        rule include {
            '<<'<[Ii]>nclude\h+<include-name>'>>'
        }
        rule empty-or-blank { [ <blank-line> | <empty-line> ] }
        rule blank-line { ^^\h*$$ }
        rule empty-line { ^^$$ }
        rule  value { <env-replace> | <simple-value> | <here-doc> }
        token simple-value { <!after ['<<'|'__']><!start-here-doc>[ \N | <.quoted-line-break> ]*<!shell-comment>  }
        token replace-value { <[\N] - [)]>* }
        regex env-replace { '__env('\h*<env-name>\h*','\h*<replace-value>\h*')__' }
        regex quoted-line-break {
            '\\'\n
        }
        token start-here-doc { '<<' }
        rule here-doc {
            <start-here-doc><name>
            $<here-doc-value>=[.*?]
            $<name>
        }
        rule  comment { <empty-comment> | <shell-comment> | <c-comment> }
        token c-comment-start { '/*' }
        token c-comment-end   { '*/' }
        rule c-comment {
            <c-comment-start>
            .*?
            <c-comment-end>
        }
        regex shell-comment { \h*'#'\N* }
        regex empty-comment { ^^\h*'#'\h*$$ }
        rule config-line {
            \h*<name><.separator><value> <shell-comment>?
        }
        token separator {
            <equals> | <space>
        }
        token space { \h+ }
        token equals { \h* '=' \h* }
        token not-ge {
            <-[>]>
        }
        token sub-section-name {
            [ <.quote><not-ge>*<.quote> | <[\S] - [>]>+ ]
        }
        rule config-section {
            '<'
               <section-name> <sub-section-name>?
            '>'
               <config-content>*
            '</' :i $<section-name> '>'
        }
    }

    class Actions {

        has FileHelper $.file-helper is required handles <get-config-text>;

        has %.initial-variables;

        has Bool $.include-env = False;

        has @!replace-stack = ( {}, );

        submethod TWEAK {
            my %vars = (|( $!include-env ?? %*ENV !! {} ), |%!initial-variables);
            @!replace-stack = ( %vars, );
        }

        method current( --> Hash ) {
            @!replace-stack.tail;
        }

        method enter-scope() {
            my %current = |self.current;
            @!replace-stack.push: %current;
        }

        method leave-scope() {
            @!replace-stack.pop;
        }


        method expand(Str() $str --> Str ) {
            my %replace = self.current;

            my &replace = sub ( $/ ) {
                my $key = $/<key>;

                if %replace{$key}:exists {
                    %replace{$key}
                }
                else {
                    ~$/;
                }
            };
            $str.subst(/'$''{'?$<key>=<.ident>+'}'?/, &replace, :g);
        }

        method dequote( Str $str --> Str ) {
            $str.subst(/<Grammar::shell-comment>/, '').subst(/^$<quote>=<['"]>?$<value>=[.*]$<quote>$/, { $<value> });
        }

        method TOP( $/ ) {
            $/.make: $/<config-content>.made;
        }

        method config-content($/) {
            my $config = Config.new( items => ($/<config-line>».made).hash, sections => $/<config-section>».?made);
            for $/<include> -> $i {
                if $i.?made -> $inc {
                    $config.merge($inc);
                }
                else {
                    note "failed to parse included file '{ $i<include-name> }'";
                }
            }
            $/.make: $config;
        }
        method config-line( $/ ) {
            $/.make: $/<name>.made => $/<value>.made;
            self.current{$/<name>.made} = $/<value>.made;
        }

        method section-name( $/ ) {
            self.enter-scope;
            $/.make: self.expand(~$/);
        }

        method config-section( $/ ) {
            my $sub-section = $/<sub-section-name> ?? self.expand($/<sub-section-name>) !! Str;

            $/.make: $/<config-content>.first.made but Section[name => $/<section-name>.made, :$sub-section] ;
            self.leave-scope;
        }

        method name( $/ ) {
            $/.make: self.expand(~$/);
        }

        method value($/) {
            $/.make: self.dequote(self.expand($/<env-replace>.made // $/<simple-value>.made // $/<here-doc>.made));
        }

        method here-doc( $/ ) {
            $/.make: ~$/<here-doc-value>;
        }

        method simple-value($/) {
            $/.make: ~$/;

        }

        method env-name($/) {
            $/.make: ~$/;
        }

        method replace-value($/) {
            $/.make: ~$/;
        }

        method env-replace($/) {
            $/.make: do {
                %*ENV{$/<env-name>.made} // $/<replace-value>.made
            }
        }

        method include($match) {
            $match.make: Grammar.parse(self.get-config-text($match<include-name>.made), actions => self).?made;
        }

        method include-name($/) {
            $/.make: $/.Str;
        }

    }

    has Actions $.actions;

    method actions( --> Actions ) {
        $!actions //= Actions.new(file-helper => self.file-helper, :%!initial-variables, :$!include-env);
    }

    has Config $.config;

    method config(--> Config) handles <get-item get-section get-sections> {
        $!config //= do {
            Grammar.parse(self.config-text, actions => self.actions).?made;
        }
    }
}
# vim: expandtab shiftwidth=4 ft=raku
