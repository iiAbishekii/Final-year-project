# ==========================================
# FFT8 SDF + CSD + AND-Gate Bypass
# Cadence Genus Synthesis Flow — 45nm
# ==========================================
#
# Run from terminal:
#   rm -rf genus.* .genus INCA_libs
#   genus -no_gui
#   source run.tcl
#
# Output files produced:
#   area_sdf_csd_andbypass.rpt
#   timing_sdf_csd_andbypass.rpt
#   power_sdf_csd_andbypass.rpt
#   fft8_sdf_csd_andbypass_netlist.v
#   fft8_sdf_csd_andbypass_synth.sdc
# ==========================================

# ------------------------------------------
# STEP 1 — Set 45nm library
# ------------------------------------------
set_db init_lib_search_path { /home/install/FOUNDRY/digital/45nm/LIBS/lib/max }
set_db library { slow.lib }

puts "Library path : [get_db init_lib_search_path]"
puts "Library file : [get_db library]"

# ------------------------------------------
# STEP 2 — Read RTL (NO testbench)
# stage1_sdf_csd_andbypass : Delay-4 butterfly, W^0=1
# stage2_sdf_csd_andbypass : Delay-2 butterfly, W^0=1 / W^2=-j
# stage3_sdf_csd_andbypass : Delay-1 butterfly + CSD twiddles
# fft8_sdf_csd_andbypass_top : 8-point Radix-2 SDF DIF FFT top
# ------------------------------------------
read_hdl -language v { \
    stage1_sdf_csd_andbypass.v \
    stage2_sdf_csd_andbypass.v \
    stage3_sdf_csd_andbypass.v \
    fft8_sdf_csd_andbypass_top.v \
}

# ------------------------------------------
# STEP 3 — Elaborate top module
# ------------------------------------------
elaborate fft8_sdf_csd_andbypass_top
cd fft8_sdf_csd_andbypass_top

# ------------------------------------------
# STEP 4 — Read timing constraints
# ------------------------------------------
read_sdc constraints_top.sdc

# ------------------------------------------
# STEP 5 — Synthesis passes
# syn_generic : technology-independent mapping
# syn_map     : maps to 45nm standard cells
# syn_opt     : timing/area/power optimisation
# ------------------------------------------
syn_generic
syn_map
syn_opt

# ------------------------------------------
# STEP 6 — Reports
# ------------------------------------------
report_area   > area_sdf_csd_andbypass.rpt
report_timing > timing_sdf_csd_andbypass.rpt
report_power  > power_sdf_csd_andbypass.rpt

puts ""
puts "========================================"
puts "  SYNTHESIS COMPLETE"
puts "  Check power_sdf_csd_andbypass.rpt"
puts "  Target: lower than SDF+CSD baseline"
puts "========================================"

# ------------------------------------------
# STEP 7 — Save netlist and constraints
# ------------------------------------------
write_hdl > fft8_sdf_csd_andbypass_netlist.v
write_sdc > fft8_sdf_csd_andbypass_synth.sdc
