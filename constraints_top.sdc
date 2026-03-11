# ==========================================
# FFT8 SDF + CSD + SPST Han-Carlson Adder
# Cadence Genus Compatible SDC — 45nm
# ==========================================

# ------------------------------------------
# Clock — 100 MHz (10 ns period)
# Tight enough to force synthesis to optimize
# the CSD shift-adder chain in stage3 and
# the SPST Han-Carlson prefix tree in all stages.
# ------------------------------------------
create_clock -name clk -period 10 [get_ports clk]

set_clock_uncertainty  0.1 [get_clocks clk]
set_clock_latency      0.2 [get_clocks clk]
set_clock_transition   0.5 [get_clocks clk]

# ------------------------------------------
# Input / Output delays
# ------------------------------------------
set INPUT_DELAY  1.0
set OUTPUT_DELAY 1.0
set MIN_DELAY    0.2

set all_inputs_no_clk [remove_from_collection [all_inputs] [get_ports clk]]
set all_outputs_ports  [all_outputs]

set_input_delay  -clock clk -max $INPUT_DELAY  $all_inputs_no_clk
set_input_delay  -clock clk -min $MIN_DELAY    $all_inputs_no_clk
set_output_delay -clock clk -max $OUTPUT_DELAY $all_outputs_ports
set_output_delay -clock clk -min $MIN_DELAY    $all_outputs_ports

# ------------------------------------------
# Output load and max transition
# ------------------------------------------
set_load           0.1 $all_outputs_ports
set_max_transition 0.5 [current_design]
