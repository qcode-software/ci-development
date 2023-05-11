set max_lines [lindex $argv 0]
set repository [lindex $argv 1]
set packages_path [lindex $argv 2]
set files [lrange $argv 3 end]

global auto_path
lappend auto_path $packages_path
package require qcode-ci

puts "Checking for procs that have bodies that are more than $max_lines lines long."
set tcl_files [lmap x $files {file join $repository $x}]
puts [procs_over_length_report $tcl_files $max_lines]
set count [procs_over_length_count $tcl_files $max_lines]

if { $count > 0 } {
    exit 1
}
