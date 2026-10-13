#------------------------------------------------------------
# STEP 6 - IJTAG network insertion (GATE-LEVEL, post-EDT)
# Tessent Shell 2022.4, design: hamming_top_edt_top
#------------------------------------------------------------
set_logfile_handling logs/ijtag_insert.log -replace

set_context dft -no_rtl

read_verilog created_edt_top_gate.v
read_cell_library slow_vdd1v0.mdt

set_current_design hamming_top_edt_top

# REQUIRED before add_dft_signals - this was the missing line that caused
# the "design level must be set" error.
# 'chip' requires every port to terminate in a real pad cell from the
# library (pad_pad_io type) - this netlist has no pad ring, so 'chip'
# fails with "Port ... is not connected to a pad cell." Use 'physical'
# instead.
set_design_level physical

set_system_mode setup

# Map the plain ports the EDT step left behind onto named DFT signals so
# the IJTAG spec knows what to wrap. Confirmed patterns from
# 'help add_dft_signals':
add_dft_signals ltest_en async_set_reset_static_disable
add_dft_signals scan_en -source_nodes scan_en

# edt_clock / edt_update pattern from the help text's EDT example, adapted
# since our edt_clock is already a real port (not derived from a shared
# test_clock) - confirm this works as written, it is not a literal example
# from the help text:
add_dft_signals edt_update -source_nodes edt_update
add_dft_signals edt_clock  -source_nodes edt_clock

# UNCONFIRMED -> now CONFIRMED WRONG: "edt_bypass" is not a registered
# DFT signal name (tool printed the full allowed list). Based on that
# list and what the edt_bypass port actually does (mux-selects between
# direct scan and EDT-compressed channels, per the bypass_logic module
# in created_edt_top_gate.v), the correct signal name is edt_mode - the
# port name stays the same, only the signal keyword changes:
add_dft_signals edt_mode -source_nodes edt_bypass

# Added: these three add_clocks calls were run in the log and cleared the 3 DFT_C6 errors.
add_clocks {uio[0]} -period 20ns
add_clocks {uio[1]} -period 10ns
add_clocks {uio[2]} -period 20ns

# edt_channels_in1/edt_channels_out1 are left undeclared here - these look
# like scan-chain-style data ports, not control signals, so they likely
# belong under set_icl_scan_interface_ports instead of add_dft_signals.
# Check 'help set_icl_scan_interface_ports' before adding them.

set_dft_specification_requirements -logic_test on -host_scan_interface_type ijtag

check_design_rules

set spec [create_dft_specification]
report_config_data $spec
# Review / edit before processing:
#   report_config_syntax $spec

process_dft_specification

extract_icl
write_design -tsdb -replace

exit
