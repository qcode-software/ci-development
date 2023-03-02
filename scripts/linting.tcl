set ci_repository [lindex $argv 0]
set file_max_lines [lindex $argv 1]
set proc_max_lines [lindex $argv 2]
set max_line_length [lindex $argv 3]
set repository [lindex $argv 4]
set test_dir [lindex $argv 5]
set files [lindex $argv 6 end]

source [file join $ci_repository "tcl/linter.tcl"]
source [file join $ci_repository "tcl/test_coverage.tcl"]

if { [llength $files] == 0 } {
    error "Usage: linting.tcl\
             <CI repository>\
             <file max lines>\
             <proc max lines>\
             <max line length>\
             <repository>\
             <test dir>\
             <tcl dir or tcl files with relative path from repo>"
} elseif { [llength $files] == 1
           && [file isdirectory [file join $repository [lindex $files 0]]] } {
    set tcl_files [glob [file join $repository [lindex $files 0] *.tcl]]
} else {
    set tcl_files [lmap x $files {file join $repository $x}]
}

package require fileutil
set test_files [fileutil::findByPattern [file join $repository $test_dir] "*.test"]

puts "Checking for files that are more than $file_max_lines lines long."
puts "---"
set count [linter_report_files_over_length $tcl_files $file_max_lines]
puts ""
puts "$count files exceeding $file_max_lines lines found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking line length is under $max_line_length characters."
puts "---"
set count [linter_report_lines_over_length $tcl_files $max_line_length]
puts ""
puts "$count lines exceeding $max_line_length characters found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking for procs that have bodies that are more than $proc_max_lines lines long."
puts "---"
set count [linter_report_procs_over_length $tcl_files $proc_max_lines]
puts ""
puts "$count procs with bodies exceeding $proc_max_lines lines found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking for proc names that are not prefixed with the file name."
puts "---"
set count [linter_report_procs_without_filename_prefix $tcl_files]
puts ""
puts "$count procs without file name as a prefix found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking for procs that do not have at least one unit test."
puts "---"
set count [test_coverage_report_procs_without_unit_tests $tcl_files $test_files]
puts ""
puts "$count procs that do not have a unit test found."
