use v6;

#no precompilation;
#use Grammar::Tracer::Compact;

class Ujumla {

    subset Filename of Str where { $_.IO.f };

    has Filename $.config-file;

    has Str $.config-text;

    method config-text( --> Str ) {
        $!config-text //= $!config-file.IO.slurp;
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
        token simple-value { <!after ['<<'|'__']>[ \N | <.quoted-line-break> ]* }
        token replace-value { <[\N] - [)]>* }
        regex env-replace { '__env('\h*<env-name>\h*','\h*<replace-value>\h*')__' }
        regex quoted-line-break {
            '\\'\n
        }
        rule here-doc {
            '<<'<name>
            $<value>=[.*?]
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
        rule shell-comment { ^^ \h* <!after '\\'>'#' \N* }
        rule config-line {
            <name><.separator><value>
        }
        token separator {
            <space>|<equals>
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

        method config-line( $/ ) {
            say ">>" ~ $/<name>.made => $/<value>.made;
        }

        method name( $/ ) {
            $/.make: ~$/;
        }

        method value($/) {
            $/.make: $/<env-replace>.made // $/<simple-value>.made // $/<here-doc>.made;
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
}
# vim: expandtab shiftwidth=4 ft=perl6
