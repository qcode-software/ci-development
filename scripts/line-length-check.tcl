set repository [lindex $argv 0]
set files [lrange $argv 1 end]
set long_lines [list]

source "${repository}/tcl/linter.tcl"

foreach file $files {
    set lines [linter_report_lines_over_length "${repository}/${file}" 90]
    lappend long_lines {*}$lines

    foreach line $lines {
        puts $line
    }
}

if { [llength $long_lines] > 0 } {
    exit 1
}
