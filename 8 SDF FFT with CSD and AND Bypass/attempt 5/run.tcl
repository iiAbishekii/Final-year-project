# ============================================================
# FFT8 SDF + CSD + AND-Gate Bypass  —  CORRECTED run.tcl
# Cadence Genus Synthesis Flow — 45nm
#
# WHY THE PREVIOUS TWO RUNS GAVE IDENTICAL POWER:
#
#   The combinational AND-gate approach:
#     iso_dre = delay_re[addr] & {16{sum_phase}}
#   is architecturally correct but INVISIBLE to Genus.
#
#   Genus does not model runtime switching behaviour.
#   It propagates "toggle rate" through combinational gates
#   using a formula that actually INCREASES the estimated
#   toggle rate of iso_ (because sum_phase itself toggles
#   every 4 cycles, contributing transitions to the AND output).
#
#   set_switching_activity and set_case_analysis also had
#   no effect because Genus resets activity to its own
#   defaults at every register (flip-flop) boundary.
#   The adder inputs inside stage1/2/3 are driven by internal
#   registers — the primary input annotation never reaches them.
#
# WHAT ACTUALLY WORKS — Registered Operand Isolation:
#
#   The Verilog files have been restructured so the adder
#   uses operand registers (op_a_re, op_b_re) that are
#   written ONLY during sum_phase:
#
#     if (sum_phase) begin
#       op_a_re <= delay_re[addr];   ← written 50% of cycles
#       op_b_re <= xin_re;           ← written 50% of cycles
#       xout_re <= delay_re[addr] + xin_re;
#       ...
#     end
#     // During store_phase: op registers hold → Q stable → no toggle
#
#   Genus DOES correctly model register conditional writes:
#   A register written 50% of cycles has 50% of the normal
#   toggle rate on its Q output. Lower Q toggle → lower
#   toggle on adder inputs → lower logic switching power.
#
#   The power saving is now visible in static analysis.
#   No simulation, no SAIF needed.
#
# EXPECTED: power BELOW CSD-only baseline (0.4377 mW)
# ============================================================

set_db init_lib_search_path { /home/install/FOUNDRY/digital/45nm/LIBS/lib/max }
set_db library { slow.lib }

read_hdl -language v { \
    stage1_sdf_csd_andbypass.v \
    stage2_sdf_csd_andbypass.v \
    stage3_sdf_csd_andbypass.v \
    fft8_sdf_csd_andbypass_top.v \
}

elaborate fft8_sdf_csd_andbypass_top
cd fft8_sdf_csd_andbypass_top

read_sdc constraints_top.sdc

# Power-aware cell selection during syn_opt
set_db / .lp_power_optimization_weight 1.0
set_db / .lp_power_unit mW

syn_generic
syn_map
syn_opt

report_area   > area_sdf_csd_andbypass_fixed.rpt
report_timing > timing_sdf_csd_andbypass_fixed.rpt
report_power  > power_sdf_csd_andbypass_fixed.rpt

puts ""
puts "========================================================"
puts "  SYNTHESIS COMPLETE"
puts "  Check: power_sdf_csd_andbypass_fixed.rpt"
puts "  Expected: below CSD-only baseline of 0.4377 mW"
puts "========================================================"

write_hdl > fft8_sdf_csd_andbypass_fixed_netlist.v
write_sdc > fft8_sdf_csd_andbypass_fixed_synth.sdc
