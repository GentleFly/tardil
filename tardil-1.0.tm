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
    variable max_multicycle_path 999
}

proc ::tardil::dbg_puts {args} {
    variable debug
    if { ${debug} >= [expr [info level]-1] } {
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
    if { [get_property ORIG_REF_NAME ${bufg_inst}] == "BUFG"} {
    } elseif { [get_property ORIG_REF_NAME ${bufg_inst}] == "BUFGCE"} {
    } else {
        error "Error: instance maby only BUFG or BUFGCE!"
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

proc ::tardil::connect_to_clock {args} {
    # source ./tardil-1.0.tm; tardil::connect_to_clock -allow_create_clock -clock_shift_step -180 i_dp_1/genblk1[0].register_i/q_reg/C
    # source ./tardil-1.0.tm; tardil::connect_to_clock -allow_create_clock -clock_shift_step -180 i_dp_0/genblk1[9].register_i/q_reg/C
    # tardil::connect_to_clock -allow_create_clock -clock_shift_step 180 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::connect_to_clock -allow_create_clock -clock_shift_step 360 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::connect_to_clock -allow_create_clock -clock_shift_step 180 i_dp_2/genblk1[0].register_i/q_reg/C
    #
    #source ./tardil-1.0.tm; close_design ; read_checkpoint ./syn.dcp ; link_design
    # tardil::connect_to_clock -allow_create_clock -clock_shift_step 180 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::connect_to_clock -allow_create_clock -clock_shift_step -180 i_dp_0/genblk1[9].register_i/q_reg/C
    # tardil::connect_to_clock -allow_create_clock -clock_shift_step 360 i_dp_1/genblk1[0].register_i/q_reg/C
    # tardil::connect_to_clock -allow_create_clock -clock_shift_step 180 i_dp_2/genblk1[0].register_i/q_reg/C
    # #tardil::connect_to_clock -allow_create_clock -clock_shift_step 180 i_dp_1/genblk1[0].register_i/q_reg/C
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
                dbg_puts "  Detected shifted clock: ${current_shifted_clock_name}"
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
                    -filter {direction==out && is_leaf==true && ref_name=~"BUFG*"} \
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
                set_clock_latency \
                    -verbose \
                    -source \
                    -clock [get_clocks "${orig_clock_name}_${prefix}_p0000"]\
                    0.0 \
                    [get_pins ${source_clock_bufg}/O]
                dbg_puts "  Added latency for clock: 0.0"

                # config_timing_pessimism -common_node off
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

                # config_timing_pessimism -common_node off
            } else {
                set src_inst [\
                    get_cell -of_objects [\
                        get_pins \
                            -filter {direction==out && is_leaf==true && ref_name=~"BUFG*"} \
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

proc ::tardil::pattern_to_name_and_shift {clock_name original_clock curr_shift} {
    variable prefix
    upvar $original_clock orig_clock
    upvar $curr_shift current_shift
    dbg_puts [info level 0]

    if {[regexp "(.*)_${prefix}_(n|p)0*(\[1-9]\[0-9]+)" ${clock_name} match orig_clock sign step]} {
        if { ${sign} == "p" } {
            set current_shift [expr 0 + ${step}]
        } elseif { ${sign} == "n"} {
            set current_shift [expr 0 - ${step}]
        }
    } elseif {[regexp "(.*)_${prefix}_(n|p)0*(0)" ${clock_name} match orig_clock sign step]} {
        if { ${sign} == "p" } {
            set current_shift [expr 0 + ${step}]
        } elseif { ${sign} == "n"} {
            set current_shift [expr 0 - ${step}]
        }
    } else {
        set orig_clock ${clock_name}
        set current_shift 0
    }
    return
}

proc ::tardil::shift {args} {
    variable prefix
    dbg_puts [info level 0]

    set options {
        { "allow_create_clock"       "Allow to create clock, in needed clock not exist"    }
        { "clock_shift_step.arg" 0 "Shift Clock Step on value in degree (180, 90, 60, ... ). Default:" }
    }
    set usage ": [lindex [info level 0] 0] \[options] <register_clock_pins> \noptions:"
    array set params [::cmdline::getoptions args ${options} ${usage}]
    if {[lsearch -regexp ${args} {-.*}] > -1} {
        return -code error -errorinfo [::cmdline::usage ${options} ${usage}]
    } else {
        dbg_puts "Prams: [array get params]"
    }

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

    set clocks [get_clocks -of_objects ${register_clock_pins}]
    if {[llength ${clocks}] > 1} {
        error "Detetected several slocks: ${clocks}"
    } else {
        set clock_on_pin [lindex ${clocks} 0]
        dbg_puts "Detected clock: ${clock_on_pin}"
    }

    if {[regexp "(.*)_${prefix}_(n|p)0*(\[1-9]\[0-9]+)" ${clock_on_pin} match orig_clock_name sign step]} {
        set orig_clock [get_clocks ${orig_clock_name}]
        if { ${sign} == "p" } {
            set current_shift [expr 0 + ${step}]
        } elseif { ${sign} == "n"} {
            set current_shift [expr 0 - ${step}]
        }
    } else {
        set orig_clock ${clock_on_pin}
        set current_shift 0
    }

    set target_shift [expr ${current_shift} + $params(clock_shift_step)]

    if { $params(allow_create_clock) } {
        set allow_create_clock "-allow_create_clock"
    } else {
        set allow_create_clock ""
    }

    tardil::connect_to_clock \
        ${allow_create_clock} \
        -clock_shift_step ${target_shift} \
        [get_pins ${register_clock_pins}]

    array unset params
    return
}

proc ::tardil::check_changes_window {timing_path} {
    if {[llength ${timing_path}] != 1} {
        error "Error: ::tardil::check_changes_window <timing_path>"
    } else {
        dbg_puts "Timing path: ${timing_path}"
    }
    set pins [get_pins -of_objects ${timing_path}]

    set startpoint_cell   [get_property PARENT_CELL [get_property STARTPOINT_PIN ${timing_path}]]
    set startpoint_period [get_property PERIOD [get_property STARTPOINT_CLOCK ${timing_path}]]
    dbg_puts "Start point period: ${startpoint_period}"

    set endpoint_cell   [get_property PARENT_CELL [get_property ENDPOINT_PIN   ${timing_path}]]
    set endpoint_period [get_property PERIOD [get_property ENDPOINT_CLOCK ${timing_path}]]
    dbg_puts "End point period: ${endpoint_period}"

    set timing_path_setup [get_timing_paths -quiet -setup -filter {CORNER==Slow} -through [join ${pins} " -through " ]]
    dbg_puts "Timing path setup: ${timing_path_setup}"
    set timing_path_hold  [get_timing_paths -quiet -hold  -filter {CORNER==Fast} -through [join ${pins} " -through " ]]
    dbg_puts "Timing path hold: ${timing_path_hold}"

    set max_delay_slack [get_property SLACK ${timing_path_setup}]
    dbg_puts "Max delay slack: ${max_delay_slack}"
    set min_delay_slack [get_property SLACK ${timing_path_hold}]
    dbg_puts "Min delay slack: ${min_delay_slack}"

    set slack_window [expr ${max_delay_slack} + ${min_delay_slack}]
    dbg_puts "Slack window: ${slack_window}"
    if { ${slack_window} < 0.300 } {
        puts "Warning: Slack window is less than 0.300ns! slack_setup(${max_delay_slack}) + slack_hold(${min_delay_slack}) = ${slack_window} < 0.300. On path: ${timing_path}"
    }

    set max_delay [get_property DATAPATH_DELAY ${timing_path_setup}]
    dbg_puts "Max delay: ${max_delay}"
    set min_delay [get_property DATAPATH_DELAY ${timing_path_hold}]
    dbg_puts "Min delay: ${min_delay}"

    set startpoint_changes_window [expr ${max_delay} - ${min_delay}]
    dbg_puts "Changes window: ${startpoint_changes_window}"
    if { ${startpoint_changes_window} > ${startpoint_period} } {
        error "Error: Changes window is more than clock period!"
    }

    return
}

proc ::tardil::get_weight {args} {
    dbg_puts [info level 0]
    set options {
        { "setup"             "for setup fix" }
        { "hold"              "for hold fix" }
        { "clock_shift.arg" 0 "Clock Shift in ns. Default:" }
    }
    set usage ": [info level 0] \[options] <cell|port> \noptions:"
    array set params [::cmdline::getoptions args ${options} ${usage}]
    if {[lsearch -regexp ${args} {-[a-zA-Z0-9]+}] > -1} {
        error [::cmdline::usage ${options} ${usage}]
    }
    if { $params(setup)==1 && $params(hold)==1 } {
        puts "Error: You need only one options -setup or -hold!"
        error [::cmdline::usage ${options} ${usage}]
    } elseif { $params(setup)==0 && $params(hold)==0 } {
        set params(setup) 1
    }
    set argument [lindex ${args} 0]
    set args [lreplace ${args} 0 0]
    if {[llength ${argument}] != 1} {
        error [::cmdline::usage ${options} ${usage}]
    }
    if {[llength ${args}] != 0} {
        error [::cmdline::usage ${options} ${usage}]
    }
    dbg_puts "Parameters resolved"

    set point [get_pins -leaf -quiet ${argument}]
    if { [llength ${point}] == 0 } {
        set point [get_cells -leaf -quiet ${argument}]
    }
    if { [llength ${point}] == 0 } {
        set point [get_ports -quiet ${argument}]
    }
    if { [llength ${point}] != 1} {
        error "Conunt of points not equal 1: ${point}"
    }
    set class [get_property CLASS ${point}]
    dbg_puts "${class} : ${point}"

    switch ${class} {
        pin     {
            if {![get_property IS_CLOCK]} {
                error "Pin is not clock pin: ${point}"
            }
            set clock_pin ${point}
            set cell [get_cells [get_property PARRENT_CELL ${point}]]
        }
        cell    {
            set clock_pin [get_pins -filter {IS_CLOCK==true && REF_PIN_NAME==C} -of_objects ${point}]
            if {[llength ${clock_pin}] != 1} {
                error "Clock pin not deteced for cell: ${point}"
            }
            set cell ${point}
        }
        port    {
            error "?!?!?!?!"
        }
        default {
            error "?!?!?!?!"
        }
    }
    dbg_puts "Clock pin: ${clock_pin}"
    dbg_puts "Cell: ${cell}"

    set clk [get_clocks -of_objects ${clock_pin}]
    if {[llength ${clk}] != 1} {
        error "Conunt of clocks not equal 1, on pin: ${clock_pin}"
    }

    set period [get_property PERIOD ${clk}]
    dbg_puts "Clock: ${clk}, period: ${period}"
    
    #set shift [expr ${period}*($params(clock_shift)/360.0)]
    set shift $params(clock_shift)
    dbg_puts "Clock shift: ${shift} ns"

    set timing_paths(setup,to)   [get_timing_paths -setup -filter {CORNER==Slow} -to   ${cell} -max_paths 99999 -nworst 9999 -quiet]
    set timing_paths(hold,to)    [get_timing_paths -hold  -filter {CORNER==Fast} -to   ${cell} -max_paths 99999 -nworst 9999 -quiet]
    set timing_paths(setup,from) [get_timing_paths -setup -filter {CORNER==Slow} -from ${cell} -max_paths 99999 -nworst 9999 -quiet]
    set timing_paths(hold,from)  [get_timing_paths -hold  -filter {CORNER==Fast} -from ${cell} -max_paths 99999 -nworst 9999 -quiet]

    foreach tp [array names timing_paths] {
        dbg_puts "    Timing path: ${tp}"
        set path_cnt(${tp})     [llength $timing_paths(${tp})]
        dbg_puts "        path_cnt: $path_cnt(${tp})"
        set min_slack(${tp})     [get_property SLACK -min $timing_paths(${tp})]
        dbg_puts "        min_slack: $min_slack(${tp})"
        set slacks(${tp})        [get_property SLACK $timing_paths(${tp})]
        dbg_puts "        slack:    $slacks(${tp})"
    }
    foreach tp [array names timing_paths] {
        if { [lindex $slacks(${tp}) 0] == ""} {
            error "Error: Not founded slacks (${tp}) for ${cell}. Check your constraints!"
        }
        set sum_of_slack(${tp}) [::tcl::mathop::+ {*}$slacks(${tp})]
        dbg_puts "        sum_of_slack: $sum_of_slack(${tp})"
    }

    set st [expr ($sum_of_slack(setup,to)   + (${shift}*$path_cnt(setup,to)) )]
    dbg_puts "      ${st}"
    if {$params(hold) && ${st} < 0}  {
        set st -9999999
    }
    set sf [expr ($sum_of_slack(setup,from) - (${shift}*$path_cnt(setup,from)) )]
    dbg_puts "      ${sf}"
    if {$params(hold) && ${sf} < 0}  {
        set sf -9999999
    }
    set ht [expr ($sum_of_slack(hold,to)    - (${shift}*$path_cnt(hold,to))  )]
    dbg_puts "      ${ht}"
    set hf [expr ($sum_of_slack(hold,from)  + (${shift}*$path_cnt(hold,from))  )]
    dbg_puts "      ${hf}"

    set weight [tcl::mathfunc::min \
        ${st} \
        ${sf} \
        ${ht} \
        ${hf} \
    ]
    dbg_puts "    Weight: ${weight}"
    return ${weight}
}

proc ::tardil::resolve_setup_slack {args} {
    variable debug
    dbg_puts [info level 0]

    set options {
        { "allow_create_clock"       "Allow to create clock, in needed clock not exist"    }
        { "clock_shift_step.arg" 180 "Clock Shift Step in degree (180, 90, 60, ... ). Default:" }
    }
    set usage ": [info level 0] \[options] <timing_path> \noptions:"
    array set params [::cmdline::getoptions args ${options} ${usage}]
    if {[lsearch -regexp ${args} {-[a-zA-Z0-9]+}] > -1} {
        error [::cmdline::usage ${options} ${usage}]
    }
    set timing_path [lindex ${args} 0]
    dbg_puts "Geted timing path"
    set args [lreplace ${args} 0 0]
    if {[llength ${timing_path}] != 1} {
        error [::cmdline::usage ${options} ${usage}]
    } else {
        dbg_puts "Timing path: ${timing_path}"
    }
    if {[llength ${args}] != 0} {
        error [::cmdline::usage ${options} ${usage}]
    }
    dbg_puts "Parameters resolved"

    ::tardil::check_changes_window ${timing_path}

    set startpoint_cell   [get_property PARENT_CELL [get_property STARTPOINT_PIN ${timing_path}]]
    dbg_puts "Start point: ${startpoint_cell}"
    set startpoint_clock [get_property STARTPOINT_CLOCK ${timing_path}]
    dbg_puts "Start point clock: ${startpoint_clock}"
    set startpoint_period [get_property PERIOD ${startpoint_clock}]
    dbg_puts "Start point period: ${startpoint_period}"
    set startpoint_shift_step [expr ${startpoint_period}*($params(clock_shift_step)/360.0)]
    dbg_puts "Start point shift step: ${startpoint_shift_step}"

    set endpoint_cell   [get_property PARENT_CELL [get_property ENDPOINT_PIN   ${timing_path}]]
    dbg_puts "End point: ${endpoint_cell}"
    set endpoint_clock [get_property ENDPOINT_CLOCK ${timing_path}]
    dbg_puts "End point period: ${endpoint_clock}"
    set endpoint_period [get_property PERIOD ${endpoint_clock}]
    dbg_puts "End point period: ${endpoint_period}"
    set endpoint_shift_step [expr ${endpoint_period}*($params(clock_shift_step)/360.0)]
    dbg_puts "End point shift step: ${startpoint_shift_step}"

    if { ${startpoint_cell} == ${endpoint_cell} } {
        error "Start cell and end cell is same!"
    }

    set setup_slack [get_property SLACK ${timing_path}]
    dbg_puts "Setup Slack: ${setup_slack}"
    set hold_slack [get_property SLACK [get_timing_paths -hold -from ${startpoint_cell} -to ${endpoint_cell}]]
    dbg_puts "Hold Slack: ${hold_slack}"

    if { ${setup_slack} >= 0 } {
        dbg_puts "Path have not negative setup slack! Path: ${timing_path}"
        return [list]
    }

    ::tardil::pattern_to_name_and_shift ${startpoint_clock} startpoint_origin_clock startpoint_current_shift
    dbg_puts "${startpoint_clock}: ${startpoint_origin_clock} ${startpoint_current_shift}"
    ::tardil::pattern_to_name_and_shift   ${endpoint_clock}   endpoint_origin_clock   endpoint_current_shift
    dbg_puts "${endpoint_clock}: ${endpoint_origin_clock} ${endpoint_current_shift}"

    set cnt_step [expr int(abs(${setup_slack})/${startpoint_shift_step}) + 1]
    if {${startpoint_clock} == ${endpoint_clock}} {
        for {set i 0} {${i} < ${cnt_step}+1} {incr i} {
            set startpoint_shift_cnt ${i}
            set endpoint_shift_cnt [expr ${cnt_step} - ${i}]
            dbg_puts "Step for startpoint and step for endpoint: \[${startpoint_shift_cnt} : ${endpoint_shift_cnt}\]"


            set startpoint_shift [expr ${startpoint_shift_cnt}*${startpoint_shift_step}]
            dbg_puts "    Startpoint shift: ${startpoint_shift}"

            set endpoint_shift [expr ${endpoint_shift_cnt}*${endpoint_shift_step}]
            dbg_puts "    Endpoint shift: ${endpoint_shift}"

            set weight [tcl::mathfunc::min \
                [::tardil::get_weight -setup -clock_shift ${startpoint_shift} ${startpoint_cell}] \
                [::tardil::get_weight -setup -clock_shift ${endpoint_shift}   ${endpoint_cell}] \
            ]
            dbg_puts "    Weight: ${weight}"

            if { [info exist best_weight] } {
                if { ${best_weight} < ${weight} } {
                    set best_weight ${weight}
                    set selected_startpoint_shift_cnt ${startpoint_shift_cnt}
                    set selected_endpoint_shift_cnt ${endpoint_shift_cnt}
                }
            } else {
                set best_weight ${weight}
                set selected_startpoint_shift_cnt ${startpoint_shift_cnt}
                set selected_endpoint_shift_cnt ${endpoint_shift_cnt}
            }
        }
    } else {
        if       { ${startpoint_current_shift} == 0 && ${endpoint_current_shift} != 0 } {
            set selected_startpoint_shift_cnt ${cnt_step}
            set selected_endpoint_shift_cnt 0
        } elseif { ${startpoint_current_shift} != 0 && ${endpoint_current_shift} == 0 } {
            set selected_startpoint_shift_cnt 0
            set selected_endpoint_shift_cnt ${cnt_step}
        } elseif { ${startpoint_current_shift} < ${endpoint_current_shift} } {
            set selected_startpoint_shift_cnt ${cnt_step}
            set selected_endpoint_shift_cnt 0
        } elseif { ${startpoint_current_shift} > ${endpoint_current_shift} } {
            set selected_startpoint_shift_cnt 0
            set selected_endpoint_shift_cnt ${cnt_step}
        } else {
            error "WTF?!?!"
        }
    }
    dbg_puts "Selected steps: \[${selected_startpoint_shift_cnt} : ${selected_endpoint_shift_cnt}\]"

    set shifted_cells [list]

    if { ${selected_startpoint_shift_cnt} > 0 } {
        tardil::shift \
            -allow_create_clock \
            -clock_shift_step [expr -180 * ${selected_startpoint_shift_cnt}] \
            [get_pins ${startpoint_cell}/C]
        set shifted_cells [lappend shifted_cells ${startpoint_cell}]
    }

    if { ${selected_endpoint_shift_cnt} > 0 } {
        tardil::shift \
            -allow_create_clock \
            -clock_shift_step [expr +180 * ${selected_endpoint_shift_cnt}] \
            [get_pins ${endpoint_cell}/C]
        set shifted_cells [lappend shifted_cells ${endpoint_cell}]
    }

    array unset path_cnt
    array unset min_slack
    array unset sum_of_slack

    array unset timing_paths
    array unset params
    return ${shifted_cells}
}

proc ::tardil::resolve_hold_slack {args} {
    variable debug
    dbg_puts [info level 0]

    set options {
        { "allow_create_clock"       "Allow to create clock, in needed clock not exist"    }
        { "clock_shift_step.arg" 180 "Clock Shift Step in degree (180, 90, 60, ... ). Default:" }
    }
    set usage ": [info level 0] \[options] <timing_path> \noptions:"
    array set params [::cmdline::getoptions args ${options} ${usage}]
    if {[lsearch -regexp ${args} {-[a-zA-Z0-9]+}] > -1} {
        error [::cmdline::usage ${options} ${usage}]
    }
    set timing_path [lindex ${args} 0]
    dbg_puts "Geted timing path"
    set args [lreplace ${args} 0 0]
    if {[llength ${timing_path}] != 1} {
        error [::cmdline::usage ${options} ${usage}]
    } else {
        dbg_puts "Timing path: ${timing_path}"
    }
    if {[llength ${args}] != 0} {
        error [::cmdline::usage ${options} ${usage}]
    }
    dbg_puts "Parameters resolved"

    set startpoint_pin [get_property STARTPOINT_PIN ${timing_path}]
    set startpoint_cell [get_property PARENT_CELL ${startpoint_pin}]
    if { ${startpoint_cell} == "" } {
        set startpoint_cell ${startpoint_pin}
    }
    dbg_puts "Start point: ${startpoint_cell}"
    set startpoint_class [get_property CLASS ${startpoint_cell}]
    dbg_puts "Start point class: ${startpoint_class}"
    set startpoint_clock [get_property STARTPOINT_CLOCK ${timing_path}]
    dbg_puts "Start point clock: ${startpoint_clock}"
    set startpoint_period [get_property PERIOD ${startpoint_clock}]
    dbg_puts "Start point period: ${startpoint_period}"
    set startpoint_shift_step [expr ${startpoint_period}*($params(clock_shift_step)/360.0)]
    dbg_puts "Start point shift step: ${startpoint_shift_step}"

    set endpoint_pin [get_property ENDPOINT_PIN ${timing_path}]
    set endpoint_cell   [get_property PARENT_CELL ${endpoint_pin}]
    if { ${endpoint_cell} == "" } {
        set endpoint_cell ${endpoint_pin}
    }
    dbg_puts "End point: ${endpoint_cell}"
    set endpoint_class [get_property CLASS ${endpoint_cell}]
    dbg_puts "End point class: ${endpoint_class}"
    set endpoint_clock [get_property ENDPOINT_CLOCK ${timing_path}]
    dbg_puts "End point period: ${endpoint_clock}"
    set endpoint_period [get_property PERIOD ${endpoint_clock}]
    dbg_puts "End point period: ${endpoint_period}"
    set endpoint_shift_step [expr ${endpoint_period}*($params(clock_shift_step)/360.0)]
    dbg_puts "End point shift step: ${startpoint_shift_step}"

    if { ${startpoint_cell} == ${endpoint_cell} } {
        error "Start cell and end cell is same!"
    }

    set setup_slack [get_property SLACK [get_timing_paths -setup -through [join [get_pins -of_objects ${timing_path}] " -through " ] -quiet]]
    dbg_puts "Setup Slack: ${setup_slack}"                                                                                                 
    set hold_slack  [get_property SLACK [get_timing_paths -hold  -through [join [get_pins -of_objects ${timing_path}] " -through " ] -quiet]]
    dbg_puts "Hold Slack: ${hold_slack}"

    set cnt_step [expr int(abs(${hold_slack})/${startpoint_shift_step}) + 1]
    dbg_puts "Count of step for fix slack: ${cnt_step}"
    if { ${hold_slack} >= 0 } {
        dbg_puts "Path have not negative hold slack! Path: ${timing_path}"
        return [list]
    }

    ::tardil::pattern_to_name_and_shift ${startpoint_clock} startpoint_origin_clock startpoint_current_shift
    dbg_puts "${startpoint_clock}: ${startpoint_origin_clock} ${startpoint_current_shift}"
    ::tardil::pattern_to_name_and_shift   ${endpoint_clock}   endpoint_origin_clock   endpoint_current_shift
    dbg_puts "${endpoint_clock}: ${endpoint_origin_clock} ${endpoint_current_shift}"

    if { ${startpoint_class} == "cell" && ${endpoint_class} == "cell" } {
        set weight [tcl::mathfunc::min \
            [::tardil::get_weight -hold -clock_shift 0 ${startpoint_cell}] \
            [::tardil::get_weight -hold -clock_shift 0 ${endpoint_cell}] \
        ]
        set best_weight ${weight}
        set selected_startpoint_shift_cnt 0
        set selected_endpoint_shift_cnt 0

        for {set i 0} {${i} < ${cnt_step}+1} {incr i} {
            set startpoint_shift_cnt ${i}
            set endpoint_shift_cnt [expr ${cnt_step} - ${i}]
            dbg_puts "Step for startpoint and step for endpoint: \[${startpoint_shift_cnt} : ${endpoint_shift_cnt}\]"


            set startpoint_shift [expr ${startpoint_shift_cnt}*${startpoint_shift_step}]
            dbg_puts "    Startpoint shift: ${startpoint_shift}"
            set endpoint_shift [expr ${endpoint_shift_cnt}*${endpoint_shift_step}]
            dbg_puts "    Endpoint shift: ${endpoint_shift}"

            set weight [tcl::mathfunc::min \
                [::tardil::get_weight -hold -clock_shift ${startpoint_shift} ${startpoint_cell}] \
                [::tardil::get_weight -hold -clock_shift ${endpoint_shift}   ${endpoint_cell}] \
            ]
            dbg_puts "    Weight: ${weight}"

            if { ${best_weight} < ${weight} } {
                set best_weight ${weight}
                set selected_startpoint_shift_cnt ${startpoint_shift_cnt}
                set selected_endpoint_shift_cnt ${endpoint_shift_cnt}
            }
        }
    } elseif { ${startpoint_class} == "port" && ${endpoint_class} == "cell" } {
        set selected_startpoint_shift_cnt 0
        set selected_endpoint_shift_cnt ${cnt_step}
    } elseif { ${startpoint_class} == "cell" && ${endpoint_class} == "port" } {
        set selected_startpoint_shift_cnt ${cnt_step}
        set selected_endpoint_shift_cnt 0
    } else {
        puts "Start point class: ${startpoint_class}"
        puts "End point class: ${endpoint_class}"
        error "Not witten...."
    }
    dbg_puts "Selected steps: \[${selected_startpoint_shift_cnt} : ${selected_endpoint_shift_cnt}\]"

    set shifted_cells [list]

    if { ${selected_startpoint_shift_cnt} > 0 } {
        tardil::shift \
            -allow_create_clock \
            -clock_shift_step [expr +180 * ${selected_startpoint_shift_cnt}] \
            [get_pins ${startpoint_cell}/C]
        set shifted_cells [lappend shifted_cells ${startpoint_cell}]
    }

    if { ${selected_endpoint_shift_cnt} > 0 } {
        tardil::shift \
            -allow_create_clock \
            -clock_shift_step [expr -180 * ${selected_endpoint_shift_cnt}] \
            [get_pins ${endpoint_cell}/C]
        set shifted_cells [lappend shifted_cells ${endpoint_cell}]
    }

    array unset path_cnt
    array unset min_slack
    array unset sum_of_slack

    array unset timing_paths
    array unset params
    return ${shifted_cells}
}

proc ::tardil::resolve {} {

    # vivado
    config_timing_pessimism -common_node off

    set timing_path [get_timing_paths -from [get_clocks original_clock*] -to [get_clocks original_clock*] -slack_lesser_than 0 -quiet]
    while {[llength ${timing_path}] > 0} {
        dbg_puts "Resolve steup path: ${timing_path}"
        set shifted_cells [tardil::resolve_setup_slack ${timing_path}]
        if {[llength ${shifted_cells}] == 0} {
            error "Why ?!?!??!"
        }
        foreach c ${shifted_cells} {
            dbg_puts "  Shifted point: $c"
        }
        set timing_path [get_timing_paths -from [get_clocks original_clock*] -to [get_clocks original_clock*] -slack_lesser_than 0 -quiet]
    }

    set exist_hold_violation 1
    while {${exist_hold_violation} == 1} {
        set exist_hold_violation 0
        set timing_paths [get_timing_paths \
            -hold \
            -from [get_clocks original_clock*] \
            -to [get_clocks original_clock*] \
            -slack_lesser_than -0.2 \
            -nworst 999 -max_paths 999 -quiet \
        ]
        for {set i 0} {${i} < [llength ${timing_paths}]} {incr i} {
            set timing_path [lindex ${timing_paths} ${i}]
            incr tp(${timing_path})
            dbg_puts "Resolve hold path: ${timing_path}"
            set shifted_cells [tardil::resolve_hold_slack ${timing_path}]
            if {[llength ${shifted_cells}] > 0} {
                foreach shifted_cell ${shifted_cells} {
                  incr shifted(${shifted_cell})
                  dbg_puts "  Shifted cell: ${shifted_cells}"
                  dbg_puts "    Cell was shifted: $shifted(${shifted_cell})"
                  if { $shifted(${shifted_cell}) < 10 } {
                    set exist_hold_violation 1
                  } else {
                    set exist_hold_violation 0
                    dbg_puts "    Not resolved ?"
                  }
                }
                break
            }
        }
    }
    array unset shifted

}

proc ::tardil::generate_with_latency {args} {
    variable prefix
    dbg_puts [info level 0]

    set strings [list]

    set clocks [lsort -uniq [get_clocks -regexp "(.*)_${prefix}_(n|p)\[0-9]*"]]
    dbg_puts "Finded clocks: ${clocks}"

    set clocks_000 [lsearch -regexp -inline -all ${clocks} "(.*)_${prefix}_(n|p)000\[0-0]*"]
    foreach clock_000 ${clocks_000} {

        regexp "(.*)_${prefix}_(n|p)\[0-9]*" ${clock_000} match orig_clock_name
        set strigns [lappend strigns "\n# vivado: config_timing_pessimism -common_node off"]
        set strigns [lappend strigns "\n# File generated by command: [info level 0]"]
        set strigns [lappend strigns "\n\n# Extendet Useful Skew for clock: ${orig_clock_name}\n"]

        dbg_puts "Original clock name: ${orig_clock_name}"
        set pin_o [get_pins -leaf -filter {direction==out} -of_objects [get_clocks ${clock_000}]]
        set pin_i [get_pins "[get_cells -of_objects ${pin_o}]/I"]
        dbg_puts "Pins for orig clock: ${pin_o}, ${pin_i}"

        set clks [lsearch -regexp -inline -all ${clocks} "${orig_clock_name}_${prefix}_(n|p)\[0-9]*"]
        foreach clk ${clks} {
            dbg_puts "Clock: ${clk}"
            ::tardil::pattern_to_name_and_shift ${clk} original_clock current_shift
            dbg_puts "  Cuttenr shift ${current_shift} for clock ${original_clock}"
            set orig_clock_period [get_property period [get_clocks ${original_clock}]]
            dbg_puts "  Detected original clock: ${original_clock} (${orig_clock_period})"
            set target_shifted_clock_latency [expr ${orig_clock_period}*(${current_shift}/360.0)]
            dbg_puts "  Latency for clock: ${target_shifted_clock_latency}"
            set inverted [expr fmod( ${current_shift}/180, 2)]
            dbg_puts "  Clock is inverted: ${inverted}"
            if {${inverted}} {
                set strign_inverted "-invert"
            } else {
                set strign_inverted ""
            }

            if { ${clock_000} == ${clk} } {
                set add ""
                set strign_inverted ""
            } else {
                set add "-add"
            }
            set strigns [lappend strigns "
create_generated_clock -name ${clk} \\
    -divide_by 1 ${add} ${strign_inverted} \\
    -master \[get_clocks ${original_clock}\] \\
    -source \[get_pins ${pin_i}\] \\
    \[get_pins ${pin_o}\] 
set_clock_latency -clock ${clk} \\
    -source \\
    ${target_shifted_clock_latency} \\
    \[get_pins ${pin_o}\]
"]

            set pins(${clk}) [get_pins \
                    -of_objects [get_nets \
                    -segments \
                    -of_objects  [get_clocks ${clk}] \
                ] \
                -filter {direction==in && is_leaf}]
        }

        dbg_puts "Stop propogation:"
        set clocks_on_pins [array names pins]
        foreach clk [lsort -dictionary [array names pins]] {
            dbg_puts "  Clock: ${clk}"
            #set clocks_on_pins [lsort -dictionary -unique [get_clocks -of_objects [get_pins $pins(${clk})]]]
            dbg_puts "    Clocks on pins: ${clocks_on_pins}"
            set index [lsearch ${clocks_on_pins} "${clk}"]
            set stop_clocks [lreplace ${clocks_on_pins} ${index} ${index}]
            dbg_puts "    Clocks for stop: ${stop_clocks}"
            set strigns [lappend strigns "
set_clock_sense \\
    -stop_propagation -quiet \\
    -clocks { ${stop_clocks} } \\
    { $pins(${clk}) }
"]
        }

        foreach clk [lsort -dictionary [array names pins]] {
            dbg_puts "  Clock: ${clk}"
            ::tardil::pattern_to_name_and_shift ${clk} original_clock current_shift
            set inverted [expr fmod( ${current_shift}/180, 2)]
            dbg_puts "  Clock is inverted: ${inverted}"
            if {${inverted}} {
                set strigns [lappend strigns "\nset_property IS_INVERTED 1 \[get_pins { $pins(${clk}) }\]"]
            }
        }

        array unset pins
        #puts [join ${strigns} {\n}]
        #foreach str ${strigns} {
        #    puts ${str}
        #}
    }
    return [join ${strigns}]
}

proc ::tardil::generate_with_multicycle {args} {
    variable prefix
    variable max_multicycle_path
    dbg_puts [info level 0]

    set strings [list]

    set clocks [lsort -uniq [get_clocks -regexp "(.*)_${prefix}_(n|p)\[0-9]*"]]
    dbg_puts "Finded clocks: ${clocks}"

    set clocks_000 [lsearch -regexp -inline -all ${clocks} "(.*)_${prefix}_(n|p)000\[0-0]*"]
    foreach clock_000 ${clocks_000} {

        regexp "(.*)_${prefix}_(n|p)\[0-9]*" ${clock_000} match orig_clock_name
        set strigns [lappend strigns "\n# File generated by command: [info level 0]"]
        set strigns [lappend strigns "\n\n# Extendet Useful Skew for clock: ${orig_clock_name}\n"]

        dbg_puts "Original clock name: ${orig_clock_name}"
        set pin_o [get_pins -leaf -filter {direction==out} -of_objects [get_clocks ${clock_000}]]
        set pin_i [get_pins "[get_cells -of_objects ${pin_o}]/I"]
        dbg_puts "Pins for orig clock: ${pin_o}, ${pin_i}"

        set clks [lsearch -regexp -inline -all ${clocks} "${orig_clock_name}_${prefix}_(n|p)\[0-9]*"]
        foreach clk ${clks} {
            dbg_puts "Clock: ${clk}"
            ::tardil::pattern_to_name_and_shift ${clk} original_clock current_shift
            dbg_puts "  Cuttenr shift ${current_shift} for clock ${original_clock}"
            set orig_clock_period [get_property period [get_clocks ${original_clock}]]
            dbg_puts "  Detected original clock: ${original_clock} (${orig_clock_period})"
            set target_shifted_clock_latency [expr ${orig_clock_period}*(${current_shift}/360.0)]
            dbg_puts "  Latency for clock: ${target_shifted_clock_latency}"
            set inverted [expr fmod( ${current_shift}/180, 2)]
            dbg_puts "  Clock is inverted: ${inverted}"
            if {${inverted}} {
                set strign_inverted "-invert"
            } else {
                set strign_inverted ""
            }

            if { ${clock_000} == ${clk} } {
                set add ""
                set strign_inverted ""
            } else {
                set add "-add"
            }
            set strigns [lappend strigns "
create_generated_clock -name ${clk} \\
    -divide_by 1 ${add} ${strign_inverted} \\
    -master \[get_clocks ${original_clock}\] \\
    -source \[get_pins ${pin_i}\] \\
    \[get_pins ${pin_o}\] 
"]

            set pins(${clk}) [get_pins \
                    -of_objects [get_nets \
                    -segments \
                    -of_objects  [get_clocks ${clk}] \
                ] \
                -filter {direction==in && is_leaf}]
        }

        dbg_puts "Stop propogation:"
        set clocks_on_pins [array names pins]
        foreach clk [lsort -dictionary [array names pins]] {
            dbg_puts "  Clock: ${clk}"
            #set clocks_on_pins [lsort -dictionary -unique [get_clocks -of_objects [get_pins $pins(${clk})]]]
            dbg_puts "    Clocks on pins: ${clocks_on_pins}"
            set index [lsearch ${clocks_on_pins} "${clk}"]
            set stop_clocks [lreplace ${clocks_on_pins} ${index} ${index}]
            dbg_puts "    Clocks for stop: ${stop_clocks}"
            set strigns [lappend strigns "
set_clock_sense \\
    -stop_propagation -quiet \\
    -clocks { ${stop_clocks} } \\
    { $pins(${clk}) }
"]
        }

        foreach clk [lsort -dictionary [array names pins]] {
            dbg_puts "  Clock: ${clk}"
            ::tardil::pattern_to_name_and_shift ${clk} original_clock current_shift
            set inverted [expr fmod( ${current_shift}/180, 2)]
            dbg_puts "  Clock is inverted: ${inverted}"
            if {${inverted}} {
                set strigns [lappend strigns "\nset_property IS_INVERTED 1 \[get_pins { $pins(${clk}) }\]"]
            }
        }

        array unset pins
        #puts [join ${strigns} {\n}]
        #foreach str ${strigns} {
        #    puts ${str}
        #}
    }


    dbg_puts "Multicycles:"
    set strigns [lappend strigns "\n
set_multicycle_path ${max_multicycle_path} -from \[get_clocks *_${prefix}_*\]
set_multicycle_path ${max_multicycle_path} -to   \[get_clocks *_${prefix}_*\]
"]

    set shifts [list]
    set clks [lsearch -regexp -inline -all ${clocks} ".*_${prefix}_(n|p)\[0-9]*"]
    foreach clk ${clks} {
        ::tardil::pattern_to_name_and_shift ${clk} original_clock current_shift
        set shifts [lappend shifts ${current_shift}]
    }
    set shifts [lsort -dictionary -uniq ${shifts}]
    dbg_puts "  Shifts: ${shifts}"
    foreach current_shift ${shifts} {
        set index [lsearch ${shifts} "${current_shift}"]
        set another_shifts [lreplace ${shifts} ${index} ${index}]
        if { ${current_shift} < 0 } {
            set sign_current_shift "n"
        } else {
            set sign_current_shift "p"
        }
        foreach another_shift ${another_shifts} {
            if { ${another_shift} < 0 } {
                set sign_another_shift "n"
            } else {
                set sign_another_shift "p"
            }
            if { ${current_shift} <= ${another_shift} } {
                dbg_puts "      ${current_shift} -> ${another_shift}"
                set diff [expr abs(${current_shift} - ${another_shift})]
                dbg_puts "        diff shifts: ${diff}"
                if { ${diff} == 0 } {
                  set cnt_cycles 1
                } else {
                  set cnt_cycles [expr (${diff}/360) + 2]
                }
                dbg_puts "        count of cycles: ${cnt_cycles}"
                set start_name "*_${prefix}_${sign_current_shift}[format %0.4u [expr abs(${current_shift})]]"
                set end_name   "*_${prefix}_${sign_another_shift}[format %0.4u [expr abs(${another_shift})]]"
                set strigns [lappend strigns "
set_multicycle_path ${cnt_cycles} -setup -from \[get_clocks ${start_name}\] -to \[get_clocks ${end_name}\]
set_multicycle_path [expr ${cnt_cycles}-1] -hold -from \[get_clocks ${start_name}\] -to \[get_clocks ${end_name}\]"]
            }
        }
    }

    return [join ${strigns}]
}

proc ::tardil::old000_generate_with_multicycle {args} {
    variable prefix
    variable max_multicycle_path
    dbg_puts [info level 0]

    set strings [list]

    set clocks [lsort -uniq [get_clocks -regexp "(.*)_${prefix}_(n|p)\[0-9]*"]]
    dbg_puts "Finded clocks: ${clocks}"

    set clocks_000 [lsearch -regexp -inline -all ${clocks} "(.*)_${prefix}_(n|p)000\[0-0]*"]
    foreach clock_000 ${clocks_000} {

        regexp "(.*)_${prefix}_(n|p)\[0-9]*" ${clock_000} match orig_clock_name
        set strigns [lappend strigns "\n# ${orig_clock_name}"]

        dbg_puts "Original clock name: ${orig_clock_name}"
        set pin_o [get_pins -leaf -filter {direction==out} -of_objects [get_clocks ${clock_000}]]
        set pin_i [get_pins "[get_cells -of_objects ${pin_o}]/I"]
        dbg_puts "Pins for orig clock: ${pin_o}, ${pin_i}"

        set strigns [lappend strigns "
create_generated_clock \\
    -name ${clock_000} \\
    -divide_by 1 \\
    -source \[get_pins ${pin_i}\] \\
    \[get_pins ${pin_o}\] 

set_multicycle_path ${max_multicycle_path} -from \[get_clocks ${clock_000}\]
set_multicycle_path ${max_multicycle_path} -to   \[get_clocks ${clock_000}\]"]
        set clks [lsearch -regexp -inline -all ${clocks} "${orig_clock_name}_${prefix}_(n|p)\[0-9]*"]

        ::tardil::pattern_to_name_and_shift ${clock_000} original_clock shfit_for_current_clock
        dbg_puts "  Current shift: ${shfit_for_current_clock}"
        foreach clock_for_multicycle ${clks} {
          ::tardil::pattern_to_name_and_shift ${clock_for_multicycle} original_clock shfit_for_another_clock
          if { ${shfit_for_current_clock} <= ${shfit_for_another_clock} } {
            dbg_puts "    ${clock_for_multicycle}: ${shfit_for_another_clock}"
            set diff [expr abs(${shfit_for_current_clock} - ${shfit_for_another_clock})]
            dbg_puts "      diff shifts: ${diff}"
            if { ${diff} == 0 } {
              set cnt_cycles 1
            } else {
              set cnt_cycles [expr (${diff}/360) + 2]
            }
            dbg_puts "      count of cycles: ${cnt_cycles}"
            set strigns [lappend strigns "
set_multicycle_path ${cnt_cycles} -setup -from \[get_clocks ${clock_000}\] -to \[get_clocks ${clock_for_multicycle}\]
set_multicycle_path [expr ${cnt_cycles}-1] -hold -from \[get_clocks ${clock_000}\] -to \[get_clocks ${clock_for_multicycle}\]"]
          }
        }
        set strigns [lappend strigns "\n"]

        foreach clk ${clks} {
            dbg_puts "Clock: ${clk}"
            ::tardil::pattern_to_name_and_shift ${clk} original_clock current_shift
            dbg_puts "  Cuttenr shift ${current_shift} for clock ${original_clock}"
            set orig_clock_period [get_property period [get_clocks ${original_clock}]]
            dbg_puts "  Detected original clock: ${original_clock} (${orig_clock_period})"
            set target_shifted_clock_latency [expr ${orig_clock_period}*(${current_shift}/360.0)]
            dbg_puts "  Latency for clock: ${target_shifted_clock_latency}"
            set inverted [expr fmod( ${current_shift}/180, 2)]
            dbg_puts "  Clock is inverted: ${inverted}"
            if {${inverted}} {
                set strign_inverted "-invert"
            } else {
                set strign_inverted ""
            }

            if { ${clock_000} != ${clk} } {
                set strigns [lappend strigns "
create_generated_clock \\
    -add -divide_by 1 ${strign_inverted} \\
    -name ${clk} \\
    -master \[get_clocks ${original_clock}\] \\
    -source \[get_pins ${pin_i}\] \\
    \[get_pins ${pin_o}\] 

set_multicycle_path ${max_multicycle_path} -from \[get_clocks ${clk}\]
set_multicycle_path ${max_multicycle_path} -to   \[get_clocks ${clk}\]"]

              ::tardil::pattern_to_name_and_shift ${clk} original_clock shfit_for_current_clock
              dbg_puts "  Current shift: ${shfit_for_current_clock}"
              foreach clock_for_multicycle ${clks} {
                ::tardil::pattern_to_name_and_shift ${clock_for_multicycle} original_clock shfit_for_another_clock
                if { ${shfit_for_current_clock} <= ${shfit_for_another_clock} } {
                  dbg_puts "    ${clock_for_multicycle}: ${shfit_for_another_clock}"
                  set diff [expr abs(${shfit_for_current_clock} - ${shfit_for_another_clock})]
                  dbg_puts "      diff shifts: ${diff}"
                  if { ${diff} == 0 } {
                    set cnt_cycles 1
                  } else {
                    set cnt_cycles [expr (${diff}/360) + 2]
                  }
                  dbg_puts "      count of cycles: ${cnt_cycles}"
                  set strigns [lappend strigns "
set_multicycle_path ${cnt_cycles} -setup -from \[get_clocks ${clk}\] -to \[get_clocks ${clock_for_multicycle}\]
set_multicycle_path [expr ${cnt_cycles}-1] -hold -from \[get_clocks ${clk}\] -to \[get_clocks ${clock_for_multicycle}\]"]
                }
              }
            }
            set strigns [lappend strigns "\n"]

            set pins(${clk}) [get_pins \
                    -of_objects [get_nets \
                    -segments \
                    -of_objects  [get_clocks ${clk}] \
                ] \
                -filter {direction==in && is_leaf}]
        }

        dbg_puts "Stop propogation:"
        set clocks_on_pins [array names pins]
        foreach clk [lsort -dictionary [array names pins]] {
            dbg_puts "  Clock: ${clk}"
            #set clocks_on_pins [lsort -dictionary -unique [get_clocks -of_objects [get_pins $pins(${clk})]]]
            dbg_puts "    Clocks on pins: ${clocks_on_pins}"
            set index [lsearch ${clocks_on_pins} "${clk}"]
            set stop_clocks [lreplace ${clocks_on_pins} ${index} ${index}]
            dbg_puts "    Clocks for stop: ${stop_clocks}"
            set strigns [lappend strigns "
set_clock_sense \\
    -stop_propagation -quiet \\
    -clocks { ${stop_clocks} } \\
    { $pins(${clk}) } \\
"]
        }

        foreach clk [lsort -dictionary [array names pins]] {
            dbg_puts "  Clock: ${clk}"
            ::tardil::pattern_to_name_and_shift ${clk} original_clock current_shift
            set inverted [expr fmod( ${current_shift}/180, 2)]
            dbg_puts "  Clock is inverted: ${inverted}"
            if {${inverted}} {
                set strigns [lappend strigns "\nset_property IS_INVERTED 1 \[get_pins { $pins(${clk}) }\]"]
            }
        }

        array unset pins
        #puts [join ${strigns} {\n}]
        #foreach str ${strigns} {
        #    puts ${str}
        #}
    }
    return [join ${strigns}]
}

#set ::tardil::debug 99
#::tardil::init
#::tardil::init -debug 99
::tardil::init -debug 1

#namespace delete tardil; source ./tardil-1.0.tm; tardil::resolve_setup_slack [get_timing_paths]
#namespace delete tardil; source ./tardil-1.0.tm; tardil::resolve
#close_design ; close_project ; read_checkpoint ./checkpoint_1.dcp ; link_design
# config_timing_pessimism -common_node off


