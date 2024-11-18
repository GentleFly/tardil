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

proc ::tardil::summ_slack {args} {
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

    report_timing \
        -name bob \
        -to [get_cells i_dp_1/genblk1[0].register_i/q_reg] \
        -slack_lesser_than 99999 \
        -max_paths 99999 \
        -nworst 9999 \
        -hold
    get_property SLACK  [get_timing_paths  -to [get_cells i_dp_1/genblk1[0].register_i/q_reg] -slack_lesser_than 99999 -max_paths 99999 -nworst 9999 -setup]
    CORNER Slow
    CORNER Fast
    
    ::tcl::mathop::+ {*}[get_property SLACK \
        [get_timing_paths  \
            -to [get_cells i_dp_1/genblk1[0].register_i/q_reg] \
            -slack_lesser_than 99999 \
            -max_paths 99999 \
            -nworst 9999 \
            -setup \
            -filter {CORNER==Slow}
        ] \
    ]

    ::tcl::mathop::+ {*}[get_property SLACK \
        [get_timing_paths  \
            -to [get_cells i_dp_1/genblk1[0].register_i/q_reg] \
            -slack_lesser_than 99999 \
            -max_paths 99999 \
            -nworst 9999 \
            -hold \
            -filter {CORNER==Fast}
        ] \
    ]


    set setup_timing_paths [get_timing_paths  \
        -to [get_cells i_dp_1/genblk1[0].register_i/q_reg] \
        -slack_lesser_than 99999 \
        -max_paths 99999 \
        -nworst 9999 \
        -setup \
        -filter {CORNER==Slow}
    ]
    set count_of_setup_timing_paths [llength ${setup_timing_paths}]
    set slacks_for_setup_timing_paths [get_property SLACK ${setup_timing_paths}]
    set min_slack_for_setup_timing_paths [get_property -min SLACK ${setup_timing_paths}]
    set sum_of_slack_for_setup_timing_paths [::tcl::mathop::+ {*}${slacks_for_setup_timing_paths}]

    set hold_timing_paths [get_timing_paths  \
        -to [get_cells i_dp_1/genblk1[0].register_i/q_reg] \
        -slack_lesser_than 99999 \
        -max_paths 99999 \
        -nworst 9999 \
        -hold \
        -filter {CORNER==Fast}
    ]
    set count_of_hold_timing_paths [llength ${hold_timing_paths}]
    set slacks_for_hold_timing_paths [get_property SLACK ${hold_timing_paths}]
    set min_slack_for_hold_timing_paths [get_property -min SLACK ${hold_timing_paths}]
    set sum_of_slack_for_hold_timing_paths [::tcl::mathop::+ {*}${slacks_for_hold_timing_paths}]

    array unset params
    return
}

proc ::tardil::check_changes_window {timing_path} {
    if {[llength ${timing_path}] != 1} {
        error "Error: ::tardil::check_changes_window <timing_path>"
    } else {
        dbg_puts "Timing path: ${timing_path}"
    }
    if { [get_property DELAY_TYPE ${timing_path}] == "min" } {
        set timing_path [get_timing_paths -setup -through [get_pins -of_objects ${timing_path}]]
    }

    set startpoint_cell   [get_property PARENT_CELL [get_property STARTPOINT_PIN ${timing_path}]]
    set startpoint_period [get_property PERIOD [get_property STARTPOINT_CLOCK ${timing_path}]]
    dbg_puts "Start point period: ${startpoint_period}"

    set endpoint_cell   [get_property PARENT_CELL [get_property ENDPOINT_PIN   ${timing_path}]]
    set endpoint_period [get_property PERIOD [get_property ENDPOINT_CLOCK ${timing_path}]]
    dbg_puts "End point period: ${endpoint_period}"

    set max_delay [get_property DATAPATH_DELAY ${timing_path}]
    dbg_puts "Max delay: ${max_delay}"
    set min_delay [get_property DATAPATH_DELAY [get_timing_paths -hold -through [get_pins -of_objects ${timing_path}]]]
    dbg_puts "Min delay: ${min_delay}"

    set startpoint_changes_window [expr ${max_delay} - ${min_delay}]
    dbg_puts "Changes window: ${startpoint_changes_window}"

    if { ${startpoint_changes_window} > ${startpoint_period} } {
        error "Error: Changes window is more than clock period!"
    }
    return
}

