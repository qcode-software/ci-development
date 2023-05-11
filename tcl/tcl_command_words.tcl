proc tcl_command_words {command} {
    #| Get the Tcl words that make up the command.
    #|
    #| Original author: PYK.
    #| https://wiki.tcl-lang.org/page/cmdSplit

    if {![info complete $command]} {
        error [list {not a complete command} $command]
    }

    set words {}
    set logical {}
    set command [string trimleft $command[set command {}] "\f\n\r\t\v " ]
    set pattern {([^\f\n\r\t\v ]*)([\f\n\r\t\v ]+)(.*)}

    while {[regexp $pattern $command full first delim last]} {
        append logical $first

        if {[info complete $logical\n]} {
            lappend words $logical
            set logical {}
        } else {
            append logical $delim
        }

        set command $last[set last {}]
    }

    if {$command ne {}} {
        append logical $command
    }

    if {$logical ne {}} {
        lappend words $logical
    }

    return $words
}
