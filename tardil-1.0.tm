#
# source ./tardil-1.0.tm
#
# set ::tardil::debug 1
# ::tardil::example3
#
#::tardil::init -debug

package require cmdline

namespace eval tardil {
    # debug verbosity
    variable debug 0
    # detected shell (Xilinx Vivado, tclsh,...?)
    variable shell ""
    variable prefix "tardil"
    variable postfix ""
}

proc ::tardil::dbg_puts {args} {
    variable debug
    if { $debug >= [expr [info level]-1] } {
        array set inf [info frame -1]
        #parray inf
        #puts $inf(proc)
 
        set empty_prefix ""
        for {set i 0} {${i}<[expr [info level]-1]} {incr i} {
            set empty_prefix "  ${empty_prefix}"
        }
        puts "${empty_prefix}\[$inf(proc)\] [lindex ${args} 0]"
    }
}

proc ::tardil::init {args} {
    variable debug
    variable shell
    dbg_puts [info level 0]

    set options {
        { "debug.arg" 0 "set verbosity for debug ouputs"   }
    }
    set usage ": [info level 0] \[options] \noptions:"
    array set params [::cmdline::getoptions args ${options} ${usage}]
    if {[llength ${args}] != 0} {
        return -code error -errorinfo [::cmdline::usage ${options} ${usage}]
    }

    set debug $params(debug)

    array set inf [info frame -1]
    if { [info exists inf(file)] } {
        dbg_puts "File: $inf(file)"
    } else {
        dbg_puts "File: command run not from file!"
    }

    set nameofexecutable [info nameofexecutable]
    dbg_puts "Name of executable: ${nameofexecutable}"
    switch -regexp ${nameofexecutable} {
        .*tclsh.*   { set shell "tclsh"         }
        .*Xilinx.*  { set shell "Xilinx"        }
        default     { set shell "not detected"  }
    }
    dbg_puts "Shell: ${shell}"

    array unset params
    array unset inf
    return
}

proc ::tardil::clone_bufg {args} {
    if {[llength ${args}] != 2} {
        return -code error -errorinfo "tardil::clone_bufg <new_name> <bufg_cell>"
    }

    set new_name  [lindex ${args} 0]
    set bufg_inst [get_cells [lindex ${args} 1]]

    if {[llength ${bufg_inst}] != 1} {
        error "Error: instance maby only one!"
    }
    #if { [get_property ORIG_REF_NAME ${bufg_inst}] != "BUFG" || [get_property IS_PRIMITIVE ${bufg_inst}] != "true"} { }
    if { [get_property ORIG_REF_NAME ${bufg_inst}] != "BUFG"} {
        error "Error: instance maby only BUFG!"
    }

    set parrent [get_property PARENT [get_cells ${bufg_inst}]]
    set net [get_nets -of_objects [get_pins ${bufg_inst}/I]]
    set new_inst [create_cell -reference BUFG ${parrent}/${new_name}_bufg]
    dbg_puts "Created new BUFG: ${new_inst}"
    connect_net -hierarchical -net ${net} -objects ${new_inst}/I
    dbg_puts "Net ${net} connected to ${new_inst}/I"

    set net_name "${parrent}/${new_name}"
    create_net ${net_name}
    dbg_puts "Created net ${net_name}"
    connect_net -hierarchical -net ${net_name} -objects ${new_inst}/O
    dbg_puts "Net ${net_name} connected to ${new_inst}/O"
}

proc ::tardil::example3 {args} {
    dbg_puts [info level 0]

    ::tardil::example0 asdf
}

proc ::tardil::example0 {args} {
    dbg_puts [info level 0]

    ::tardil::example1 dddd
}

proc ::tardil::example1 {args} {
    dbg_puts [info level 0]

    dbg_puts "Hello for debug! In shell: ${::tardil::shell}"
}

#set ::tardil::debug 99
#::tardil::init
::tardil::init -debug 99

