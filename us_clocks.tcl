
create_generated_clock \
  -name clock__000 \
  -source [get_pins clocks_inst/BUFG_inst0/I] \
  -edges {1 2 3} \
  -edge_shift {0 0 0} \
  [get_pins clocks_inst/BUFG_inst0/O] 

create_generated_clock \
  -add \
  -master_clock clock__000 \
  -name clock_n180 \
  -source [get_pins clocks_inst/BUFG_inst0/I] \
  -edges {1 2 3} \
  -edge_shift {-2.5 -2.5 -2.5} \
  [get_pins clocks_inst/BUFG_inst0/O] 

create_generated_clock \
  -add \
  -master_clock clock__000 \
  -name clock_p180 \
  -source [get_pins clocks_inst/BUFG_inst0/I] \
  -edges {1 2 3} \
  -edge_shift {2.5 2.5 2.5} \
  [get_pins clocks_inst/BUFG_inst0/O] 

# set_clock_sense \
#   -stop_propagation  \
#   -clocks [get_clocks {clock_p* clock_n*}] \
#   [get_pins \
#     -filter {direction==in && IS_LEAF==true && IS_CLOCK==true} \
#     -of_objects [
#       get_nets \
#         -segments \
#         -of_objects  [get_clocks clock__000] \
#     ] \
#   ]

