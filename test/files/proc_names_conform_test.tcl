proc proc_names_conform_test {args} {
    #| Passing proc name.
    return 1
}

proc proc_names_conform_test_two {args} {
    #| Passing extended proc name.
    return 1
}

proc proc_names_conform_testthree {args} {
    #| Passing extended proc name.
    return 1
}

proc ::proc_names_conform_test {args} {
    #| Failing namespace - global namespace.
    return 1
}

proc test::fail::proc_names_conform_test {args} {
    #| Failing namespaces.
    return 1
}

proc failing_proc_name {args} {
    #| Failing proc name.
    return 1
}

proc test::proc_name {args} {
    #| Failing namespace and proc name.
    return 1
}
