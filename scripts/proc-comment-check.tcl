set linter [lindex $argv 0]
set repository [lindex $argv 1]
set files [lrange $argv 2 end]

source $linter

puts "Checking procs have a #| comment in files that have changed."

set tcl_files [lmap x $files {file join $repository $x}]
puts [linter_report_procs_without_proc_comment $tcl_files]
set count [linter_count_procs_without_proc_comment $tcl_files]

if { $count > 0 } {
    exit 1
}
