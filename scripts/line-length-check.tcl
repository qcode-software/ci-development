set max_line_length [lindex $argv 0]
set repository [lindex $argv 1]
set files [lrange $argv 2 end]
set long_lines [list]

source "${repository}/tcl/linter.tcl"

foreach file $files {
    set lines [linter_report_lines_over_length \
                   "${repository}/${file}" \
                   $max_line_length]
    lappend long_lines {*}$lines

    foreach line $lines {
        puts $line
    }
}

if { [llength $long_lines] > 0 } {
    exit 1
}
