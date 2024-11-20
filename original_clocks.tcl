
create_clock -name original_clock -period 5.000 [get_ports clock]

set_input_delay 0.5 -clock [get_clocks original_clock] [get_ports in]
set_input_delay 0.5 -clock [get_clocks original_clock] [get_ports rst]
set_output_delay 0.5 -clock [get_clocks original_clock] [get_ports out]

