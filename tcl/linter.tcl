proc cat {file} {
    #| Get the contents of a file.

    try {
        set handle [open $file r]
        return [read $handle]
    } on error [list message options] {
        error \
            $message \
            [dict get $options -errorinfo] \
            [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

proc proc_names_parse {string} {
    #| Parse any proc names from the given string without their namespaces.

    set pattern {^\s*proc\s+:{0,2}((?:[a-z0-9_-]+::)*(?:[a-z0-9_-]+))\s+\{}
    set matches [regexp -lineanchor -all -inline -- $pattern $string]
    set proc_names [list]

    foreach {match_string proc_name} $matches {
        lappend proc_names $proc_name
    }

    return $proc_names
}

proc tcl_commands {script} {
    #| Get Tcl commands that are in the script.
    #|
    #| Original author: PYK.
    #| https://wiki.tcl-lang.org/page/cmdSplit

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
            } elseif {(!$comment || (
                    $comment && (!$numparts || ![llength $parts])))
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

proc proc_lengths {string} {
    #| Returns proc names and the line count of the body of each proc within the
    #| given string.

    set commands [tcl_commands $string]
    set proc_lengths [dict create]

    foreach command $commands {
        switch -regexp $command {
            {^proc} {
                set proc_name [lindex $command 1]
                set proc_body [lindex $command 3]
                set body_length [llength [split [string trim $proc_body] "\n"]]
                set query_count [llength [sql_query_indices $proc_body]]
                set query_length [sql_queries_length $proc_body]
                set body_length [expr {$body_length - $query_length + $query_count}]

                dict set proc_lengths $proc_name $body_length
            }
            {^namespace eval} {
                set proc_lengths [dict merge \
                                      $proc_lengths \
                                      [proc_lengths [lindex $command 3]]]
            }
        }
    }

    return $proc_lengths
}


