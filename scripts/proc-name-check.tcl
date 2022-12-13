set repository [lindex $argv 0]
set files [lrange $argv 1 end]
set reported_procs [list]

source "${repository}/tcl/linter.tcl"

foreach file $files {
    set lines [linter_report_procs_without_filename_prefix \
                   "${repository}/${file}"]
    lappend reported_procs {*}$lines

    foreach line $lines {
        puts $line
    }
}

if { [llength $reported_procs] > 0 } {
    exit 1
}
