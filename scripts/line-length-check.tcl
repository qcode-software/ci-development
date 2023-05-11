set max_line_length [lindex $argv 0]
set repository [lindex $argv 1]
set packages_path [lindex $argv 2]
set files [lrange $argv 3 end]

global auto_path
lappend auto_path $packages_path
package require qcode-ci

puts "Checking line length is under $max_line_length chars in files that have changed."

set tcl_files [lmap x $files {file join $repository $x}]
puts [lines_over_length_report $tcl_files $max_line_length]
set count [lines_over_length_count $tcl_files $max_line_length]

if { $count > 0 } {
    exit 1
}
