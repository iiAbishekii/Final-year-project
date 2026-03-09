# ==========================================
# FFT8 SDF + CSD (Optimized, No Bit-Inv)
# Cadence Genus Synthesis Flow — 45nm
# ==========================================
#
# Run from terminal:
#   rm -rf genus.* .genus INCA_libs
#   genus -no_gui
#   source run_sdf_csd.tcl
#
# Output files produced:
#   area_sdf_csd.rpt
#   timing_sdf_csd.rpt
#   power_sdf_csd.rpt
#   fft8_sdf_csd_netlist.v
#   fft8_sdf_csd_synth.sdc
# ==========================================

# ------------------------------------------
# STEP 1 — Set 45nm library
# ------------------------------------------
set_db init_lib_search_path { /home/install/FOUNDRY/digital/45nm/LIBS/lib/max }
set_db library { slow.lib }

puts "Library path : [get_db init_lib_search_path]"
puts "Library file : [get_db library]"

# ------------------------------------------
# STEP 2 — Read RTL (NO testbench, NO bit-inv files)
# stage3_sdf_csd has CSD inlined — no csd_sqrt2_inv needed
# ------------------------------------------
read_hdl -language v { \
    stage1_sdf_csd.v \
    stage2_sdf_csd.v \
    stage3_sdf_csd.v \
    fft8_sdf_csd_top.v \
}

# ------------------------------------------
# STEP 3 — Elaborate top module
# ------------------------------------------
elaborate fft8_sdf_csd_top
cd fft8_sdf_csd_top

# ------------------------------------------
# STEP 4 — Read timing constraints
# ------------------------------------------
read_sdc constraints_sdf_csd.sdc

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
report_area   > area_sdf_csd.rpt
report_timing > timing_sdf_csd.rpt
report_power  > power_sdf_csd.rpt

puts ""
puts "========================================"
puts "  SYNTHESIS COMPLETE"
puts "  Check power_sdf_csd.rpt"
puts "  Target: ~1.15 mW (vs 2.558 mW prev)"
puts "========================================"

# ------------------------------------------
# STEP 7 — Save netlist and constraints
# ------------------------------------------
write_hdl > fft8_sdf_csd_netlist.v
write_sdc > fft8_sdf_csd_synth.sdc
