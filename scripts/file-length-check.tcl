set max_lines [lindex $argv 0]
set repository [lindex $argv 1]
set files [lrange $argv 2 end]
set long_files [list]

puts "Checking for files that are more than $max_lines lines long."

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

    dict for {filename line_count} $long_files {
        puts "The file $filename has $line_count lines."
    }

    exit 1
}
