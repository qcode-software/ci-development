set repository [lindex $argv 0]
set packages_path [lindex $argv 1]
set files [lrange $argv 2 end]

global auto_path
lappend auto_path $packages_path
package require qcode-ci

puts "Checking procs have a #| comment in files that have changed."

set tcl_files [lmap x $files {file join $repository $x}]
puts [procs_without_proc_comment_report $tcl_files]
set count [procs_without_proc_comment_count $tcl_files]

if { $count > 0 } {
    exit 1
}