proc ::tardil::reslove {args} {
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

    set startpoint_cell   [get_property PARENT_CELL [get_property STARTPOINT_PIN ${timing_path}]]
    dbg_puts "Start point: ${startpoint_cell}"
    set startpoint_period [get_property PERIOD [get_property STARTPOINT_CLOCK ${timing_path}]]
    dbg_puts "Start point period: ${startpoint_period}"
    set startpoint_shift_step [expr ${startpoint_period}*($params(clock_shift_step)/360.0)]
    dbg_puts "Start point shift step: ${startpoint_shift_step}"

    set endpoint_cell   [get_property PARENT_CELL [get_property ENDPOINT_PIN   ${timing_path}]]
    dbg_puts "End point: ${endpoint_cell}"
    set endpoint_period [get_property PERIOD [get_property ENDPOINT_CLOCK ${timing_path}]]
    dbg_puts "End point period: ${endpoint_period}"
    set endpoint_shift_step [expr ${endpoint_period}*($params(clock_shift_step)/360.0)]
    dbg_puts "End point shift step: ${startpoint_shift_step}"

    if { ${startpoint_cell} == ${endpoint_cell} } {
        error "Start cell and end cell is same!"
    }

    set timing_paths(setup,to,startpoint)   [get_timing_paths -setup -filter {CORNER==Slow} -to   ${startpoint_cell} -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    set timing_paths(hold,to,startpoint)    [get_timing_paths -hold  -filter {CORNER==Fast} -to   ${startpoint_cell} -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    set timing_paths(setup,from,startpoint) [get_timing_paths -setup -filter {CORNER==Slow} -from ${startpoint_cell} -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    set timing_paths(hold,from,startpoint)  [get_timing_paths -hold  -filter {CORNER==Fast} -from ${startpoint_cell} -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    set timing_paths(setup,to,endpoint)     [get_timing_paths -setup -filter {CORNER==Slow} -to   ${endpoint_cell}   -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    set timing_paths(hold,to,endpoint)      [get_timing_paths -hold  -filter {CORNER==Fast} -to   ${endpoint_cell}   -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    set timing_paths(setup,from,endpoint)   [get_timing_paths -setup -filter {CORNER==Slow} -from ${endpoint_cell}   -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    set timing_paths(hold,from,endpoint)    [get_timing_paths -hold  -filter {CORNER==Fast} -from ${endpoint_cell}   -slack_lesser_than 99999 -max_paths 99999 -nworst 9999]
    dbg_puts "Timing paths: [array get timing_paths]"

    foreach tp [array names timing_paths] {
        dbg_puts "    Timing path: ${tp}"
        set path_cnt(${tp})     [llength $timing_paths(${tp})]
        dbg_puts "        path_cnt: $path_cnt(${tp})"
        set min_slak(${tp})     [get_property SLACK -min $timing_paths(${tp})]
        dbg_puts "        min_slak: $min_slak(${tp})"
        set slacks(${tp})        [get_property SLACK $timing_paths(${tp})]
        dbg_puts "        slack:    $slacks(${tp})"
        set sum_of_slack(${tp}) [::tcl::mathop::+ {*}$slacks(${tp})]
        dbg_puts "        sum_of_slack: $sum_of_slack(${tp})"
    }

    set setup_slack [get_property SLACK ${timing_path}]
    dbg_puts "Setup Slack: ${setup_slack}"
    set hold_slack [get_property SLACK [get_timing_paths -hold -through [get_pins -of_objects ${timing_path}]]]
    dbg_puts "Hold Slack: ${hold_slack}"

    if { ${setup_slack} < 0 } {
        set cnt_step [expr int(abs(${setup_slack})/${startpoint_shift_step}) + 1]
        for {set i 0} {${i} < ${cnt_step}+1} {incr i} {
            set startpoint_shift_cnt ${i}
            set endpoint_shift_cnt [expr ${cnt_step} - ${i}]
            dbg_puts "Step for startpoint and step for endpoint: \[${startpoint_shift_cnt} : ${endpoint_shift_cnt}\]"


            set startpoint_shift [expr ${startpoint_shift_cnt}*${startpoint_shift_step}]
            dbg_puts "    Startpoint shift: ${startpoint_shift}"
            set sts [expr $sum_of_slack(setup,to,startpoint) - (${startpoint_shift}*$path_cnt(setup,to,startpoint))]
            #dbg_puts "      setup,to,startpoint: ${sts}"
            set hts [expr $sum_of_slack(hold,to,startpoint) + (${startpoint_shift}*$path_cnt(hold,to,startpoint))]
            #dbg_puts "      hold,to,startpoint: ${hts}"

            set endpoint_shift [expr ${endpoint_shift_cnt}*${endpoint_shift_step}]
            dbg_puts "    Endpoint shift: ${endpoint_shift}"
            set sfe [expr $sum_of_slack(setup,from,endpoint) - (${endpoint_shift}*$path_cnt(setup,from,endpoint))]
            #dbg_puts "      setup,from,endpoint: ${sfe}"
            set hfe [expr $sum_of_slack(hold,from,endpoint) + (${endpoint_shift}*$path_cnt(hold,from,endpoint))]
            #dbg_puts "      hold,from,endpoint: ${hfe}"

            set weight [tcl::mathfunc::min ${sts} ${hts} ${sfe} ${hfe}]
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
        dbg_puts "Selected steps: \[${selected_startpoint_shift_cnt} : ${selected_endpoint_shift_cnt}\]"
        # TODO: ....
    }
    if { ${hold_slack} < 0 } {
        puts [expr int(abs(${hold_slack})/${startpoint_shift_step}) + 1]
    }

    #namespace delete tardil; source ./tardil-1.0.tm; tardil::reslove [get_timing_paths]

    array unset path_cnt
    array unset min_slak
    array unset slack
    array unset sum_of_slack

    array unset timing_path
    array unset params
    return
}

#set ::tardil::debug 99
#::tardil::init
::tardil::init -debug 99

