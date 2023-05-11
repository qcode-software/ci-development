set repository [lindex $argv 0]
set packages_path [lindex $argv 1]
set test_dir [lindex $argv 2]
set files [lrange $argv 3 end]

global auto_path
lappend auto_path $packages_path
package require qcode-ci
package require fileutil

puts "Checking for procs that do not have at least one unit test."

set test_files [fileutil::findByPattern "${repository}/$test_dir" "*.test"]
set tcl_files [lmap x $files {file join $repository $x}]
puts [test_coverage_report_procs_without_unit_tests $tcl_files $test_files]
set count [test_coverage_count_procs_without_unit_tests $tcl_files $test_files]

if { $count > 0 } {
    exit 1
}
