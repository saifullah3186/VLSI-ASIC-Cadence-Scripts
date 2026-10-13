
#========================================================
# GENUS SYNTHESIS FLOW
# Design: sequence_detector_4bit
# Genus: 16.23
#========================================================

#--------------------------------------------------------
# Read RTL
#--------------------------------------------------------
read_hdl rtl/hamming_top.v
read_hdl rtl/hamming_decoder_13_8.v
read_hdl rtl/hamming_encoder_13_8.v
read_hdl rtl/async_fifo_13_fix.v
read_hdl rtl/async_fifo_8_fix.v

#--------------------------------------------------------
# Read standard-cell timing library
#--------------------------------------------------------
read_libs libs/slow_vdd1v0_basicCells.lib


#--------------------------------------------------------
# Elaborate design
#--------------------------------------------------------
elaborate 

current_design hamming_top
#--------------------------------------------------------
# Check RTL
#--------------------------------------------------------
check_design -all

#--------------------------------------------------------
# Read timing constraints
#--------------------------------------------------------
read_sdc constraints/hamming.sdc

#--------------------------------------------------------
# Check timing constraints
#--------------------------------------------------------
check_timing

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium


#--------------------------------------------------------
# Generic synthesis
#--------------------------------------------------------
syn_generic

#--------------------------------------------------------
# Technology mapping
#--------------------------------------------------------
syn_map

#--------------------------------------------------------
# Optimization
#--------------------------------------------------------
syn_opt

#--------------------------------------------------------
# Timing report
#--------------------------------------------------------
report_timing -max_paths 10 > reports/hamming_top.timing.rpt
report_area                  > reports/hamming_top.area.rpt
report_power                 > reports/hamming_top.power.rpt
report_gates                 > reports/hamming_top.gates.rpt
report_qor                   > reports/hamming_top.qor.rpt


#--------------------------------------------------------
# Area report
#--------------------------------------------------------


#--------------------------------------------------------
# Final design check
#--------------------------------------------------------
check_design -all

#--------------------------------------------------------
# Create output directory if required
#--------------------------------------------------------
# outputs directory should already exist

#--------------------------------------------------------
# Write synthesized gate-level netlist
#--------------------------------------------------------
write_hdl > outputs/noscan.v

#--------------------------------------------------------
# Write synthesized SDC
#--------------------------------------------------------
write_sdc > outputs/synth.sdc

