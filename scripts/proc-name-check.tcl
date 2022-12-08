set incorrect_names false

foreach file [glob [lindex $argv 0]] {
    set handle [open $file r]
    set contents [read $handle]
    set line_no 1
    set filename [file tail $file]
    set length [string length [file extension $file]]
    set prefix [string range $filename 0 end-$length]

    foreach line [split $contents "\n"] {
        if { [regexp {^\s*proc\s(.+)\s+\{} $line -> proc_name]
             && ![string match "${prefix}*" $proc_name] } {
            puts "$filename :: Line $line_no :: $proc_name"
            set incorrect_names true
        }

        incr line_no
    }

    close $handle
}

if { $incorrect_names } {
    exit 1
}
