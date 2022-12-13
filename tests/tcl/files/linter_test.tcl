proc this_is_a_long_proc_name_for_testing {arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10} {
    #| Proc level comment that is meant to be at least 90 characters in length for testing purposes.

    set var "Hello World"

    return $var
}

proc linter_test {args} {
    #| Test proc name that matches the file name.

    return "Hello World"
}

proc linter_test_two {args} {
    #| Test proc with a prefix that matches the file name.

    return "Hello World"
}

proc does_not_start_with_linter_test {args} {
    #| Test proc that is not prefixed with the file name.

    return "Hello World"
}
