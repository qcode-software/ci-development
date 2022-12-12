set repository [lindex $argv 0]
set files [lrange $argv 1 end]
set procs [list]

source "${repository}/tcl/linter.tcl"

foreach file $files {
    set lines [linter_report_procs_without_filename_prefix "${repository}/${file}"]
    lappend procs {*}$lines

    foreach line $lines {
        puts $line
    }
}

if { $incorrect_names } {
    exit 1
}
