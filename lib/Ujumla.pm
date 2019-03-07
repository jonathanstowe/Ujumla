use v6;

no precompilation;
use Grammar::Tracer;
class Ujumla {
    grammar Grammar {
        rule TOP {
            <config-content>
        }
        rule  config-content {
            [ | <config-line> | <config-section> | <include> | <.comment> | <.empty-or-blank>  ]+
        }
        token name { <[\S] - [/<>=]>+ }
        token quote { <['"]> }
        token env-name { <alpha>+ }
        token include-name {
            <[\S] - [>]>+
        }
        rule include {
            '<<'<[Ii]>nclude\h+<include-name>'>>'
        }
        rule empty-or-blank { [ <blank-line> | <empty-line> ] }
        rule blank-line { ^^\h*$$ }
        rule empty-line { ^^$$ }
        rule  value { <simple-value> | <here-doc> }
        token simple-value { <!after '<<'>[ \N | <.quoted-line-break> ]* }
        rule env-replace { '__env('\h*<env-name>\h*','\h*<simple-value>\h*')__' }
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
        token section-name {
            [ <.quote><not-ge>*<.quote> | <[\S] - [>]>+ ]
        }
        rule config-section {
            '<'
               <name> <section-name>?
            '>'
               <config-content>*
            '</' :i $<name> '>'
        }
    }

    class Actions {
    }
}
# vim: expandtab shiftwidth=4 ft=perl6
