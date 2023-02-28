proc linter_report_lines_over_length {
    file
    max_line_length
} {
    #| Report lines in the file that have more chars than max line length.

    try {
        set handle [open $file r]
        set contents [read $handle]
        set report [list]
        set line_no 1

        foreach line [split $contents "\n"] {
            set line_length [string length $line]
            if { $line_length > $max_line_length } {
                set partial_line [string range [string trimleft $line] 0 15]

                set details "Line $line_no in file $file is $line_length chars long"
                append details " - ${partial_line}..."

                lappend report $details
            }

            incr line_no
        }

        return $report
    } on error [list message options] {
        error $message [dict get $options -errorinfo] [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

proc linter_report_procs_without_filename_prefix {file} {
    #| Report proc names that are not prefixed with the file name.

    try {
        set handle [open $file r]
        set contents [read $handle]
        set filename [file tail $file]
        set length [string length [file extension $file]]
        set prefix [string range $filename 0 end-$length]
        set report [list]

        set proc_names [linter_proc_names_parse $contents]

        foreach proc_name $proc_names {
            if { ![string match "${prefix}*" $proc_name] } {
                lappend report "The proc name \"$proc_name\" in file $filename is not\
                                prefixed with \"$prefix\"."
            }
        }

        return $report
    } on error [list message options] {
        error $message [dict get $options -errorinfo] [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

proc linter_proc_names_parse {string} {
    #| Parse any proc names from the given string without their namespaces.

    set pattern {^\s*proc\s+:{0,2}(?:[a-z0-9_-]+::)*([a-z0-9_-]+)\s+\{}
    set matches [regexp -lineanchor -all -inline -- $pattern $string]
    set proc_names [list]

    foreach {match_string proc_name} $matches {
        lappend proc_names $proc_name
    }

    return $proc_names
}

proc linter_tcl_commands {script} {
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

proc linter_file_proc_lengths {file} {
    #| Returns proc names and the line count of the body of each proc within the
    #| given file.

    try {
        set handle [open $file r]
        set contents [read $handle]

        return [linter_proc_lengths $contents]
    } on error [list message options] {
        error $message [dict get $options -errorinfo] [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

proc linter_proc_lengths {string} {
    #| Returns proc names and the line count of the body of each proc within the
    #| given string.

    set commands [linter_tcl_commands $string]
    set proc_lengths [dict create]

    foreach command $commands {
        switch -regexp $command {
            {^proc} {
                set proc_name [lindex $command 1]
                set proc_body [lindex $command 3]
                set body_length [llength [split [string trim $proc_body] "\n"]]
                set query_count [llength [linter_sql_query_indices $proc_body]]
                set query_length [linter_sql_queries_length $proc_body]
                set body_length [expr {$body_length - $query_length + $query_count}]

                dict set proc_lengths $proc_name $body_length
            }
            {^namespace eval} {
                set proc_lengths [dict merge \
                                      $proc_lengths \
                                      [linter_proc_lengths [lindex $command 3]]]
            }
        }
    }

    return $proc_lengths
}

proc linter_sql_queries_length {string} {
    #| Get the combined length of all SQL queries in a string.

    set line_count 0

    foreach indices [linter_sql_query_indices $string] {
        set query [string range $string [lindex $indices 0] [lindex $indices 1]]
        incr line_count [llength [split $query "\n"]]
    }

    return $line_count
}

proc linter_sql_query_indices {string} {
    #| Get the indexes of SQL queries in a string.

    set pattern {(?:\{(?:\s)*select[^\}]+\sfrom\s+[^\}]+\})}
    append pattern {|(?:\{(?:\s)*insert\s+into[^\}]+\})}
    append pattern {|(?:\{(?:\s)*update[^\}]+set[^\}]+\})}
    append pattern {|(?:\{(?:\s)*delete\s+from[^\}]+\})}

    return [regexp -all -inline -indices $pattern $string]
}
