proc proc_lengths {string} {
    #| Returns proc names and the line count of the body of each proc within the
    #| given string.

    set commands [tcl_commands $string]
    set proc_lengths [dict create]

    foreach command $commands {
        set words [tcl_command_words $command]
        set command_name [lindex $words 0]

        if { $command_name eq "proc" } {
            lassign $words \
                command_name \
                proc_name \
                proc_args \
                proc_body
            set proc_body [join $proc_body]
            set body_length [llength [split [string trim $proc_body] "\n"]]
            set query_count [llength [sql_query_indices $proc_body]]
            set query_length [sql_queries_length $proc_body]
            set body_length [expr {$body_length - $query_length + $query_count}]

            dict set proc_lengths $proc_name $body_length
        } elseif { $command_name eq "namespace" } {
            lassign $words \
                command_name \
                subcommand \
                name \
                body

            if { $subcommand eq "eval" } {
                set proc_lengths [dict merge \
                                      $proc_lengths \
                                      [proc_lengths [join $body]]]
            }
        }
    }

    return $proc_lengths
}
