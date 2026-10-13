
set_context dft -edt

read_verilog hamming_top_scan.v

read_cell_library slow_vdd1v0.mdt

set_current_design

dofile hamming_top_scan.dofile

tessent_scan_setup

set_edt_options -channels 1

check_design_rules

report_edt_pins

report_edt_configurations

write_edt_files edt/created -verilog -replace -synthesis_script RTL_Compiler

exit
