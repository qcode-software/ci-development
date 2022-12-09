source "../tcl/linter.tcl"

set files [lindex $argv 0]
set long_lines [list]
puts "Files: $files"

foreach file $files {
    set lines [linter_report_lines_over_length $file 90]
    lappend long_lines {*}$lines

    foreach line $lines {
        puts $line
    }
}

if { [llength $long_lines] > 0 } {
    exit 1
}

