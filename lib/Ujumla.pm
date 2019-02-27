use v6;

no precompilation;
use Grammar::Tracer;
class Ujumla {
    grammar Grammar {
        rule TOP {
            <config-content>
        }
        rule  config-content {
            [ | <config-line> | <config-section> | <.comment> | <.empty-or-blank>  ]+
        }
        token name { \w+ }
        token quote { <['"]> }
        rule empty-or-blank { [ <blank-line> | <empty-line> ] }
        rule blank-line { ^^\h*$$ }
        rule empty-line { ^^$$ }
        rule  value { <simple-value> | <here-doc> }
        token simple-value { \N* }
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
        token space { \s+ }
        token equals { \s* '=' \s* }
        rule config-section {
            '<'
               <name> <simple-value>?
            '>'
               <config-content>*
            '</' $<name> '>'
        }
    }

    class Actions {
    }
}
# vim: expandtab shiftwidth=4 ft=perl6
