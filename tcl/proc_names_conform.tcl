proc proc_names_conform_to_filename_report {file_path proc_names} {
    #| Returns a report of the proc names that:
    #| * Are not prefixed with the filename.
    #| * Do not have the correct namespaces.

    set filename [file tail $file_path]
    set rootname [file rootname $filename]
    set report [list]

    foreach proc_name $proc_names {
        set proc_tail [namespace tail $proc_name]

        if { [string first $rootname $proc_tail] != 0 } {
            lappend report "The proc name \"$proc_name\" does not belong in $filename"
        }

        set proc_path [string map {/ ::} [file rootname $file_path]]
        set pattern {^(::)?([^:]+::)?${proc_path}((_[^_]+)|$)}
        set pattern [subst -nocommands -nobackslashes $pattern]

        if { ![regexp $pattern $proc_name] } {
            lappend report "The proc name \"$proc_name\" does not belong in the directory $file_path"
        }
    }

    return [join $report "\n"]
}

proc proc_names_conform_to_filename_count {file_path proc_names} {
    #| Returns a count of the proc names that either:
    #| * Are not prefixed with the filename. Or;
    #| * Do not have the correct namespaces.

    set filename [file tail $file_path]
    set rootname [file rootname $filename]
    set count 0

    foreach proc_name $proc_names {
        set proc_tail [namespace tail $proc_name]
        set proc_path [string map {/ ::} [file rootname $file_path]]
        set pattern {^(::)?([^:]+::)?${proc_path}((_[^_]+)|$)}
        set pattern [subst -nocommands -nobackslashes $pattern]

        if { [string first $rootname $proc_tail] != 0
             || ![regexp $pattern $proc_name] } {
            incr count
        }
    }

    return $count
}

proc proc_names_conform_report {tcl_path tcl_files} {
    #| Report procs that do not conform to the naming structure.
    #|
    #| Proc names, excluding any namespaces, should be prefixed with file name
    #| without the extension.
    #|
    #| Additionally, the namespaces must conform to the directory structure such
    #| that the directories appear as namespaces for each proc within the file.
    #| The global namespace is optional and the first namespace does not need to
    #| conform to the directory structure.
    #|
    #| For example, valid proc names for Tcl file "is/integer.tcl" may include:
    #|
    #| * is::integer
    #| * ::is::integer
    #| * is::integer_positive
    #| * test::is::integer
    #| * ::test::is::integer_positive

    set report [list]

    foreach tcl_file $tcl_files {
        set file [file join $tcl_path $tcl_file]
        set proc_names [proc_names_parse [cat $file]]
        lappend report [proc_names_conform_to_filename_report $tcl_file $proc_names]
    }

    return [join $report "\n"]
}

proc proc_names_conform_count {tcl_path tcl_files} {
    #| Return a count of procs in the files that do not conform to the naming structure.
    #|
    #| Proc names, excluding any namespaces, should be prefixed with file name
    #| without the extension.
    #|
    #| Additionally, the namespaces must conform to the directory structure such
    #| that the directories appear as namespaces for each proc within the file.
    #| The global namespace is optional and the first namespace does not need to
    #| conform to the directory structure.
    #|
    #| For example, valid proc names for Tcl file "is/integer.tcl" may include:
    #|
    #| * is::integer
    #| * ::is::integer
    #| * is::integer_positive
    #| * test::is::integer
    #| * ::test::is::integer_positive

    set count 0

    foreach tcl_file $tcl_files {
        set file [file join $tcl_path $tcl_file]
        set proc_names [proc_names_parse [cat $file]]
        incr count [proc_names_conform_to_filename_count $tcl_file $proc_names]
    }

    return $count
}
