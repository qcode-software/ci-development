proc proc_names_conform_to_filename_report {file_path proc_names} {
    #| Returns a report of the proc names that:
    #| * Are not prefixed with the filename.
    #| * Do not have the correct namespaces.

    set filename [file tail $file_path]
    set root_filename [file rootname $filename]
    set report [list]

    foreach proc_name $proc_names {
        set proc_tail [namespace tail $proc_name]

        if { [string first $root_filename $proc_tail] != 0 } {
            lappend report "The proc name \"$proc_tail\" does not belong in the\
                            file \"$filename\"."
        }

        set dir_path [file dirname $file_path]
        set file_path_namespace [string map {/ ::} $dir_path]
        set proc_namespace [namespace qualifier $proc_name]

        if { ([string first "/" $file_path] >= 0 || [string first "::" $proc_name] >= 0)
             && $proc_namespace ne $file_path_namespace} {
            lappend report "The namespace \"$proc_namespace\" from proc\
                            \"$proc_name\" does not belong in the directory\
                            \"${dir_path}\"."
        }
    }

    return [join $report "\n"]
}

proc proc_names_conform_to_filename_count {file_path proc_names} {
    #| Returns a count of the proc names that either:
    #| * Are not prefixed with the filename. Or;
    #| * Do not have the correct namespaces.

    set filename [file tail $file_path]
    set root_filename [file rootname $filename]
    set count 0

    foreach proc_name $proc_names {
        set proc_tail [namespace tail $proc_name]
        set dir_path [file dirname $file_path]
        set file_path_namespace [string map {/ ::} $dir_path]
        set proc_namespace [namespace qualifier $proc_name]

        if { [string first $root_filename $proc_tail] != 0
             || (([string first "/" $file_path] >= 0
                  || [string first "::" $proc_name] >= 0)
                 && $proc_namespace ne $file_path_namespace) } {
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
