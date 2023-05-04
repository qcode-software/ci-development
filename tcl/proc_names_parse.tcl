proc proc_names_parse {string} {
    #| Parse any proc names from the given string without their namespaces.

    set pattern {^\s*proc\s+(:{0,2}(?:[a-z0-9_-]+::)*(?:[a-z0-9_-]+))\s+\{}
    set matches [regexp -lineanchor -all -inline -- $pattern $string]
    set proc_names [list]

    foreach {match_string proc_name} $matches {
        lappend proc_names $proc_name
    }

    return $proc_names
}
