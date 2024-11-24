# original_clock 
create_generated_clock \
    -name original_clock_tardil_p0000 \
    -divide_by 1 \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_latency \
    -source \
    -clock original_clock_tardil_p0000 \
    0 \
    [get_pins clocks_inst/BUFG_inst0/O] 
create_generated_clock \
    -add -divide_by 1 -invert \
    -name original_clock_tardil_n0180 \
    -master [get_clocks original_clock] \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_latency \
    -source \
    -clock original_clock_tardil_n0180 \
    -2.5 \
    [get_pins clocks_inst/BUFG_inst0/O] 
create_generated_clock \
    -add -divide_by 1 -invert \
    -name original_clock_tardil_p0180 \
    -master [get_clocks original_clock] \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_latency \
    -source \
    -clock original_clock_tardil_p0180 \
    2.5 \
    [get_pins clocks_inst/BUFG_inst0/O] 
create_generated_clock \
    -add -divide_by 1  \
    -name original_clock_tardil_p0360 \
    -master [get_clocks original_clock] \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_latency \
    -source \
    -clock original_clock_tardil_p0360 \
    5.0 \
    [get_pins clocks_inst/BUFG_inst0/O] 
set_clock_sense \
    -stop_propagation -quiet \
    -clocks { original_clock_tardil_p0000 original_clock_tardil_p0360 original_clock_tardil_p0180 } \
    { rst_sync/sync_reg_reg[0]/C } 
set_clock_sense \
    -stop_propagation -quiet \
    -clocks { original_clock_tardil_n0180 original_clock_tardil_p0360 original_clock_tardil_p0180 } \
    { i_dp_0/genblk1[0].register_i/q_reg/C i_dp_0/genblk1[1].register_i/q_reg/C i_dp_0/genblk1[2].register_i/q_reg/C i_dp_0/genblk1[3].register_i/q_reg/C i_dp_0/genblk1[4].register_i/q_reg/C i_dp_0/genblk1[5].register_i/q_reg/C i_dp_0/genblk1[6].register_i/q_reg/C i_dp_0/genblk1[7].register_i/q_reg/C i_dp_0/genblk1[8].register_i/q_reg/C i_dp_0/genblk1[9].register_i/q_reg/C i_dp_2/genblk1[1].register_i/q_reg/C i_dp_2/genblk1[2].register_i/q_reg/C i_dp_2/genblk1[3].register_i/q_reg/C i_dp_2/genblk1[4].register_i/q_reg/C i_dp_2/genblk1[5].register_i/q_reg/C i_dp_2/genblk1[6].register_i/q_reg/C i_dp_2/genblk1[7].register_i/q_reg/C i_dp_2/genblk1[8].register_i/q_reg/C i_dp_2/genblk1[9].register_i/q_reg/C rst_sync/sync_reg_reg[1]/C } 
set_clock_sense \
    -stop_propagation -quiet \
    -clocks { original_clock_tardil_n0180 original_clock_tardil_p0000 original_clock_tardil_p0360 } \
    { i_dp_2/genblk1[0].register_i/q_reg/C } 
set_clock_sense \
    -stop_propagation -quiet \
    -clocks { original_clock_tardil_n0180 original_clock_tardil_p0000 original_clock_tardil_p0180 } \
    { i_dp_1/genblk1[0].register_i/q_reg/C } 
set_property IS_INVERTED 1 [get_pins { rst_sync/sync_reg_reg[0]/C }] 
set_property IS_INVERTED 1 [get_pins { i_dp_2/genblk1[0].register_i/q_reg/C }]

