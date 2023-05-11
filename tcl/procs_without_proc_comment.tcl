proc procs_without_proc_comment {string} {
    #| Get a list procs that don't have a proc comment.

    set procs [list]
    set commands [tcl_commands $string]

    foreach command $commands {
        set words [tcl_command_words $command]
        set command_name [lindex $words 0]

        if { $command_name eq "proc" } {
            lassign $words \
                command_name \
                proc_name \
                args \
                body
            set body_lines [split [string trim [join $body]] "\n"]

            if { [lsearch -regexp $body_lines {^#\|}] == -1 } {
                lappend procs $proc_name
            }
        } elseif { $command_name eq "namespace" } {
            lassign $words \
                command_name \
                subcommand \
                namespace \
                body

            if { $subcommand eq "eval" } {
                lappend procs {*}[procs_without_proc_comment [join $body]]
            }
        }
    }

    return $procs
}

proc procs_without_proc_comment_report {files} {
    #| Report procs that don't have a proc comment.

    set report [list]

    foreach file $files {
        foreach proc_name [procs_without_proc_comment [cat $file]] {
            lappend report "The proc $proc_name in file $file does not have a #| comment."
        }
    }

    return [join $report "\n"]
}

proc procs_without_proc_comment_count {files} {
    #| Count the number of procs that don't have a proc comment.

    set count 0

    foreach file $files {
        set procs [procs_without_proc_comment [cat $file]]
        incr count [llength $procs]
    }

    return $count
}
