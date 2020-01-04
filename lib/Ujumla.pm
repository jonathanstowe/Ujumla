use v6;

# no precompilation;
# use Grammar::Tracer::Compact;

class Ujumla {

    subset Filename of Str where { $_.IO.f };

    has Filename $.config-file;

    has Str $.config-text;

    method config-text( --> Str ) {
        $!config-text //= $!config-file.IO.slurp;
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
        has IO $.input-file;
        has    $.config;

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
            $/.make: Config.new( items => ($/<config-line>».made).hash, sections => $/<config-section>».?made);
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

    }

    has Config $.config;

    method config(--> Config) handles <get-item get-section get-sections> {
        $!config //= do {
            Grammar.parse(self.config-text, actions => Actions.new).?made;
        }
    }
}
# vim: expandtab shiftwidth=4 ft=perl6
