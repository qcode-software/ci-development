proc test_coverage_file_line_matches_get {pattern file} {
    #| Get all matches for the pattern in the file.

    try {
        set handle [open $file r]
        set contents [read $handle]
        set matches [regexp -lineanchor -all -inline -- $pattern $contents]
        set items [list]

        foreach {match_string item} $matches {
            lappend items $item
        }

        return $items
    } on error [list message options] {
        error $message [dict get $options -errorinfo] [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

proc test_coverage_proc_names_get {file} {
    #| Get proc names from the given file.

    set pattern {^\s*proc\s+:{0,2}(?:[a-zA-Z0-9_-]+::)*([a-zA-Z0-9_-]+)\s+\{}
    return [test_coverage_file_line_matches_get $pattern $file]
}

proc test_coverage_test_names_get {file} {
    #| Get test names from the given file.

    set pattern {^\s*test\s+([a-zA-Z0-9_-]+-[0-9]+\.[0-9]+)\s+}
    return [test_coverage_file_line_matches_get $pattern $file]
}

proc test_coverage_endpoints_get {file} {
    #| Get endpoints from the given file.

    set pattern {^\s*(?:qc::)?register\s+([a-zA-Z]+\s[a-zA-Z0-9_\-\/\:\.]+)\s+}
    return [test_coverage_file_line_matches_get $pattern $file]
}

proc test_coverage_file_tcl_lines_count {file} {
    #| Count the lines of Tcl code in the given file.
    #| Returns an integer that is the number of lines of Tcl code.

    try {
        set handle [open $file r]
        set contents [read $handle]
        set lines [split $contents "\n"]
        set count [llength $lines]

        if { [lindex $lines end] eq "" } {
            incr count -1
        }

        return $count
    } on error [list message options] {
        error $message [dict get $options -errorinfo] [dict get $options -errorcode]
    } finally {
        if { [info exists handle] } {
            close $handle
        }
    }
}

proc test_coverage_procs_tests_map {procs tests} {
    #| Maps tests to procs and returns the results.
    #| Mapping a test to a proc is determined by the test name being the proc
    #| name ending with a dash and a version number.
    #| i.e. test test_proc-1.0 will be mapped to proc test_proc
    #|
    #| Returns a dictionary where the key is the Tcl filename and the value is a
    #| map of procs within that file to matching tests.
    #|
    #| {
    #|     /home/user/project/products.tcl {
    #|         products_data {
    #|             /home/user/project/tests/products.test {
    #|                 products_data-1.0
    #|                 products_data-2.0
    #|             }
    #|         }
    #|         products_report_sales {
    #|             /home/user/project/tests/products.test {
    #|                 products_report_sales-1.0
    #|             }
    #|         }
    #|     }
    #|     /home/user/project/products_search.tcl {
    #|         products_search_code {
    #|             /home/user/project/tests/products_search.test {
    #|                 products_search_code-1.0
    #|             }
    #|         }
    #|     }
    #| }

    set procs_tests [dict create]

    dict for {filename proc_names} $procs {
        foreach proc_name $proc_names {
            regsub -all {\W} $proc_name {\\&} escaped_name
            set pattern "^${escaped_name}-\[0-9\]+\\.\[0-9\]+$"
            set test_matches [dict create]

            dict for {test_filename test_names} $tests {
                set matches [lsearch \
                                 -all \
                                 -inline \
                                 -regexp \
                                 $test_names \
                                 $pattern]

                if { [llength $matches] > 0 } {
                    dict set test_matches $test_filename $matches
                }
            }

            dict set procs_tests $filename $proc_name $test_matches
        }
    }

    return $procs_tests
}

proc test_coverage_endpoints_tests_map {endpoints tests} {
    #| Maps tests to endpoints and returns the results.
    #| Mapping a test to an endpoint is determined by the test name being the
    #| endpoint name with spaces replaced by "::" and ending with a dash and a
    #| version number.
    #| i.e. test GET::/tests/:test_id-1.0 will be mapped to endpoint "GET /tests/test_id"
    #|
    #| Returns a dictionary where the key is the Tcl filename and the value is a
    #| map of endpoints within that file to matching tests. E.g.
    #|
    #| {
    #|     /home/user/project/products.tcl {
    #|         {GET /products/:product_id} {
    #|             /home/user/project/tests/get_products.test {
    #|                 GET::/products/:product_id-1.0
    #|                 GET::/products/:product_id-2.0
    #|             }
    #|         }
    #|     }
    #|     /home/user/project/search.tcl {
    #|         {POST /search} {
    #|             /home/user/project/tests/search.test {
    #|                 POST::/search-1.0
    #|                 POST::/search-2.0
    #|             }
    #|         }
    #|     }
    #| }

    set endpoints_tests [dict create]

    dict for {filename endpoint_names} $endpoints {
        foreach endpoint_name $endpoint_names {
            regsub -all {\W} [string map {" " ::} $endpoint_name] {\\&} escaped_name
            set pattern "^${escaped_name}-\[0-9\]+\\.\[0-9\]+$"
            set test_matches [dict create]

            dict for {test_filename test_names} $tests {
                set matches [lsearch \
                                 -all \
                                 -inline \
                                 -regexp \
                                 $test_names \
                                 $pattern]

                if { [llength $matches] > 0 } {
                    dict set test_matches $test_filename $matches
                }
            }

            dict set endpoints_tests $filename $endpoint_name $test_matches
        }
    }

    return $endpoints_tests
}

proc test_coverage_counts {procs_tests_map} {
    #| Reports the percentages of procs that have at least 1 test.

    set proc_count 0
    set procs_with_tests_count 0

    dict for {filename procs_tests} $procs_tests_map {
        dict for {proc_name tests} $procs_tests {
            incr proc_count
            set test_count 0

            dict for {test_filename test_names} $tests {
                incr test_count [llength $test_names]
            }

            if { $test_count > 0 } {
                incr procs_with_tests_count
            }
        }
    }

    set percentage [expr {(double($procs_with_tests_count) / $proc_count) * 100}]

    return [dict create \
                total_count $proc_count \
                count_with_tests $procs_with_tests_count \
                percent_with_tests $percentage]
}

proc test_coverage {tcl_dir test_dir} {
    #| Get test coverage data for the given directories.

    set data [dict create]
    set file_procs [dict create]
    set file_endpoints [dict create]
    set file_tests [dict create]
    set line_count 0
    set test_count 0

    foreach tcl_file [glob -nocomplain -types f -- "${tcl_dir}/*.tcl"] {
        set procs [test_coverage_proc_names_get $tcl_file]
        dict set file_procs $tcl_file $procs

        set endpoints [test_coverage_endpoints_get $tcl_file]
        dict set file_endpoints $tcl_file $endpoints

        incr line_count [test_coverage_file_tcl_lines_count $tcl_file]
    }

    package require fileutil
    foreach test_file [fileutil::findByPattern $test_dir "*.test"] {
        set tests [test_coverage_test_names_get $test_file]
        dict set file_tests $test_file $tests

        incr test_count [llength $tests]
    }

    set procs_tests_map [test_coverage_procs_tests_map $file_procs $file_tests]
    set endpoints_tests_map [test_coverage_endpoints_tests_map \
                                 $file_endpoints \
                                 $file_tests]
    set proc_coverage [test_coverage_counts $procs_tests_map]
    set endpoint_coverage [test_coverage_counts $endpoints_tests_map]
    set all $procs_tests_map

    dict for {filename endpoints_tests} $endpoints_tests_map {
        if { ![dict exists $all $filename] } {
            dict set all $filename $endpoints_tests
        } else {
            dict for {endpoint_name tests} $endpoints_tests {
                dict set all $filename $endpoint_name $tests
            }
        }
    }

    set test_coverage [test_coverage_counts $all]

    dict set data line_count $line_count
    dict set data test_coverage_perct [dict get $test_coverage percent_with_tests]
    dict set data test_count $test_count
    dict set data procs $procs_tests_map
    dict set data proc_count [dict get $proc_coverage total_count]
    dict set data proc_count_with_tests [dict get $proc_coverage count_with_tests]
    dict set data proc_test_coverage_perct [dict get $proc_coverage percent_with_tests]
    dict set data endpoints $endpoints_tests_map
    dict set data endpoint_count [dict get $endpoint_coverage total_count]
    dict set data endpoint_count_with_tests [dict get $endpoint_coverage count_with_tests]
    dict set data endpoint_test_coverage_perct [dict get $endpoint_coverage percent_with_tests]

    return $data
}
