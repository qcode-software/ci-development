set linter [lindex $argv 0]
set max_lines [lindex $argv 1]
set repository [lindex $argv 2]
set files [lrange $argv 3 end]

source $linter

puts "Checking for files that are more than $max_lines lines long."

set tcl_files [lmap x $files {file join $repository $x}]
set long_files [linter_files_over_length $tcl_files $max_lines]
linter_report_files_over_length $long_files

if { [dict size $long_files] > 0 } {
    exit 1
}
