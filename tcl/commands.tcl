# {
#     command proc {
#         unquoted_string hello_world
#         literal {{line}}
#         literal {
#             comment {\#| Prints the line to stdout.}
#             command puts {
#                 variable {$line}
#             }
#             command return {
#                 unquoted_string 1
#             }
#         }
#     }
# }

# command name could be in quotes or curly braces
# consider parsing these out of the command name

# how do you tell the difference between a string literal and a script?
# Requires guidance to parse scripts further.
# A data structure to identify how each part of a command should be treated. E.g.
#   * proc {string name} {list args} {script body}
#
# According to this definition one now knows that the third argument can be treated
# as a list and format appropriately.
# The fourth arg is identified as a script so can be parsed further for commands.
#
# Configurations for built in Tcl commands and allow users to define additional
# configurations for their own defined procs.

# if {expression} {script}
# foreach {string} {command, variable, or list} {script}
# dict for {list} {command, variable, or dict} {script}
# db_0or1row {command, variable, or string} {script} ?{script}?

proc commands_parse {string} {
    #| Parse commands in the string into a data structure that identifies the
    #| commands and tokens in their arguments.

    # Flatten the commands by replacing line continuations.
    regsub -all {(\s+\\|\\)\n\s*} $string " " flattened
    set commands [list]

    foreach command [commands $flattened] {

        if { [string index [string trim $command] 0] eq "#" } {
            set command [list comment [string trimleft $command]]
        } else {
            set words [words $command]
            set command_name [string trimleft [lindex $words 0] " "]
            set command [list command $command_name]

            # TODO parse commands according to a schema/config that gives
            # context about what to parse further.
            # E.g. proc body, foreach body, dict for body, while body, and
            #      user-defined commands like qc::db_0or1row
            if { $command_name eq "proc" } {
                set parsed_args [command_args_tokens_parse [lrange $words 1 end-1]]
                lappend parsed_args \
                    script [commands_parse [string range [lindex $words end] 1 end-1]]
                lappend command $parsed_args
            } elseif { [llength $words] > 1 } {
                lappend command [command_args_tokens_parse [lrange $words 1 end]]
            }
        }

        lappend commands $command
    }

    return $commands
}

