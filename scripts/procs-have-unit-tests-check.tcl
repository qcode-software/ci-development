set test_coverage_api [lindex $argv 0]
set repository [lindex $argv 1]
set test_dir [lindex $argv 2]
set files [lrange $argv 3 end]

set file_procs [list]
set file_tests [list]
set procs_missing_tests false

source $test_coverage_api

foreach file $files {
    set proc_names [test_coverage_proc_names_get "${repository}/${file}"]
    dict set file_procs $file $proc_names
}

package require fileutil
foreach test_file [fileutil::findByPattern "${repository}/$test_dir" "*.test"] {
    set tests [test_coverage_test_names_get $test_file]
    dict set file_tests $test_file $tests
}

set map [test_coverage_procs_tests_map $file_procs $file_tests]

dict for {filename procs_tests} $map {

    dict for {proc_name tests} $procs_tests {

        if { [dict size $tests] == 0 } {
            set procs_missing_tests true
            puts "$filename :: $proc_name"
        }
    }
}

if { $procs_missing_tests } {
    exit 1
}
