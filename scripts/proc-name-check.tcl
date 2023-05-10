set repository [lindex $argv 0]
set tcl_dir [lindex $argv 1]
set files [lrange $argv 2 end]

global auto_path
lappend auto_path [file join $repository packages]
package require qcode-ci

puts "Checking proc name prefixes in files that have changed."

set tcl_path [file join $repository $tcl_dir]
set tcl_files [list]

foreach file $files {
    set parts [file split $file]

    if { [lindex $parts 0] eq $tcl_dir } {
        lappend tcl_files [file join [lrange $parts 1 end]]
    }
}

puts [proc_names_conform_report $tcl_path $tcl_files]
set count [proc_names_conform_count $tcl_path $tcl_files]

if { $count > 0 } {
    exit 1
}
