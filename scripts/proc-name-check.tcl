set linter [lindex $argv 0]
set repository [lindex $argv 1]
set files [lrange $argv 2 end]
set reported_procs [list]

source $linter

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
