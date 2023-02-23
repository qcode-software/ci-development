set linter [lindex $argv 0]
set max_lines [lindex $argv 1]
set repository [lindex $argv 2]
set files [lrange $argv 3 end]
set long_procs [list]

source $linter

puts "Checking for procs that have bodies that are more than $max_lines lines long."

foreach file $files {
    set proc_lengths [linter_file_proc_lengths "${repository}/${file}"]

    dict for {proc_name body_length} $proc_lengths {
        if { $body_length > $max_lines } {
            dict set long_procs $file $proc_name $body_length
        }
    }
}

if { [dict size $long_procs] > 0 } {

    dict for {filename procs} $long_procs {
        dict for {proc_name body_length} $procs {
            puts "The proc \"$proc_name\" in file $filename has a body that is\
                  $body_length long."
        }
    }

    exit 1
}
