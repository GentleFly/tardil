proc rr {} {
  source ./vivado.tcl
}

if { [current_design -quiet] != "" } {
  close_design
  remove_files [get_files -quiet *]
}

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

# origin:  -part xc7k325tffg676-2
# origin:  -part xc7k325tffg676-2
# origin:  -part xcvu19p-fsvb3824-2-e
synth_design \
  -part xcvu19p-fsvb3824-2-e \
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

