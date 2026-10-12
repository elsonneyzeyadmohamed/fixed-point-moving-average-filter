# Run with Synopsys Design Compiler from the repository root:
#   dc_shell -f synthesis/refreshed/syn.tcl
# Put the licensed TSMC standard-cell .db files in the repository-root std_cells/ directory.
# These library files are intentionally not distributed with this repository.
set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ../..]]
cd $script_dir

set top_module non_recursive_filter
define_design_lib work -path ./work

lappend search_path [file join $repo_root rtl]
lappend search_path [file join $repo_root std_cells]

set SSLIB "scmetro_tsmc_cl013g_rvt_ss_1p08v_125c.db"
set TTLIB "scmetro_tsmc_cl013g_rvt_tt_1p2v_25c.db"
set FFLIB "scmetro_tsmc_cl013g_rvt_ff_1p32v_m40c.db"
set target_library [list $SSLIB $TTLIB $FFLIB]
set link_library [list * $SSLIB $TTLIB $FFLIB]

read_file -format verilog non_recursive_filter.v
current_design $top_module
link
check_design

create_clock -name clk -period 10.0 [get_ports clk]
set_clock_latency 0.5 [get_clocks clk]
set_clock_uncertainty -setup 0.2 [get_clocks clk]
set_clock_uncertainty -hold 0.05 [get_clocks clk]
set_clock_transition 0.1 [get_clocks clk]
set_dont_touch_network [get_ports rst]
set_false_path -from [get_ports rst]

set data_inputs [remove_from_collection [all_inputs] [get_ports {clk rst}]]
set_input_delay 2.0 -clock clk $data_inputs
set_output_delay 2.0 -clock clk [all_outputs]
set_driving_cell -lib_cell BUFX2M $data_inputs
set_load 0.5 [all_outputs]

set_operating_conditions -max scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
                         -max_library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
                         -min scmetro_tsmc_cl013g_rvt_ff_1p32v_m40c \
                         -min_library scmetro_tsmc_cl013g_rvt_ff_1p32v_m40c
set_wire_load_mode enclosed
set_clock_gating_style -sequential_cell latch -minimum_bitwidth 4

compile -map_effort high -gate_clock
write_sdc -nosplit non_recursive_filter_cg.sdc
write -format verilog -hierarchy -output non_recursive_filter_cg_mapped.v
write -format ddc -hierarchy -output non_recursive_filter_cg.ddc

report_area > non_recursive_cg_area.rpt
report_power > non_recursive_cg_power.rpt
report_constraint -all_violators > non_recursive_cg_constraints.rpt
report_timing -max_paths 10 > non_recursive_cg_timing.rpt
report_qor > non_recursive_cg_qor.rpt
report_clock_gating > non_recursive_cg_clock_gating.rpt
