
## set clocks {original_clock_tardil_p0000 original_clock_tardil_n0180 original_clock_tardil_p0180}
## 
## foreach clk ${clocks} {
##     set pins(${clk}) [get_pins \
##         -of_objects [get_nets \
##                         -segments \
##                         -of_objects  [get_clocks ${clk}] \
##                     ] \
##         -filter {direction==in && is_leaf}]
## }
## #array unset pins
 
## foreach clk ${clocks} {
##     create_generated_clock \
##         -add
##         -name ${clk} \
##         -divide_by 1 \
##         -source [get_pins clocks_inst/BUFG_inst0/I] \
##         [get_pins clocks_inst/BUFG_inst0/O] 
## }

set clk original_clock_tardil_p0000
create_generated_clock \
    -name ${clk} \
    -divide_by 1 \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_latency \
    -source \
    -clock ${clk} \
    0 \
        [get_pins clocks_inst/BUFG_inst0/O]

set clk original_clock_tardil_n0180
create_generated_clock \
    -add \
    -name ${clk} \
    -divide_by 1 \
    -master [get_clocks original_clock] \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_latency \
    -source \
    -clock ${clk} \
    -2.5 \
        [get_pins clocks_inst/BUFG_inst0/O]

set clk original_clock_tardil_p0180
create_generated_clock \
    -add \
    -name ${clk} \
    -divide_by 1 \
    -master [get_clocks original_clock] \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_latency \
    -source \
    -clock ${clk} \
    2.5 \
        [get_pins clocks_inst/BUFG_inst0/O]


set pins(original_clock_tardil_n0180) {i_dp_0/genblk1[0].register_i/q_reg/C i_dp_0/genblk1[1].register_i/q_reg/C i_dp_0/genblk1[2].register_i/q_reg/C i_dp_0/genblk1[3].register_i/q_reg/C i_dp_0/genblk1[4].register_i/q_reg/C i_dp_0/genblk1[5].register_i/q_reg/C i_dp_0/genblk1[6].register_i/q_reg/C i_dp_0/genblk1[7].register_i/q_reg/C i_dp_0/genblk1[8].register_i/q_reg/C i_dp_0/genblk1[9].register_i/q_reg/C}
set pins(original_clock_tardil_p0000) {i_dp_2/genblk1[0].register_i/q_reg/C i_dp_2/genblk1[1].register_i/q_reg/C i_dp_2/genblk1[2].register_i/q_reg/C i_dp_2/genblk1[3].register_i/q_reg/C i_dp_2/genblk1[4].register_i/q_reg/C i_dp_2/genblk1[5].register_i/q_reg/C i_dp_2/genblk1[6].register_i/q_reg/C i_dp_2/genblk1[7].register_i/q_reg/C i_dp_2/genblk1[8].register_i/q_reg/C i_dp_2/genblk1[9].register_i/q_reg/C rst_sync/sync_reg_reg[0]/C rst_sync/sync_reg_reg[1]/C}
set pins(original_clock_tardil_p0180) {i_dp_1/genblk1[0].register_i/q_reg/C}


foreach clk [lsort -dictionary [array names pins]] {
    puts "${clk}:"
    set clocks_on_pins [lsort -dictionary -unique [get_clocks -of_objects [get_pins $pins(${clk})]]]
    set index [lsearch ${clocks_on_pins} "${clk}"]
    set stop_clocks [lreplace ${clocks_on_pin} ${index} ${index}]
    puts "    stop: ${stop_clocks}"
    set_clock_sense \
        -quiet \
        -stop_propagation \
        -clocks ${stop_clocks} \
        $pins(${clk})
}

## foreach clk [lsort -dictionary [array names pins]] {
##     puts "${clk}:"
##     foreach pin $pins(${clk}) {
##         #puts "  pin:${pin}"
##         set clocks_on_pin [get_clocks -of_objects [get_pins ${pin}]]
##         #puts "    clocks :${clocks_on_pin}"
##         set index [lsearch ${clocks_on_pin} "${clk}"]
##         #puts "    index:${index}"
##         set stop_clocks [lreplace ${clocks_on_pin} ${index} ${index}]
##         puts "    stop: ${stop_clocks}"
##         set_clock_sense \
##             -stop_propagation \
##             -clocks ${stop_clocks} \
##             ${pin}
##     }
## }



## create_generated_clock \
##   -name clock__000 \
##   -source [get_pins clocks_inst/BUFG_inst0/I] \
##   -edges {1 2 3} \
##   -edge_shift {0 0 0} \
##   [get_pins clocks_inst/BUFG_inst0/O] 
## 
## create_generated_clock \
##   -add \
##   -master_clock clock__000 \
##   -name clock_n180 \
##   -source [get_pins clocks_inst/BUFG_inst0/I] \
##   -edges {1 2 3} \
##   -edge_shift {-2.5 -2.5 -2.5} \
##   [get_pins clocks_inst/BUFG_inst0/O] 
## 
## create_generated_clock \
##   -add \
##   -master_clock clock__000 \
##   -name clock_p180 \
##   -source [get_pins clocks_inst/BUFG_inst0/I] \
##   -edges {1 2 3} \
##   -edge_shift {2.5 2.5 2.5} \
##   [get_pins clocks_inst/BUFG_inst0/O] 
## 
## # set_clock_sense \
## #   -stop_propagation  \
## #   -clocks [get_clocks {clock_p* clock_n*}] \
## #   [get_pins \
## #     -filter {direction==in && IS_LEAF==true && IS_CLOCK==true} \
## #     -of_objects [
## #       get_nets \
## #         -segments \
## #         -of_objects  [get_clocks clock__000] \
## #     ] \
## #   ]
## 
