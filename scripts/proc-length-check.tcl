set linter [lindex $argv 0]
set max_lines [lindex $argv 1]
set repository [lindex $argv 2]
set files [lrange $argv 3 end]

source $linter

puts "Checking for procs that have bodies that are more than $max_lines lines long."
set tcl_files [lmap x $file {file join $repository $x}]
set count [linter_report_procs_over_length $tcl_files $max_lines]

if { $count > 0 } {
    exit 1
}
