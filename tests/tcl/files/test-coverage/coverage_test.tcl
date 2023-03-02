proc test_1 {args} {
    #| Proc comment 1.

    return true
}

proc test_2 {args} {
    #| Proc comment 2.

    return true
}

proc test_3 {args} {
    #| Proc comment 3.

    return true
}

proc test_4 {args} {
    #| Proc comment 4.

    return true
}

register GET /test/1 {args} {
    return true
}

register POST /test/1 {args} {
    return true
}

register PUT /test/1 {args} {
    return true
}
