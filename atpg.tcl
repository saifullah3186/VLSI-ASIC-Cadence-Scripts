#---------------------------------------------------------------#
#                                                               #
#             TRANSITION ATPG FLOW                              #
#                                                               #
#---------------------------------------------------------------#

set_logfile_handling atpg.log -rep

#set_tsdb_output_directory ./tsdb_outdir

set_context patterns -scan

read_verilog noscan.v
read_cell_library slow_vdd1v0.mdt


#set_logfile_handling pattern_generation.log -rep

set_current_design

#add_black_boxes -auto 

# Load generated test procedure file
dofile sd_scan_testproc_verify_scan_modes.dofile


# Add faults
add_faults -all

# Generate ATPG patterns
create_patterns

# ATPG reports
report_statistics
report_faults -summary

# Export generated patterns
write_patterns ../patterns_ascii.v -Verilog -rep

#write_patterns tsdb_outdir/patterns.patdb -patdb -rep

#run_testbench_simulations

exit

#---------------------------------------------------------------#
# END OF FLOW
#---------------------------------------------------------------#
