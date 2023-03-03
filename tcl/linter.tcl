proc linter_files_over_length {
    files
    max_file_length
} {
    #| Get files that have more lines than max file length.

    set long_files [dict create]

    foreach file $files {
        try {
            set handle [open $file r]
            set contents [read $handle]
            set lines [split $contents "\n"]
            set count [llength $lines]

            if { $count > $max_file_length } {
                dict set long_files $file $count
            }
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

    return $long_files
}

proc linter_report_files_over_length {
    files
    max_file_length
} {
    #| Report files that have more lines than max file length.

    set long_files [linter_files_over_length $files $max_file_length]
    set count 0

    dict for {filename line_count} $long_files {
        puts "The file $filename has $line_count lines."
        incr count
    }

    return $count
}

proc linter_lines_over_length {
    files
    max_line_length
} {
    #| Get lines in the files that have more chars than max line length.

    set long_lines [dict create]

    foreach file $files {
        try {
            set handle [open $file r]
            set contents [read $handle]
            set report [list]
            set line_no 1

            foreach line [split $contents "\n"] {
                set line_length [string length $line]

                if { $line_length > $max_line_length } {
                    dict lappend long_lines $file [dict create \
                                                       line $line \
                                                       line_length $line_length \
                                                       line_no $line_no]
                }

                incr line_no
            }
        } on error [list message options] {
            error $message [dict get $options -errorinfo] [dict get $options -errorcode]
        } finally {
            if { [info exists handle] } {
                close $handle
            }
        }
    }

    return $long_lines
}

proc linter_report_lines_over_length {
    files
    max_line_length
} {
    #| Report lines in the files that have more chars than max line length.

    set long_lines [linter_lines_over_length $files $max_line_length]
    set count 0

    dict for {filename line_details} $long_lines {
        foreach line_detail $line_details {
            set line_no [dict get $line_detail line_no]
            set line_length [dict get $line_detail line_length]
            set line [dict get $line_detail line]
            set partial_line [string range [string trimleft $line] 0 15]

            set output "Line $line_no in file $filename is $line_length chars long"
            append output " - ${partial_line}..."

            puts $output

            incr count
        }
    }

    return $count
}

proc linter_procs_without_filename_prefix {files} {
    #| Get procs that are not prefixed with the name of the file that they are in.

    set procs [dict create]

    foreach file $files {
        try {
            set handle [open $file r]
            set contents [read $handle]
            set filename [file tail $file]
            set length [string length [file extension $file]]
            set prefix [string range $filename 0 end-$length]
            set proc_names [linter_proc_names_parse $contents]
            set not_prefixed [list]

            foreach proc_name $proc_names {
                if { ![string match "${prefix}*" $proc_name] } {
                    lappend not_prefixed $proc_name
                }
            }

            if { [llength $not_prefixed] > 0 } {
                dict set procs $file $prefix $not_prefixed
            }
        } on error [list message options] {
            error $message [dict get $options -errorinfo] [dict get $options -errorcode]
        } finally {
            if { [info exists handle] } {
                close $handle
            }
        }
    }

    return $procs
}

proc linter_report_procs_without_filename_prefix {files} {
    #| Report procs that are not prefixed with the name of the file that they are in.

    set procs [linter_procs_without_filename_prefix $files]
    set count 0

    dict for {filename prefix_procs} $procs {
        set prefix [lindex $prefix_procs 0]
        set proc_names [lindex $prefix_procs 1]

        foreach proc_name $proc_names {
            puts "The proc name \"$proc_name\" in file $filename is not prefixed\
                  with \"$prefix\"."
            incr count
        }
    }

    return $count
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

proc linter_procs_over_length {
    files
    max_proc_length
} {
    #| Get procs that have a body line count over max proc length.

    set long_procs [dict create]

    foreach file $files {
        try {
            set handle [open $file r]
            set contents [read $handle]

            set proc_lengths [linter_proc_lengths $contents]

            dict for {proc_name body_length} $proc_lengths {
                if { $body_length > $max_proc_length } {
                    dict set long_procs $file $proc_name $body_length
                }
            }
        } on error [list message options] {
            error $message [dict get $options -errorinfo] [dict get $options -errorcode]
        } finally {
            if { [info exists handle] } {
                close $handle
            }
        }
    }

    return $long_procs
}

proc linter_report_procs_over_length {files max_proc_length} {
    #| Report procs that have a body line count over max proc length.

    set long_procs [linter_procs_over_length $files $max_proc_length]
    set count 0

    dict for {filename procs} $long_procs {
        dict for {proc_name body_length} $procs {
            puts "The proc \"$proc_name\" in file $filename has a body that is\
                  $body_length lines long."
            incr count
        }
    }

    return $count
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

proc linter_procs_first_line {string} {
    #| Get the first line for each proc in the string.

    set proc_lines [dict create]
    set commands [linter_tcl_commands $string]

    foreach command $commands {
        switch -regexp $command {
            {^proc} {
                set proc_name [lindex $command 1]
                set body_lines [split [string trim [lindex $command 3]] "\n"]
                dict set proc_lines $proc_name [lindex $body_lines 0]
            }
            {^namespace eval} {
                set proc_lines [dict merge \
                                    $proc_lines \
                                    [linter_procs_first_line [lindex $command 3]]]
            }
        }
    }

    return $proc_lines
}

proc linter_procs_without_proc_comment {files} {
    #| Procs without a comment at the beginning of the body.

    set procs [dict create]

    foreach file $files {
        ::try {
            set handle [open $file r]
            set contents [read $handle]
            set proc_lines [linter_procs_first_line $contents]

            dict for {proc_name line} $proc_lines {
                if { ![regexp {^#.*} $line] } {
                    dict lappend procs $file $proc_name
                }
            }
        } on error [list message options] {
            error \
                $message \
                [dict get $options -errorinfo] \
                [dict get $options -errorinfo]
        } finally {
            if { [info exists handle] } {
                close $handle
            }
        }
    }

    return $procs
}

proc linter_report_procs_without_proc_comment {files} {
    #| Report procs that do not have a comment at the beginning of the body.

    set procs [linter_procs_without_proc_comment $files]
    set count 0

    dict for {file_name procs} $procs {
        foreach proc_name $procs {
            puts "The proc $proc_name in file $file_name does not have a proc comment."
            incr count
        }
    }

    return $count
}
