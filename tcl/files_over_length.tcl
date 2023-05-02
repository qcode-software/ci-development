proc files_over_length_report {
    files
    max_file_length
} {
    #| Report files that have more lines than max file length.

    set report [list]

    foreach file $files {
        set contents [linter_cat $file]
        set line_count [llength [split $contents "\n"]]

        if { $line_count > $max_file_length } {
            lappend report "The file $file has $line_count lines."
        }
    }

    return [join $report "\n"]
}

proc files_over_length_count {
    files
    max_file_length
} {
    #| Count the number of files that have more lines than max file length.

    set count 0

    foreach file $files {
        set contents [linter_cat $file]
        set line_count [llength [split $contents "\n"]]

        if { $line_count > $max_file_length } {
            incr count
        }
    }

    return $count
}
