#---------------------------------------------------------------#
# STEP 3 - SCAN INSERTION : hamming_top   (Tessent Shell 2022.4)
# Input : Genus netlist + SDC (re-synthesised, see FLOW notes)
#---------------------------------------------------------------#
set_logfile_handling logs/scan_insertion_1.log -rep

set_context dft -scan

read_verilog hamming_top_synth_opt.v
read_cell_library slow_vdd1v0.mdt
read_sdc hamming_top_synth_opt.sdc

set_current_design hamming_top

# Clocks = PIs uio[0] clk_in, uio[1] clk_core, uio[2] clk_out
# Async reset = uio[3] (flop RN pins, active low) -> must be OFF during shift
# 12 Genus clock gates (TLATNTSCAX2) -> their SE pin must be driven by
# scan_en, otherwise gated clocks stop during shift. Read the
# analyze_control_signals report before going on.
analyze_control_signals -auto_fix

set_test_logic -clock on

set_system_mode analysis

# 124 flops in the synthesised netlist. Chains are kept per clock domain;
# 6 chains gives EDT something to compress (3 chains would not).
add_scan_mode int_mode -type internal -chain_count 6 -single_power_domain_chains on

analyze_scan_chains

insert_test_logic
report_scan_chains
write_scan_order hamming_top.scandef

write_design -output_file hamming_top_scan.v -rep
write_atpg_setup hamming_top_scan -procfile -rep     ;# -> hamming_top_scan.dofile / .testproc
exit
