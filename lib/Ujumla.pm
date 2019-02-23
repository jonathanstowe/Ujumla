use v6;

class Ujumla {
    grammar Grammar {
        rule  TOP {
            [ <config-line> | <comment> ]+
        }
        token name { \w+ }
        token quote { <['"]> }
        token value { \N* }
        rule comment { ^^ \s* '#' .*?   $$ }
        rule config-line {
            <name><.separator><value>
        }
        token separator {
            <space>|<equals>
        }
        token space { \s+ }
        token equals { \s* '=' \s* }
    }
}
# vim: expandtab shiftwidth=4 ft=perl6
