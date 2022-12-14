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
