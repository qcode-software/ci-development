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
                
                set details "[file tail $file] :: line $line_no :: "
                append details "length: $line_length chars :: ${partial_line}..."

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
                lappend report "$filename :: $proc_name"
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

# proc linter_procs_get {string} {

#     set lines [split $string "\n"]
#     set pattern {^\s*proc\s+:{0,2}(?:[a-z0-9_-]+::)*(?:[a-z0-9_-]+)\s+}
#     set line_no 1
#     set procs_starts [list]

#     foreach line $lines {
#         if { [regexp $pattern $line] } {
#             lappend procs_starts $line_no
#         }

#         incr line_no
#     }

#     set proc_lines [list]
#     set count [llength $proc_starts]

#     if { [llength $procs_starts] == 1} {
#         set proc_ends $line_no
#     }
# }

# proc linter_proc_body_length {contents} {
#     # Get indexes of proc definitions.
#     # Need to parse:
#     # "proc"
#     # proc name
#     # arguments
#     # body

#     # Proc line count begins at body start.

#     # What if "{" appears in a string somewhere?
#     #   Would it always be preceded by a backslash?

#     set paren_count 0
#     set end_index 0

#     foreach character [split [string trim $contents] ""] {
#         if { $character eq "{" } {
#             incr paren_count
#         } elseif { $character eq "}" } {
#             incr paren_count -1
#         }

#         if { $paren_count == 0 } {
#             incr end_index
#         }
#     }
# }

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

proc linter_proc_lengths {file} {

    try {
        set handle [open $file r]
        set contents [read $handle]
        set commands [linter_tcl_commands $contents]
        set proc_lengths [dict create]

        foreach command $commands {
            if { [lindex $command 0] eq "proc" } {
                set proc_name [lindex $command 1]
                set body_length [llength [split [string trim [lindex $command 3]] "\n"]]

                dict set proc_lengths $proc_name $body_length
            }
        }

        return $proc_lengths
    } on error [list message options] {
        error $message [dict get $options -errorinfo] [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}
