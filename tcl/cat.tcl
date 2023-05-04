proc cat {file} {
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