proc command_args_tokens_parse {words} {
    #| Parse the tokens from the command arg words.
    set parsed_args [list]

    foreach word $words {
        set trimmed [string trim [string trimleft $word "\\"]]

        switch [string index $trimmed 0] {
            \" {
                lappend parsed_args string_quoted $trimmed
            }
            \{ {
                lappend parsed_args string_braced $trimmed
            }
            \[ {
                set command [string range $trimmed 1 end-1]
                lappend parsed_args {*}[commands_parse $command]
            }
            \$ {
                lappend parsed_args variable $trimmed
            }
            default {
                lappend parsed_args bareword $trimmed
            }
        }
    }

    return $parsed_args
}


proc commands {script} {
    namespace upvar [namespace current] commands_info report
    set report {}
    set commands {}
    set command {}
    set comment 0
    set lineidx 0
    set offset 0
    foreach line [split $script \n] {
        set parts [split $line \;]
        set numparts [llength $parts]
        set partidx 0
        while 1 {
            set parts [lassign $parts[set parts {}] part]
            if {[string length $command]} {
                if {$partidx} {
                    append command \;$part
                } else {
                    append command \n$part
                }
            } else {
                set partlength [string length $part]
                set command [string trimleft $part[set part {}] "\f\n\r\t\v "]
                incr offset [expr {$partlength - [string length $command]}]
                if {[string match #* $command]} {
                    set comment 1
                }
            }

            if {$command eq {}} {
                incr offset
            } elseif {(!$comment
                       || ($comment
                           && (!$numparts
                               || ![llength $parts])))
                      && [info complete $command\n]} {

                lappend commands $command
                set info [dict create character $offset line $lineidx]
                set offset [expr {$offset + [string length $command] + 1}]
                lappend report $info
                set command {}
                set comment 0
                set info {}
            }

            incr partidx
            if {![llength $parts]} break
        }
    }

    incr lineidx

    if {$command ne {}} {
        error [list {incomplete command} $command]
    }

    return $commands
}

proc words cmd {
    if {![info complete $cmd]} {
        error [list {not a complete command} $cmd]
    }
    set words {}
    set logical {}
    set cmd [string trimleft $cmd[set cmd {}] "\f\n\r\t\v " ]
    while {[regexp {([^\f\n\r\t\v ]*)([\f\n\r\t\v ]+)(.*)} $cmd full first delim last]} {
        append logical $first
        if {[info complete $logical\n]} {
            lappend words $logical
            set logical {}
        } else {
            append logical $delim
        }
        set cmd $last[set last {}]
    }
    if {$cmd ne {}} {
        append logical $cmd
    }
    if {$logical ne {}} {
        lappend words $logical 
    }
    return $words
}

proc scripted_list script {
    concat {*}[lmap part [commands $script] {
        if {[string match #* $part]} continue
        uplevel 1 list $part
    }]
}

proc wordparts word {
    set parts {}
    set first [string index $word 0]

    if {$first in {\" \{}} { ;#P syche! "
        # Remove quotes and curly braces from the word.
        set last [string index $word end]
        set wantlast [dict get {\" \" \{ \}} $first] ;#P syche! "
        if {$last ne $wantlast} {
            error [list [list missing trailing [
                dict get {\" quote \{ brace} $first]]] ;#P syche! "
        }
        set word [string range $word[set word {}] 1 end-1]
    }

    
    if {$first eq "\{"} {
        set obracecount 0
        set cbracecount 0
        set part {}
        while {$word ne {}} {
            switch -regexp -matchvar rematch $word [scripted_list {
                #these seem to be the only characters Tcl accepts as whitespace
                #in this context
                {^([{}])(.*)} {
                    if {[string index $word 0] eq "\{"} {
                        incr obracecount
                    } else {
                        incr cbracecount
                    }
                    lassign $rematch -> 1 word 
                    append part $1
                }
                {^(\\[{}])(.*)} {
                    lassign $rematch -> 1 word 
                    append part $1
                }
                {^(\\+\n[\x0a\x0b\x0d\x20]*)(.*)}  {
                    lassign $rematch -> 1 word
                    if {[regexp -all {\\} $1] % 2} {
                        if {$part ne {}} {
                            lappend parts $part
                            set part {}
                        }
                        lappend parts $1
                    } else {
                        append part $1
                    }
                }
                {^(.+?(?=(\\?[{}])|(\\+\n)|$))(.*$)} {
                    lassign $rematch -> 1 word
                    append part $1
                } 
                default {
                    error [list {no match} $word]
                }
            }]
        }

        if {$cbracecount != $obracecount} {
            error [list {unbalanced braces in braced word}]
        }

        if {$part ne {}} {
            lappend parts $part
        }
        return $parts
    } else {
        set expression [scripted_list {
            #order matters in some cases below

            {^(\$(?:::|[A-Za-z0-9_])*\()(.*)} - 
            {^(\[)(.*)} {
                if {[string index $word 0] eq {$}} {
                    set re {^([^)]*\))(.*)}
                    set errmsg {incomplete variable name}
                } else {
                    set re {^([^]]*])(.*)}
                    set errmsg {incomplete command substitution}
                }
                lassign $rematch -> 1 word
                while {$word ne {}} {
                    set part {}
                    regexp $re $word -> part word
                    append 1 $part
                    if {[info complete $1]}  {
                        lappend parts $1
                        break
                    } elseif {$word eq {}} {
                        error [list $errmsg $1] 
                    }
                }
            }

            #these seem to be the only characters Tcl accepts as whitespace
            #in this context
            {^(\\\n[\x0a\x0b\x0d\x20]*)(.*)} -
            {^(\$(?:::|[A-Za-z0-9_])+)(.*)} -
            {^(\$\{[^\}]*\})(.*)} -
            #detect a single remaining backlsash or dollar character here
            #to avoid a more complicated re below
            {^(\\|\$)($)} -
            {^(\\[0-7]{1,3})(.*)} -
            {^(\\U[0-9a-f]{1,8})(.*)} -
            {^(\\u[0-9a-f]{1,4})(.*)} -
            {^(\\x[0-9a-f]{1,2})(.*)} -
            {^(\\.)(.*)} -
            #lookahead ensures that .+ matches non-special occurrences of
            #"$" character
            #non greedy match here, so make sure .*$ stretches the match to
            #the end, so that something ends up in $2
            {(?x)
                #non-greedy so that the following lookahead stops it at the
                #first chance 
                ^(.+?
                    #stop at and backslashes
                    (?=(\\
                        #but only if they aren't at the end of the word 
                        (?!$))
                    #also stop at brackets
                    |(\[)
                    #and stop at variables
                    |(\$(?:[\{A-Za-z0-9_]|::))
                    #or at the end of the word
                    |$)
                )
                #the rest of the word
                (.*$)} {

                lassign $rematch -> 1 word 
                lappend parts $1
            } 
            default {
                error [list {no match} $word]
            }
        }]
        while {$word ne {}} {
            set part {}
            switch -regexp -matchvar rematch $word $expression
        }
    }
    return $parts
}

proc varparts varspec {
    # varspec is already stripped of $ and braces
    set res {}
    if {[regexp {([^\)]*)(?:(\()(.*)(\)))?$} $varspec -> name ( index )]} {
        lappend res $name
    }
    if {${(} eq {(}} {
        lappend res $index
    }
    return $res
}
