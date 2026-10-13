#========================================================
# GENUS SYNTHESIS FLOW
# Design: hamming_top
# Genus: 16.23
#========================================================

#--------------------------------------------------------
# Library / search path setup
#--------------------------------------------------------

#--------------------------------------------------------
# Read RTL - top + all submodules in the hierarchy
#--------------------------------------------------------
read_hdl rtl/hamming_top.v
read_hdl rtl/hamming_encoder_13_8.v
read_hdl rtl/hamming_decoder_13_8.v
read_hdl rtl/async_fifo_8_fix.v
read_hdl rtl/async_fifo_13_fix.v

#--------------------------------------------------------
# Read standard-cell timing library
# FILL IN: your actual ihp130 .lib filename
#--------------------------------------------------------
read_libs libs/slow_vdd1v0_basicCells.lib

#--------------------------------------------------------
# power optimization
#--------------------------------------------------------
set_db lp_insert_clock_gating true
set_db lp_insert_clock_gating_incremental true
set_db lp_clock_gating_infer_enable true

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
# FILL IN: your actual hamming_top SDC filename
#--------------------------------------------------------
read_sdc constraints/hamming.sdc

#--------------------------------------------------------
# Check timing constraints
#--------------------------------------------------------
check_timing

#--------------------------------------------------------
# Synthesis effort
#--------------------------------------------------------
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

#========================================================
# LOW POWER: CLOCK GATING INSERTION
# Uncomment BOTH lines below to enable low-power synthesis.
# Leave commented out for the normal/baseline run.
# Must be set before syn_generic.
#========================================================

#========================================================

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
# Reports
# NOTE: these filenames are shared between baseline and LP
# runs. Before switching the toggle above and rerunning,
# rename/move the reports/ and genus/ output directories
# (e.g. reports -> reports_baseline) or this run will
# overwrite the previous results.
#--------------------------------------------------------
report_timing -max_paths 10 > reports/hamming_top_opt.timing.rpt
report_area                  > reports/hamming_top_opt.area.rpt
report_power                 > reports/hamming_top_opt.power.rpt
report_gates                 > reports/hamming_top_opt.gates.rpt
report_qor                   > reports/hamming_top_opt.qor.rpt

#--------------------------------------------------------
# Final design check
#--------------------------------------------------------
check_design -all

#--------------------------------------------------------
# Create output directories if required
#--------------------------------------------------------


#--------------------------------------------------------
# Write synthesized gate-level netlist
#--------------------------------------------------------
write_hdl > outputs/hamming_top_synth_opt.v

#--------------------------------------------------------
# Write synthesized SDC (for STA / DFT flows downstream)
#--------------------------------------------------------
write_sdc > outputs/hamming_top_synth_opt.sdc



