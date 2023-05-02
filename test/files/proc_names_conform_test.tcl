proc proc_names_conform_test {args} {
    #| Passing proc name.
    return 1
}

proc proc_names_conform_test_two {args} {
    #| Passing proc name.
    return 1
}

proc ::proc_names_conform_test {args} {
    #| Passing proc name with global namespace.
    return 1
}

proc test::proc_names_conform_test {args} {
    #| Passing proc name with one namespace.
    return 1
}

proc failing_proc_name {args} {
    #| Failing proc name.
    return 1
}

proc test::fail::proc_names_conform_test {args} {
    #| Failing namespace in proc name.
    return 1
}

proc test::fail::proc_name {args} {
    #| Failing namespace and proc name.
    return 1
}
