
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
  CONFIG.CLKOUT2_REQUESTED_PHASE {90} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_REQUESTED_PHASE {180} \
  CONFIG.CLKOUT3_USED {true} \
  CONFIG.CLKOUT4_REQUESTED_PHASE {270} \
  CONFIG.CLKOUT4_USED {true} \
  CONFIG.CLKOUT5_REQUESTED_PHASE {360} \
  CONFIG.CLKOUT5_USED {true} \
  CONFIG.CLKOUT6_REQUESTED_PHASE {-90} \
  CONFIG.CLKOUT6_USED {true} \
  CONFIG.CLKOUT7_REQUESTED_PHASE {-180} \
  CONFIG.CLKOUT7_USED {true} \
  CONFIG.CLK_OUT1_PORT {clk__000} \
  CONFIG.CLK_OUT2_PORT {clk_p090} \
  CONFIG.CLK_OUT3_PORT {clk_p180} \
  CONFIG.CLK_OUT4_PORT {clk_p270} \
  CONFIG.CLK_OUT5_PORT {clk_p360} \
  CONFIG.CLK_OUT6_PORT {clk_n090} \
  CONFIG.CLK_OUT7_PORT {clk_n180} \
] [get_ips clk_wiz_0]
generate_target all [get_files  *.xci]



create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
  CONFIG.CLKOUT2_JITTER {130.958} \
  CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT2_REQUESTED_PHASE {90} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_JITTER {130.958} \
  CONFIG.CLKOUT3_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT3_REQUESTED_PHASE {180} \
  CONFIG.CLKOUT3_USED {true} \
  CONFIG.CLKOUT4_JITTER {130.958} \
  CONFIG.CLKOUT4_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT4_REQUESTED_PHASE {270} \
  CONFIG.CLKOUT4_USED {true} \
  CONFIG.CLKOUT5_JITTER {130.958} \
  CONFIG.CLKOUT5_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT5_REQUESTED_PHASE {360} \
  CONFIG.CLKOUT5_USED {true} \
  CONFIG.CLKOUT6_JITTER {130.958} \
  CONFIG.CLKOUT6_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT6_REQUESTED_PHASE {-90} \
  CONFIG.CLKOUT6_USED {true} \
  CONFIG.CLKOUT7_JITTER {130.958} \
  CONFIG.CLKOUT7_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT7_REQUESTED_PHASE {-180} \
  CONFIG.CLKOUT7_USED {true} \
  CONFIG.CLK_OUT1_PORT {clk__000} \
  CONFIG.CLK_OUT2_PORT {clk_p090} \
  CONFIG.CLK_OUT3_PORT {clk_p180} \
  CONFIG.CLK_OUT4_PORT {clk_p270} \
  CONFIG.CLK_OUT5_PORT {clk_p360} \
  CONFIG.CLK_OUT6_PORT {clk_n090} \
  CONFIG.CLK_OUT7_PORT {clk_n180} \
  CONFIG.MMCM_CLKOUT1_DIVIDE {10} \
  CONFIG.MMCM_CLKOUT1_PHASE {90.000} \
  CONFIG.MMCM_CLKOUT2_DIVIDE {10} \
  CONFIG.MMCM_CLKOUT2_PHASE {180.000} \
  CONFIG.MMCM_CLKOUT3_DIVIDE {10} \
  CONFIG.MMCM_CLKOUT3_PHASE {270.000} \
  CONFIG.MMCM_CLKOUT4_DIVIDE {10} \
  CONFIG.MMCM_CLKOUT4_PHASE {360.000} \
  CONFIG.MMCM_CLKOUT5_DIVIDE {10} \
  CONFIG.MMCM_CLKOUT5_PHASE {-90.000} \
  CONFIG.MMCM_CLKOUT6_DIVIDE {10} \
  CONFIG.MMCM_CLKOUT6_PHASE {-180.000} \
  CONFIG.NUM_OUT_CLKS {7} \
] [get_ips clk_wiz_0]
generate_target {instantiation_template} [get_files /home/muh/tardil/.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
generate_target all [get_files  /home/muh/tardil/.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
export_ip_user_files -of_objects [get_files /home/muh/tardil/.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci] -no_script -sync -force -quiet
export_simulation -of_objects [get_files /home/muh/tardil/.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci] -directory .ip_user_files/sim_scripts -ip_user_files_dir .ip_user_files -ipstatic_source_dir .ip_user_files/ipstatic -lib_map_path [list {modelsim=./.cache/compile_simlib/modelsim} {questa=./.cache/compile_simlib/questa} {xcelium=./.cache/compile_simlib/xcelium} {vcs=./.cache/compile_simlib/vcs} {riviera=./.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
refresh_design


create_generated_clock \
    -name test_negative_shifted \
    -divide_by 1 \
    -source [get_pins clocks_inst/BUFG_inst0/I] \
    [get_pins clocks_inst/BUFG_inst0/O]
 set_clock_latency \
     -source \
     -clock [get_clocks test_negative_shifted]\
     -0.4 [get_pins clocks_inst/BUFG_inst0/O]

