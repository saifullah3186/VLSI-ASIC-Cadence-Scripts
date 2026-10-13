# =====================================================================
# mbist.tcl
# Tessent MBIST insertion for sram_bist_checksum_top
#
# Rebuilt from your mbist_soc_top.tcl template. Filenames, top module,
# and the memory model now point at your actual project files instead
# of the tutorial's block_top/SYNC_1RW_8Kx16 placeholders.
# =====================================================================

#set_logfile_handling log/mbist.log -replace

# VERIFY: the reference script used -rtl here, which matches Tessent's
# documented flow (MemoryBIST as the FIRST insertion pass, done at RTL,
# before synthesis - see "First DFT Insertion Pass: MemoryBIST and
# Boundary Scan" in the Tessent Shell manual). You currently have an
# already-synthesized gate netlist (sram_bist_checksum_top_netlist.v),
# not RTL source. Confirm with your manual whether -rtl context accepts
# a gate-level netlist directly for MBIST insertion, or whether you
# need to go back to pre-synthesis RTL and redo synthesis afterward -
# this decision affects whether the read_verilog line below is even
# the right input file.
set_context dft -rtl

# Pin-direction/bus-type library for the std cells (does NOT contain
# the SRAM macro model - confirmed earlier, only sky130_fd_sc_hd__*
# cells are in this file)
read_cell_library sky130_hd.mdt

# Your actual gate-level netlist
read_verilog sram_bist_checksum_top_netlist.v

# Interface-only stub for the SRAM macro (ports only, no behavior).
# check_design_rules explicitly requires a real module definition for
# MBIST to bind the .tcd_memory port map against - black-boxing alone
# (which worked fine for scan insertion) is not sufficient here.
read_verilog sky130_sram_1kbyte_1rw1r_8x1024_8.v -interface_only

# Memory BIST model for your actual SRAM (rebuilt - see companion file)
read_core_descriptions sky130_sram_1kbyte_1rw1r_8x1024_8(1).tcd_memory

set_tsdb_output_directory tsdb_mbist

set_current_design sram_bist_checksum_top

# "core" fits your case: sram_bist_checksum_top is a standalone
# memory-test top, not a block being inserted into a larger chip
# (per the reference script's own comment distinguishing the two)
set_design_level physical_block


set_dft_specification_requirements -memory_test on

# Matches your SDC: create_clock -name "clk" -period 10.0
add_clocks clk -period 10ns -label clk

check_design_rules

set spec [create_dft_specification]
process_dft_specification

extract_icl

set pspec [create_patterns_specification]
process_patterns_specification

write_design -tsdb
write_icl tsdb_mbist/sram_bist_checksum_top_mbist.icl -replace
