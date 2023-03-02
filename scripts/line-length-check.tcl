set linter [lindex $argv 0]
set max_line_length [lindex $argv 1]
set repository [lindex $argv 2]
set files [lrange $argv 3 end]

source $linter

puts "Checking line length is under $max_line_length chars in files that have changed."

set tcl_files [lmap x $files {file join $repository $x}]
set count [linter_report_lines_over_length $tcl_files $max_line_length]

if { $count > 0 } {
    exit 1
}
