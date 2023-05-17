set max_lines [lindex $argv 0]
set repository [lindex $argv 1]
set files [lrange $argv 2 end]

package require qcode-linter

puts "Checking for files that are more than $max_lines lines long."

set tcl_files [lmap x $files {file join $repository $x}]
puts [files_over_length_report $tcl_files $max_lines]
set count [files_over_length_count $tcl_files $max_lines]

if { $count > 0 } {
    exit 1
}

