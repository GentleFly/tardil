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
    return ${new_inst}
}

proc ::tardil::shift {args} {
    # source ./tardil-1.0.tm; tardil::shift -allow_create_clock -clock_shift_step -180 i_dp_1/genblk1[0].register_i/q_reg/C
    # source ./tardil-1.0.tm; tardil::shift -allow_create_clock -clock_shift_step -180 i_dp_0/genblk1[9].register_i/q_reg/C
    # tardil::shift -allow_create_clock -clock_shift_step 180 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::shift -allow_create_clock -clock_shift_step 360 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::shift -allow_create_clock -clock_shift_step 180 i_dp_2/genblk1[0].register_i/q_reg/C
    #
    #source ./tardil-1.0.tm; close_design ; read_checkpoint ./syn.dcp ; link_design
    # tardil::shift -allow_create_clock -clock_shift_step 180 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::shift -allow_create_clock -clock_shift_step -180 i_dp_0/genblk1[9].register_i/q_reg/C
    # tardil::shift -allow_create_clock -clock_shift_step 360 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::shift -allow_create_clock -clock_shift_step 180 i_dp_2/genblk1[0].register_i/q_reg/C
    # #tardil::shift -allow_create_clock -clock_shift_step 180 i_dp_1/genblk1[0].register_i/q_reg/C
    variable prefix
    dbg_puts [info level 0]

    set options {
        { "allow_create_clock"       "Allow to create clock, in needed clock not exist"    }
        { "clock_shift_step.arg" 180 "Clock Shift Step in degree (180, 90, 60, ... ). Default:" }
    }
    set usage ": [lindex [info level 0] 0] \[options] <register_clock_pins> \noptions:"
    array set params [::cmdline::getoptions args ${options} ${usage}]
    if {[lsearch -regexp ${args} {-.*}] > -1} {
        return -code error -errorinfo [::cmdline::usage ${options} ${usage}]
    } else {
        dbg_puts "Prams: [array get params]"
    }
    if { $params(clock_shift_step) >= 0 } {
        set sign "p"
        dbg_puts "Detected positive sign for clock shift."
    } elseif { $params(clock_shift_step) < 0 } {
        set sign "n"
        dbg_puts "Detected negative sign for clock shift."
    }
    set degree_postfix "${sign}[format %0.4u [expr abs($params(clock_shift_step))]]"
    dbg_puts "Degree postfix: \"${degree_postfix}\""
    set clock_postfix "_${prefix}_${degree_postfix}"
    dbg_puts "Clock postfix: \"${clock_postfix}\""

    set register_clock_pins [get_pins "[lindex ${args} 0]" -filter {IS_CLOCK==true}]
    set args [lreplace ${args} 0 0]
    if {[llength ${register_clock_pins}] == 0} {
        error [::cmdline::usage ${options} ${usage}]
    } else {
        dbg_puts "Clock pins:"
        foreach clock_pin ${register_clock_pins} {
            dbg_puts "    ${register_clock_pins}"
        }
    }
    if {[llength ${args}] != 0} {
        dbg_puts "args: ${args}"
        error [::cmdline::usage ${options} ${usage}]
    }
    dbg_puts "Parameters resolved"
    
    foreach register_clock_pin ${register_clock_pins} {
        set current_shifted_clock_name ""
        set orig_clock_name ""

        if {$params(allow_create_clock)} {
            dbg_puts "Allowed to create clocks, with step $params(clock_shift_step)°"
            dbg_puts "Register clock pin: ${register_clock_pin}"

            set clock_on_pin [get_clocks -of_objects [get_pins ${register_clock_pin}]]
            if {[llength ${clock_on_pin}]>1} {
                error "Clocks on this ${register_clock_pin} need to be only one!\nOn pin detected clocks: ${clock_on_pin}"
            } else {
                dbg_puts "  On pin detected clocks: ${clock_on_pin}"
            }

            if {[regexp ${clock_on_pin} "(.*)${clock_postfix}" match orig_clock_name]} {
                set current_shifted_clock_name ${clock_on_pin}
                dbg_puts "  Detected needed clock: ${current_shifted_clock_name}"
            } elseif {[regexp "(.*)_${prefix}_(n|p)\[0-9]*" ${clock_on_pin} match orig_clock_name]} {
                set current_shifted_clock_name ${clock_on_pin}
                dbg_puts "  Detected sifted clock: ${current_shifted_clock_name}"
            } else {
                set orig_clock_name ${clock_on_pin}
            }
            set orig_clock_period [get_property period [get_clocks ${orig_clock_name}]]
            dbg_puts "  Detected original clock: ${orig_clock_name} (${orig_clock_period})"
            set target_shifted_clock_name "${orig_clock_name}${clock_postfix}"
            dbg_puts "  Target clock name: ${target_shifted_clock_name}"

            set source_clock_bufg [\
                get_cell -of_objects [\
                get_pins \
                -filter {direction==out && is_leaf==true && ref_name==BUFG} \
                -of_objects  [\
                get_nets -segments -of_objects ${register_clock_pin} \
                ]\
                ]\
                ]
            dbg_puts "  Source clock bufg: ${source_clock_bufg}"
            if { ${current_shifted_clock_name} == "" } {
                create_generated_clock \
                    -verbose \
                    -name "${orig_clock_name}_${prefix}_p0000" \
                    -divide_by 1 \
                    -source [get_pins ${source_clock_bufg}/I] \
                    [get_pins ${source_clock_bufg}/O]
                dbg_puts "  Created generated clock: \"${orig_clock_name}_${prefix}_p0000\""
            }
            if {[llength [get_clocks -quiet ${target_shifted_clock_name}]] == 0 } {

                set src_inst [tardil::clone_bufg ${target_shifted_clock_name} ${source_clock_bufg}]

                create_generated_clock \
                    -verbose \
                    -name ${target_shifted_clock_name} \
                    -divide_by 1 \
                    -source [get_pins ${src_inst}/I] \
                    [get_pins ${src_inst}/O]
                dbg_puts "  Created generated clock: ${target_shifted_clock_name}"

                set target_shifted_clock_latency [expr ${orig_clock_period}*($params(clock_shift_step)/360.0)]
                set_clock_latency \
                    -verbose \
                    -source \
                    -clock [get_clocks ${target_shifted_clock_name}]\
                    ${target_shifted_clock_latency} \
                    [get_pins ${src_inst}/O]
                dbg_puts "  Added latency for clock: ${target_shifted_clock_latency}"
            } else {
                set src_inst [\
                    get_cell -of_objects [\
                        get_pins \
                            -filter {direction==out && is_leaf==true && ref_name==BUFG} \
                            -of_objects [get_clocks ${target_shifted_clock_name}] \
                    ]\
                ]
                dbg_puts "  Target clock bufg: ${src_inst}"
            }

            disconnect_net \
                -verbose \
                -net [get_nets -of_objects ${register_clock_pin}] \
                -objects [list ${register_clock_pin}]
            dbg_puts "  Disconnected register clock pin for old clock"
            
            connect_net \
                -hierarchical \
                -net [get_nets -of_objects [get_pins ${src_inst}/O]] \
                -objects [list ${register_clock_pin}]
            dbg_puts "  Connected register clock pin for new clock"

            # TODO: ...

            #if {[lsearch -regexp ${clk} ".*${prefix}.*"] > -1} { }
            #set shifted_clocks [lsearch -inline -regexp ${clk} ".*${prefix}.*"]
            #if {[lindex ${shifted_clocks}] < 1} {
            #    dbg_puts "Not detected shifted clock!"
            #    #$params(clock_shift_step)
            #} else {
            #    dbg_puts "Detected shifted clock!"
            #}

        } else {
            error "This functional is not ready yet!"
        }
    }


    array unset params
    return
}

proc ::tardil::reslove {args} {
    dbg_puts [info level 0]

    set options {
        { "allow_create_clock"       "Allow to create clock, in needed clock not exist"    }
        { "clock_shift_step.arg" 180 "Clock Shift Step in degree (180, 90, 60, ... ). Default:" }
    }
    set usage ": [info level 0] \[options] <timing_path> \noptions:"
    array set params [::cmdline::getoptions args ${options} ${usage}]
    if {[lsearch -regexp ${args} {-.*}] > -1} {
        return -code error -errorinfo [::cmdline::usage ${options} ${usage}]
    }
    set timing_path [lindex ${args} 0]
    if {[llength ${args}] != 0} {
        return -code error -errorinfo [::cmdline::usage ${options} ${usage}]
    }

    #puts $params(clock_shift_step)

    array unset params
    return
}

#set ::tardil::debug 99
#::tardil::init
::tardil::init -debug 99

