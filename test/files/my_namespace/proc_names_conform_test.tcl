namespace eval my_namespace {
    namespace export *
    namespace ensemble create
}

proc my_namespace::proc_names_conform_test {args} {
    #| Passing namespace and proc name.
    return 1
}

proc my_namespace::proc_names_conform_test_two {args} {
    #| Passing namespace and extended proc name.
    return 1
}

proc my_namespace::proc_names_conform_testthree {args} {
    #| Passing namespace and extended proc name.
    return 1
}

proc proc_names_conform_test {args} {
    #| Failing namespace - no namespace.
    return 1
}

proc ::proc_names_conform_test {args} {
    #| Failing namespace - global namespace.
    return 1
}

proc my_namespace::test::proc_names_conform_test {args} {
    #| Failing namespaces - some different.
    return 1
}

proc test::fail::proc_names_conform_test {args} {
    #| Failing namespaces - all different.
    return 1
}

proc my_namespace::failing_proc_name {args} {
    #| Failing proc name.
    return 1
}

proc test::fail::proc_name {args} {
    #| Failing namespace and proc name.
    return 1
}
