proc linter_report_lines_over_length {
    file
    max_line_length
} {
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
    try {
        set handle [open $file r]
        set contents [read $handle]
        set line_no 1
        set filename [file tail $file]
        set length [string length [file extension $file]]
        set prefix [string range $filename 0 end-$length]
        set report [list]

        foreach line [split $contents "\n"] {
            if { [regexp {^\s*proc\s(.+)\s+\{} $line -> proc_name]
                 && ![string match "${prefix}*" $proc_name] } {
                lappend report "$filename :: Line $line_no :: $proc_name"
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
