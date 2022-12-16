set linter [lindex $argv 0]
set max_line_length [lindex $argv 1]
set repository [lindex $argv 2]
set files [lrange $argv 3 end]
set long_lines [list]

source $linter

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
