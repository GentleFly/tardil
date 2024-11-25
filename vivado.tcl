proc rr {} {
  source ./vivado.tcl
}

if { [current_design -quiet] != "" } {
  close_design
  remove_files [get_files -quiet *]
}
if { [current_project -quiet] != "" } {
  close_project
}

#set_part xc7k325tffg676-2
set_part xcvu19p-fsvb3824-2-e

set files { \
  ./inv.sv \
  ./winv.sv \
  ./register.sv \
  ./comb_path.sv \
  ./data_path.sv \
  ./clocks.sv \
  ./sync.sv \
  ./top.sv \
}

set constraints { \
  ./original_clocks.tcl \
}

foreach f ${files} {
  read_verilog ${f}
}

foreach c ${constraints} {
  read_xdc -mode out_of_context ${c}
}

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
  CONFIG.CLKOUT1_REQUESTED_PHASE {0} \
  CONFIG.CLKOUT2_REQUESTED_PHASE {90} \
  CONFIG.CLKOUT3_REQUESTED_PHASE {180} \
  CONFIG.CLKOUT4_REQUESTED_PHASE {270} \
  CONFIG.CLKOUT5_REQUESTED_PHASE {360} \
  CONFIG.CLKOUT6_REQUESTED_PHASE {-90} \
  CONFIG.CLKOUT7_REQUESTED_PHASE {-180} \
  CONFIG.CLK_OUT1_PORT {clk_p000} \
  CONFIG.CLK_OUT2_PORT {clk_p090} \
  CONFIG.CLK_OUT3_PORT {clk_p180} \
  CONFIG.CLK_OUT4_PORT {clk_p270} \
  CONFIG.CLK_OUT5_PORT {clk_p360} \
  CONFIG.CLK_OUT6_PORT {clk_n090} \
  CONFIG.CLK_OUT7_PORT {clk_n180} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_USED {true} \
  CONFIG.CLKOUT4_USED {true} \
  CONFIG.CLKOUT5_USED {true} \
  CONFIG.CLKOUT6_USED {true} \
  CONFIG.CLKOUT7_USED {true} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT6_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT7_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.PRIM_IN_FREQ {200.000} \
] [get_ips clk_wiz_0]
generate_target all [get_ips]
synth_ip [get_ips]


synth_design \
  -top top \
  -mode out_of_context

opt_design

report_timing_summary \
  -delay_type min_max \
  -report_unconstrained \
  -check_timing_verbose \
  -max_paths 10 \
  -input_pins \
  -name timing_1

write_checkpoint ./syn.dcp -force

# place_design
# phys_opt_design -directive ExploreWithHoldFix
# route_design

