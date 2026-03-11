# ==========================================
# FFT8 SDF + CSD + Registered Operand Isolation
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
#   clockgating_sdf_csd_andbypass.rpt
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
# STEP 2 — Power-oriented synthesis settings
# Set BEFORE read_hdl so Genus applies them
# during elaboration and technology mapping.
#
# lp_insert_clock_gating:
#   Inserts ICG cells on all enable-qualified
#   flip-flop banks. The op_a registers in
#   each stage are written only in store_phase
#   (50% duty), so Genus will gate their clock
#   → adder inputs stable during sum_phase
#   → logic switching power reduced.
#
# lp_power_analysis_effort high:
#   Activates switching-activity-aware
#   optimisation during syn_opt. Without this,
#   syn_opt targets timing only and may undo
#   power savings from ICG insertion.
#
# lp_insert_operand_isolation:
#   Additional isolation cells on combinational
#   paths whose enable is derivable from the
#   design's control signals. Complements the
#   manual registered-operand approach.
# ------------------------------------------
set_db lp_insert_clock_gating      true
set_db lp_clock_gating_prefix      "CG_"
set_db lp_power_analysis_effort    high
set_db lp_insert_operand_isolation true
set_db lp_operand_isolation_prefix "OI_"

# ------------------------------------------
# STEP 3 — Read RTL (NO testbench)
# ------------------------------------------
read_hdl -language v { \
    stage1_sdf_csd_andbypass.v \
    stage2_sdf_csd_andbypass.v \
    stage3_sdf_csd_andbypass.v \
    fft8_sdf_csd_andbypass_top.v \
}

# ------------------------------------------
# STEP 4 — Elaborate top module
# ------------------------------------------
elaborate fft8_sdf_csd_andbypass_top
cd fft8_sdf_csd_andbypass_top

# ------------------------------------------
# STEP 5 — Read timing constraints
# ------------------------------------------
read_sdc constraints_top.sdc

# ------------------------------------------
# STEP 6 — Synthesis passes
# syn_opt -effort high -power:
#   -effort high  : exhaustive optimisation
#   -power        : power as explicit secondary
#                   metric after timing closure
# ------------------------------------------
syn_generic
syn_map
syn_opt -effort high -power

# ------------------------------------------
# STEP 7 — Reports
# ------------------------------------------
report_area          > area_sdf_csd_andbypass.rpt
report_timing        > timing_sdf_csd_andbypass.rpt
report_power         > power_sdf_csd_andbypass.rpt
report_clock_gating  > clockgating_sdf_csd_andbypass.rpt

puts ""
puts "========================================"
puts "  SYNTHESIS COMPLETE"
puts "  Check power_sdf_csd_andbypass.rpt"
puts "  Check clockgating_sdf_csd_andbypass.rpt"
puts "  Target: below CSD baseline 4.37703e-04 W"
puts "========================================"

# ------------------------------------------
# STEP 8 — Save netlist and constraints
# ------------------------------------------
write_hdl > fft8_sdf_csd_andbypass_netlist.v
write_sdc > fft8_sdf_csd_andbypass_synth.sdc
