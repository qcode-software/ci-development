proc procs_over_length_report {
    files
    max_proc_length
} {
    #| Report procs that have a body line count over max proc length.

    set report [list]

    foreach file $files {
        set contents [linter_cat $file]

        dict for {proc_name body_length} [linter_proc_lengths $contents] {
            if { $body_length > $max_proc_length } {
                lappend report "The proc \"$proc_name\" in file $file has a body that is\
                                $body_length lines long."
            }
        }
    }

    return [join $report "\n"]
}

proc procs_over_length_count {
    files
    max_proc_length
} {
    #| Count the number of procs that have a body line count over max proc length.

    set count 0

    foreach file $files {
        set contents [linter_cat $file]

        dict for {proc_name body_length} [linter_proc_lengths $contents] {
            if { $body_length > $max_proc_length } {
                incr count
            }
        }
    }

    return $count
}
