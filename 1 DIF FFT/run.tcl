# ==========================================
# FFT8 RADIX2 TOP - 45nm Synthesis
# ==========================================

# Clear previous design (important if same session)
reset_design

# ------------------------------------------
# 1. Read RTL (NO TESTBENCH)
# ------------------------------------------

read_hdl { \
    fft8_radix2_top.v \
    stage1_radix2.v \
    stage2_radix2_block_sdf.v \
    stage3_radix2_block_sdf.v \
}

# ------------------------------------------
# 2. Elaborate Top
# ------------------------------------------

elaborate fft8_radix2_top

# ------------------------------------------
# 3. Read Constraints
# ------------------------------------------

read_sdc constraints_fft8_top.sdc

# ------------------------------------------
# 4. Synthesis Flow
# ------------------------------------------

syn_generic
syn_map
syn_opt

# ------------------------------------------
# 5. Reports
# ------------------------------------------

report_area   > area_fft8_45nm.rpt
report_timing > timing_fft8_45nm.rpt
report_power  > power_fft8_45nm.rpt

# ------------------------------------------
# 6. Save Netlist
# ------------------------------------------

write_hdl > fft8_top_45nm_netlist.v
write_sdc > fft8_top_45nm_synth.sdc