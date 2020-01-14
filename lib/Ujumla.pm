use v6;

# no precompilation;
# use Grammar::Tracer::Compact;

class Ujumla {

    class X::Ujumla::NoFile is Exception {
        has Str $.file-name is required;
        method message( --> Str ) {
            "File '{ $!file-name }' cannot be found";
        }
    }

    class FileHelper {
        #| This is the user-visible path
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
            [ | <comment> | <config-line> | <config-section> | <include> | <.empty-or-blank>  ]+
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
        token simple-value { <!after ['<<'|'__']><!start-here-doc>[ \N | <.quoted-line-break> ]* }
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
        rule  comment { <shell-comment> | <c-comment> }
        token c-comment-start { '/*' }
        token c-comment-end   { '*/' }
        rule c-comment {
            <c-comment-start>
            .*?
            <c-comment-end>
        }
        regex shell-comment { ^^ \h* <!after '\\'>'#' \N* }
        rule config-line {
            <name><.separator><value>
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

        has @!replace-stack = ( {}, );

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
            $str.subst(/^$<quote>=<['"]>?$<value>=[.*]$<quote>$/, { $<value> });
        }

        method TOP( $/ ) {
            $/.make: $/<config-content>.made;
        }

        method config-content($/) {
            my $config = Config.new( items => ($/<config-line>».made).hash, sections => $/<config-section>».?made);
            for $/<include> -> $i {
                $config.merge($i.?made);
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

    has Config $.config;

    method config(--> Config) handles <get-item get-section get-sections> {
        $!config //= do {
            Grammar.parse(self.config-text, actions => Actions.new(file-helper => self.file-helper)).?made;
        }
    }
}
# vim: expandtab shiftwidth=4 ft=perl6
