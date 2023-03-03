##########
#
# Dependencies
#

# Requires qcode-tcl.
# Requires ci-development project in home directory.

##########
#
# Args
#

# -line_length <integer>
#    Default: 90
#    Report any lines that exceed this length.

# -file_length <integer>
#    Default: 500
#    Report any files that exceed this number of lines.

# -proc_length <integer>
#    Default: 100
#    Report any procs where the body exceeds this number of lines.
#    Note: SQL queries within a proc body are only counted as 1 line.

# -tcl_dir <directory>
#    Default: current working directory
#    The directory to search for Tcl files for linting.
#    Must be a relative path from the current working directory.

# -test_dir <directory>
#    Default: current working directory
#    The directory to search for test files for linting.
#    Must be a relative path from the current working directory.

# Any args that aren't specified at the command line will instead be taken from the config
# file if one exists.
#
# Any args that aren't specified at the command line nor in a config file will be set to
# the default value.


##########
#
# Config File
#

# The optional config file must be named ".qcode-linting" and can be stored in the home
# directory or within each project. This allows for project specific linting settings.
#
# Example config file:
#
# line_length = 80
# file_length = 300
# proc_length = 90
# tcl_dir = tcl
# test_dir = test

source "~/ci-development/tcl/linter.tcl"
source "~/ci-development/tcl/test_coverage.tcl"
package require qcode
package require fileutil

set vars [dict create \
              -line_length 90 \
              -file_length 500 \
              -proc_length 100 \
              -tcl_dir "" \
              -test_dir ""]

qc::args $argv {*}$vars

if { [file exists [file join [pwd] ".qcode-linting"]] } {
    set config_file [file join [pwd] ".qcode-linting"]
} elseif { [file exists [file join "~" ".qcode-linting"]] } {
    set config_file [file join "~" ".qcode-linting"]
} else {
    set config_file ""
}

if { $config_file ne "" } {
    ::try {
        set handle [open $config_file r]
        set contents [read $handle]
        set pairs [split $contents "\n"]

        foreach pair $pairs {
            lassign [split $pair "="] name value
            set name [string trim $name]
            set value [string trim $value]

            if { "-${name}" in [dict keys $vars] && "-${name}" ni $argv } {
                set $name $value
            }
        }
    } on error [list message options] {
        error \
            $message \
            [dict get $options -errorinfo] \
            [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

if { $tcl_dir eq "" } {
    set tcl_dir [pwd]
} else {
    set tcl_dir [file join [pwd] $tcl_dir]
}

if { $test_dir eq "" } {
    set test_dir [pwd]
} else {
    set test_dir [file join [pwd] $test_dir]
}

set tcl_files [fileutil::findByPattern $tcl_dir "*.tcl"]
set test_files [fileutil::findByPattern $test_dir "*.test"]

puts "Checking for files that are more than $file_length lines long."
puts "---"
set count [linter_report_files_over_length $tcl_files $file_length]
puts ""
puts "$count files exceeding $file_length lines found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking line length is under $line_length characters."
puts "---"
set count [linter_report_lines_over_length $tcl_files $line_length]
puts ""
puts "$count lines exceeding $line_length characters found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking for procs that have bodies that are more than $proc_length lines long."
puts "---"
set count [linter_report_procs_over_length $tcl_files $proc_length]
puts ""
puts "$count procs with bodies exceeding $proc_length lines found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking for proc names that are not prefixed with the file name."
puts "---"
set count [linter_report_procs_without_filename_prefix $tcl_files]
puts ""
puts "$count procs without file name as a prefix found."

puts ""
puts "--------------------------------------------------"
puts ""
puts "Checking for procs that do not have at least one unit test."
puts "---"
set count [test_coverage_report_procs_without_unit_tests $tcl_files $test_files]
puts ""
puts "$count procs that do not have a unit test found."
