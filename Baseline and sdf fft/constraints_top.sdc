# ==========================================
# Timing Constraints for fft8_dif_sdf
# ==========================================

# Clock settings
set CLK_PERIOD 10
set CLK_NAME clk

# Create clock (10ns = 100MHz)
create_clock -name $CLK_NAME -period $CLK_PERIOD [get_ports clk]

# Clock properties
set_clock_uncertainty 0.1 [get_clocks $CLK_NAME]
set_clock_latency 0.2 [get_clocks $CLK_NAME]
set_clock_transition 0.2 [get_clocks $CLK_NAME]

# Input/Output delays
set INPUT_DELAY 1.0
set OUTPUT_DELAY 1.0
set MIN_DELAY 0.2

# All inputs except clock
set all_inputs_no_clk [remove_from_collection [all_inputs] [get_ports clk]]
set all_outputs_ports [all_outputs]

# Input delays
set_input_delay  -clock $CLK_NAME -max $INPUT_DELAY $all_inputs_no_clk
set_input_delay  -clock $CLK_NAME -min $MIN_DELAY   $all_inputs_no_clk

# Output delays
set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY $all_outputs_ports
set_output_delay -clock $CLK_NAME -min $MIN_DELAY    $all_outputs_ports

# Output load
set_load 0.1 $all_outputs_ports

# Max transition
set_max_transition 0.5 [current_design]
