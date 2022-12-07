try {
    set long_lines false

    foreach filename [glob [lindex $argv 0]] {
        set handle [open $filename r]
        set contents [read $handle]
        set line_no 1

        foreach line [split $contents "\n"] {
            if { [string length $line] > 90 } {
                puts "[file tail $filename] :: line $line_no"
                set long_lines true
            }

            incr line_no
        }

        close $handle
    }

    if { $long_lines } {
        exit 1
    }
} on error [list message options] {
    puts "Error: $message"
    exit 1
}
