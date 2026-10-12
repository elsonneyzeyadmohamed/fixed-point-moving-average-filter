# Create and map work library
vlib work
vmap work work

# Compile all Verilog files
# Assumes refreshed_filter.v, non_recursive_filter.v, and tb_moving_average.v are in the same directory
vlog -work work refreshed_filter.v
vlog -work work non_recursive_filter.v
vlog -work work tb_moving_average.v

# Simulate the top-level testbench
# +acc ensures visibility of all signals for the waveform
vsim -voptargs=+acc work.tb_moving_average

# Load waveform configurations
do wave.do

# Run the simulation until $stop is reached in the TB
run -all