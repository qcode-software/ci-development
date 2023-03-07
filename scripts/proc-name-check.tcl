set linter [lindex $argv 0]
set repository [lindex $argv 1]
set files [lrange $argv 2 end]

source $linter

puts "Checking proc name prefixes in files that have changed."

set tcl_files [lmap x $files {file join $repository $x}]
set procs_without_prefix [linter_procs_without_filename_prefix $tcl_files]
linter_report_procs_without_filename_prefix $procs_without_prefix

if { [dict size $procs_without_prefix] > 0 } {
    exit 1
}
