set_logfile_handling logs/atpg_edt.log -rep

set_context patterns -scan

read_verilog edt/created_edt_top_gate.v

read_cell_library libs/slow_vdd1v0.mdt

set_current_design 

dofile edt/created_edt.dofile

set_system_mode analysis

report_edt_configurations

create_patterns 

report_scan_volume 

write_flat_model edt/patterns_edt_flat_model.fit -rep 

write_patterns patterns_edt/serial_patterns.v -verilog -serial -rep

write_patterns patterns_edt/parallel_patterns.v -verilog -parallel -rep

write_patterns patterns_edt/pattern_edt.ascii -ascii -parallel -rep 



