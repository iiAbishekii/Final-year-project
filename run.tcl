# ==========================================
# FFT8 RADIX2 SDF STREAM - 45nm Synthesis
# ==========================================

# Reset previous design (important in same session)
reset_design

# ------------------------------------------
# 1. Read RTL (NO TESTBENCH)
# ------------------------------------------
read_hdl { \
    fft8_radix2_sdf_stream_top.v \
    stage1_radix2_sdf.v \
    stage2_radix2_sdf_stream.v \
    stage3_radix2_sdf_stream.v \
}

# ------------------------------------------
# 2. Elaborate Top Module
# ------------------------------------------
elaborate fft8_radix2_sdf_stream_top

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
# 5. Reports
# ------------------------------------------
report_area   > area_fft8_sdf_45nm.rpt
report_timing > timing_fft8_sdf_45nm.rpt
report_power  > power_fft8_sdf_45nm.rpt

# ------------------------------------------
# 6. Save Netlist
# ------------------------------------------
write_hdl > fft8_sdf_stream_45nm_netlist.v
write_sdc > fft8_sdf_stream_45nm_synth.sdc