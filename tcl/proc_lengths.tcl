proc proc_lengths {string} {
    #| Returns proc names and the line count of the body of each proc within the
    #| given string.

    set commands [tcl_commands $string]
    set proc_lengths [dict create]

    foreach command $commands {
        switch -regexp $command {
            {^proc} {
                set proc_name [lindex $command 1]
                set proc_body [lindex $command 3]
                set body_length [llength [split [string trim $proc_body] "\n"]]
                set query_count [llength [sql_query_indices $proc_body]]
                set query_length [sql_queries_length $proc_body]
                set body_length [expr {$body_length - $query_length + $query_count}]

                dict set proc_lengths $proc_name $body_length
            }
            {^namespace eval} {
                set proc_lengths [dict merge \
                                      $proc_lengths \
                                      [proc_lengths [lindex $command 3]]]
            }
        }
    }

    return $proc_lengths
}


