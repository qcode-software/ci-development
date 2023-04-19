proc linter_cat {file} {
    #| Get the contents of a file.

    try {
        set handle [open $file r]
        return [read $handle]
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

proc linter_report_files_over_length {
    files
    max_file_length
} {
    #| Report files that have more lines than max file length.

    set report [list]

    foreach file $files {
        set contents [linter_cat $file]
        set line_count [llength [split $contents "\n"]]

        if { $line_count > $max_file_length } {
            lappend report "The file $file has $line_count lines."
        }
    }

    return [join $report "\n"]
}

proc linter_count_files_over_length {
    files
    max_file_length
} {
    #| Count the number of files that have more lines than max file length.

    set count 0

    foreach file $files {
        set contents [linter_cat $file]
        set line_count [llength [split $contents "\n"]]

        if { $line_count > $max_file_length } {
            incr count
        }
    }

    return $count
}

proc linter_report_lines_over_length {
    files
    max_line_length
} {
    #| Report lines that have more characters than max line length.

    set report [list]

    foreach file $files {
        set contents [linter_cat $file]
        set line_no 1

        foreach line [split $contents "\n"] {
            set line_length [string length $line]

            if { $line_length > $max_line_length } {
                set partial_line [string range [string trimleft $line] 0 15]
                lappend report "Line $line_no in file $file is $line_length chars long\
                                - ${partial_line}..."
            }

            incr line_no
        }
    }

    return [join $report "\n"]
}

proc linter_count_lines_over_length {
    files
    max_line_length
} {
    #| Count the number of lines that have more characters than max line length.

    set count 0

    foreach file $files {
        set contents [linter_cat $file]

        foreach line [split $contents "\n"] {
            if { [string length $line] > $max_line_length } {
                incr count
            }
        }
    }

    return $count
}

proc linter_boolean_table {length} {
    #| Returns a boolean table where number of columns matches length.

    if { $length == 0 } {
        return [list]
    }

    if { $length == 1 } {
        return [list \
                    [list 0] \
                    [list 1]]
    }

    set ones [list]
    set zeroes [list]

    foreach row [boolean_table [expr {$length - 1}]] {
        lappend zeroes [concat 0 $row]
        lappend ones [concat 1 $row]
    }

    return [concat $zeroes $ones]
}


proc linter_proc_name_prefixes_from_filename {filename} {
    #| Generate unique proc name prefixes from the filename.
    #|
    #| The underscores in a filename can either represent a literal underscore or a
    #| double colon.
    #| The list of strings returned contains all combinations of literal underscores
    #| and double colon replacements.

    set matches [regexp -all -indices -inline -- {[^\_](\_)[^\_]} $filename]

    if { [llength $matches] == 0 } {
        return $filename
    }

    set indices [list]

    foreach {match_indices underscore_indices} $matches {
        lappend indices [lindex $underscore_indices 0]
    }

    set boolean_table [boolean_table [llength $indices]]
    set prefixes [list]

    foreach row $boolean_table {
        set prefix $filename
        set offset 0

        foreach index $indices element $row {
            if { $element == 1 } {
                incr index $offset
                set prefix [string replace $prefix $index $index "::"]
                incr offset
            }
        }

        lappend prefixes $prefix
    }

    return $prefixes
}

proc linter_report_procs_without_filename_prefix {files} {
    #| Report procs that are not prefixed with the name of the file that they are in.

    set report [list]

    foreach file $files {
        set contents [linter_cat $file]
        set length [string length [file extension $file]]
        set filename [string range [file tail $file] 0 end-$length]
        set prefixes [linter_proc_name_prefixes_from_filename $filename]
        set proc_name_pattern {([a-z0-9_-]+::)*}

        foreach proc_name [linter_proc_names_parse $contents] {
            set namespaced_prefix [string map [list _ ::] $filename]
            set proc_name_parts [string map [list :: " "] $proc_name]
            set proc_name_no_namespaces [lindex $proc_name_parts end]
            set proc_name_namespaces [lrange $proc_name_parts 0 end-1]

            if { ![string match "${filename}*" $proc_name]
                 || ![string match "${filename}*" $proc_name_no_namespaces]
                 || ![string match "${namespaced_prefix}*" $proc_name] } {
                lappend report "The proc name \"$proc_name\" in file $file is not\
                                prefixed with \"$prefix\"."
            }
        }
    }

    return [join $report "\n"]
}

proc linter_count_procs_without_filename_prefix {files} {
    #| Count the number of procs that are not prefixed with the name of the file that
    #| they are in.

    set count 0

    foreach file $files {
        set contents [linter_cat $file]
        set length [string length [file extension $file]]
        set prefix [string range [file tail $file] 0 end-$length]

        foreach proc_name [linter_proc_names_parse $contents] {
            if { ![string match "${prefix}*" $proc_name] } {
                incr count
            }
        }
    }

    return $count
}

proc linter_proc_names_parse {string} {
    #| Parse any proc names from the given string without their namespaces.

    set pattern {^\s*proc\s+:{0,2}((?:[a-z0-9_-]+::)*(?:[a-z0-9_-]+))\s+\{}
    set matches [regexp -lineanchor -all -inline -- $pattern $string]
    set proc_names [list]

    foreach {match_string proc_name} $matches {
        lappend proc_names $proc_name
    }

    return $proc_names
}

proc linter_tcl_commands {script} {
    #| Get Tcl commands that are in the script.
    #|
    #| Original author: PYK.
    #| https://wiki.tcl-lang.org/page/cmdSplit

    namespace upvar [namespace current] commands_info report
    set report {}
    set commands {}
    set command {}
    set comment 0
    set lineidx 0
    set offset 0
    foreach line [split $script \n] {
        set parts [split $line \;]
        set numparts [llength $parts]
        set partidx 0
        while 1 {
            set parts [lassign $parts[set parts {}] part]
            if {[string length $command]} {
                if {$partidx} {
                    append command \;$part
                } else {
                    append command \n$part
                }
            } else {
                set partlength [string length $part]
                set command [string trimleft $part[set part {}] "\f\n\r\t\v "]
                incr offset [expr {$partlength - [string length $command]}]
                if {[string match #* $command]} {
                    set comment 1
                }
            }

            if {$command eq {}} {
                incr offset
            } elseif {(!$comment || (
                    $comment && (!$numparts || ![llength $parts])))
                && [info complete $command\n]} {

                lappend commands $command
                set info [dict create character $offset line $lineidx]
                set offset [expr {$offset + [string length $command] + 1}]
                lappend report $info
                set command {}
                set comment 0
                set info {}
            }

            incr partidx
            if {![llength $parts]} break
        }
    }

    incr lineidx

    if {$command ne {}} {
        error [list {incomplete command} $command]
    }

    return $commands
}

proc linter_report_procs_over_length {
    files
    max_proc_length
} {
    #| Report procs that have a body line count over max proc length.

    set report [list]

    foreach file $files {
        set contents [linter_cat $file]

        dict for {proc_name body_length} [linter_proc_lengths $contents] {
            if { $body_length > $max_proc_length } {
                lappend report "The proc \"$proc_name\" in file $file has a body that is\
                                $body_length lines long."
            }
        }
    }

    return [join $report "\n"]
}

proc linter_count_procs_over_length {
    files
    max_proc_length
} {
    #| Count the number of procs that have a body line count over max proc length.

    set count 0

    foreach file $files {
        set contents [linter_cat $file]

        dict for {proc_name body_length} [linter_proc_lengths $contents] {
            if { $body_length > $max_proc_length } {
                incr count
            }
        }
    }

    return $count
}

proc linter_proc_lengths {string} {
    #| Returns proc names and the line count of the body of each proc within the
    #| given string.

    set commands [linter_tcl_commands $string]
    set proc_lengths [dict create]

    foreach command $commands {
        switch -regexp $command {
            {^proc} {
                set proc_name [lindex $command 1]
                set proc_body [lindex $command 3]
                set body_length [llength [split [string trim $proc_body] "\n"]]
                set query_count [llength [linter_sql_query_indices $proc_body]]
                set query_length [linter_sql_queries_length $proc_body]
                set body_length [expr {$body_length - $query_length + $query_count}]

                dict set proc_lengths $proc_name $body_length
            }
            {^namespace eval} {
                set proc_lengths [dict merge \
                                      $proc_lengths \
                                      [linter_proc_lengths [lindex $command 3]]]
            }
        }
    }

    return $proc_lengths
}

proc linter_sql_queries_length {string} {
    #| Get the combined length of all SQL queries in a string.

    set line_count 0

    foreach indices [linter_sql_query_indices $string] {
        set query [string range $string [lindex $indices 0] [lindex $indices 1]]
        incr line_count [llength [split $query "\n"]]
    }

    return $line_count
}

proc linter_sql_query_indices {string} {
    #| Get the indexes of SQL queries in a string.

    set pattern {(?:\{(?:\s)*select[^\}]+\sfrom\s+[^\}]+\})}
    append pattern {|(?:\{(?:\s)*insert\s+into[^\}]+\})}
    append pattern {|(?:\{(?:\s)*update[^\}]+set[^\}]+\})}
    append pattern {|(?:\{(?:\s)*delete\s+from[^\}]+\})}

    return [regexp -all -inline -indices $pattern $string]
}

