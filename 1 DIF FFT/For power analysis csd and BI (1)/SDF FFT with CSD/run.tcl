# ==========================================
# FFT8 RADIX2 SDF STREAM - 45nm Synthesis
# Cadence Genus Flow (with Power Analysis)
# NOTE: tb_fft8_radix2_sdf_stream_top is
#       EXCLUDED (testbench, not synthesizable)
# ==========================================

# ------------------------------------------
# 0. Setup
# ------------------------------------------
set_db init_lib_search_path { . }
set_db init_hdl_search_path { . }

# Load 45nm library (update path to your actual lib)
# set_db library { slow_tt_1v0_25c.lib }

# ------------------------------------------
# 1. Read RTL (NO TESTBENCH)
# ------------------------------------------
read_hdl -language v { \
    fft8_radix2_sdf_stream_top.v \
    stage1_radix2_sdf.v \
    stage2_radix2_sdf_stream.v \
    stage3_radix2_sdf_stream.v \
    csd_sqrt2_inv.v \
}

# ------------------------------------------
# 2. Elaborate Top Module
# ------------------------------------------
elaborate fft8_radix2_sdf_stream_top

# Check design
check_design -unresolved

# ------------------------------------------
# 3. Read Constraints
# ------------------------------------------
read_sdc constraints_fft8_sdf_stream.sdc

# ------------------------------------------
# 4. Synthesis Flow
# ------------------------------------------
syn_generic
syn_map
syn_opt

# ------------------------------------------
# 5. Power Analysis Setup (Genus-specific)
# ------------------------------------------

# Set power analysis to use vectorless estimation
set_db power_method static

# Set activity on clock
set_switching_activity -toggle_rate 2.0 -static_probability 0.5 [get_ports clk]

# Propagate activity through design
report_clock_gating

# ------------------------------------------
# 6. Reports
# ------------------------------------------
report_area    > area_fft8_sdf_45nm.rpt
report_timing  > timing_fft8_sdf_45nm.rpt
report_power   > power_fft8_sdf_45nm.rpt

# Per-module power breakdown
report_power -hier > power_fft8_sdf_45nm_hier.rpt

# Per-instance power for each submodule
foreach mod { \
    fft8_radix2_sdf_stream_top \
    stage1_radix2_sdf \
    stage2_radix2_sdf_stream \
    stage3_radix2_sdf_stream \
    csd_sqrt2_inv \
} {
    report_power -instance [get_cells -hierarchical $mod] \
        >> power_fft8_sdf_45nm_hier.rpt
}

# QoR summary
report_qor > qor_fft8_sdf_45nm.rpt

# ------------------------------------------
# 7. Save Netlist & SDC
# ------------------------------------------
write_hdl  > fft8_sdf_stream_45nm_netlist.v
write_sdc  > fft8_sdf_stream_45nm_synth.sdc

# Save Genus database (checkpoint)
write_db   fft8_sdf_stream_45nm.db