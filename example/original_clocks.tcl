
create_clock -name original_clock -period 5.000 [get_ports clock]
set_clock_latency -min -source -clock original_clock 0.4 [get_ports clock] 
set_clock_latency -max -source -clock original_clock 0.6 [get_ports clock] 

# set_false_path -through [get_ports rst_i]
set_input_delay 0.5 -clock [get_clocks original_clock] [get_ports in]
set_input_delay 0.5 -clock [get_clocks original_clock] [get_ports rst_i]
set_output_delay 0.5 -clock [get_clocks original_clock] [get_ports out]

