proc lines_over_length_report {
    files
    max_line_length
} {
    #| Report lines that have more characters than max line length.

    set report [list]

    foreach file $files {
        set contents [linter_cat $file]
        set line_no 1

        foreach line [split $contents "\n"] {
            set line_length [string length $line]

            if { $line_length > $max_line_length } {
                set partial_line [string range [string trimleft $line] 0 15]
                lappend report "Line $line_no in file $file is $line_length chars long\
                                - ${partial_line}..."
            }

            incr line_no
        }
    }

    return [join $report "\n"]
}

proc lines_over_length_count {
    files
    max_line_length
} {
    #| Count the number of lines that have more characters than max line length.

    set count 0

    foreach file $files {
        set contents [linter_cat $file]

        foreach line [split $contents "\n"] {
            if { [string length $line] > $max_line_length } {
                incr count
            }
        }
    }

    return $count
}