proc linter_procs_without_proc_comment {string} {
    #| Get a list procs that don't have a proc comment.

    set procs [list]
    set commands [linter_tcl_commands $string]

    foreach command $commands {
        set command_name [lindex $command 0]

        if { $command_name eq "proc" } {
            lassign $command command_name proc_name args body
            set body_lines [split [string trim $body] "\n"]

            if { [lsearch -regexp $body_lines {^#\|}] == -1 } {
                lappend procs $proc_name
            }
        } elseif { $command_name eq "namespace" } {
            lassign $command command_name subcommand namespace body

            if { $subcommand eq "eval" } {
                lappend procs {*}[linter_procs_without_proc_comment $body]
            }
        }
    }

    return $procs
}

proc linter_report_procs_without_proc_comment {files} {
    #| Report procs that don't have a proc comment.

    set report [list]

    foreach file $files {
        foreach proc_name [linter_procs_without_proc_comment [linter_cat $file]] {
            lappend report "The proc $proc_name in file $file does not have a #| comment."
        }
    }

    return [join $report "\n"]
}

proc linter_count_procs_without_proc_comment {files} {
    #| Count the number of procs that don't have a proc comment.

    set count 0

    foreach file $files {
        set procs [linter_procs_without_proc_comment [linter_cat $file]]
        incr count [llength $procs]
    }

    return $count
}
