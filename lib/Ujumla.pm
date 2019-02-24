use v6;

class Ujumla {
    grammar Grammar {
        rule TOP {
            <config-content>
        }
        rule  config-content {
            [ | <config-line> | <config-section> | <.comment> ]+
        }
        token name { \w+ }
        token quote { <['"]> }
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
        rule shell-comment { ^^ \s* '#' \N*    }
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
}
# vim: expandtab shiftwidth=4 ft=perl6
