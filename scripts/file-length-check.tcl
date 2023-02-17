set max_lines [lindex $argv 0]
set repository [lindex $argv 1]
set files [lrange $argv 2 end]
set long_files [list]

foreach file $files {
    try {
        set handle [open "${repository}/${file}" r]
        set contents [read $handle]
        set lines [split $contents "\n"]
        set count [llength $lines]

        if { $count > $max_lines } {
            dict set long_files $file $count
        }

    } on error [list message options] {
        error \
            $message \
            [dict get $options -errorinfo] \
            [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

if { [dict size $long_files] > 0 } {

    puts "Files with more than ${max_lines} lines:"

    dict for {filename line_count} $long_files {
        puts "  $filename :: $line_count"
    }

    exit 1
}
