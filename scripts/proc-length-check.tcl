set linter [lindex $argv 0]
set max_lines [lindex $argv 1]
set repository [lindex $argv 2]
set files [lrange $argv 3 end]
set long_procs [list]

source $linter

foreach file $files {
    set proc_lengths [linter_file_proc_lengths "${repository}/${file}"]

    dict for {proc_name body_length} $proc_lengths {
        if { $body_length > $max_lines } {
            dict set long_procs $file $proc_name $body_length
        }
    }
}

if { [dict size $long_procs] > 0 } {

    puts "Procs with bodies greater than ${max_lines} lines:"

    dict for {filename procs} $long_procs {
        dict for {proc_name body_length} $procs {
            puts "  $filename :: $proc_name :: $body_length lines"
        }
    }

    exit 1
}
