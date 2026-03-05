# ==========================================
# FFT8 RADIX2 SDF STREAM - 45nm Synthesis + Power
# ==========================================

# ------------------------------------------------
# 1. Reset previous design (important)
# ------------------------------------------------
reset_design -all

# ------------------------------------------------
# 2. Set 45nm library
# ------------------------------------------------
set_db init_lib_search_path {/home/install/FOUNDRY/digital/45nm/LIBS/lib/max}
set_db library {slow.lib}

# ------------------------------------------------
# 3. Read RTL files
# ------------------------------------------------
read_hdl { \
    fft8_radix2_sdf_stream_top.v \
    stage1_radix2_sdf.v \
    stage2_radix2_sdf_stream.v \
    stage3_radix2_sdf_stream.v \
    vedic_16x16_signed.v \
    vedic_16x16_unsigned.v \
    vedic_8x8.v \
    vedic_4x4.v \
    vedic_2x2.v \
}

# ------------------------------------------------
# 4. Elaborate top module
# ------------------------------------------------
elaborate fft8_radix2_sdf_stream_top

# Set active design
current_design fft8_radix2_sdf_stream_top

# ------------------------------------------------
# 5. Apply timing constraints
# ------------------------------------------------
read_sdc constraints_fft8_sdf_stream.sdc

# ------------------------------------------------
# 6. Run synthesis
# ------------------------------------------------
syn_generic
syn_map
syn_opt

# ------------------------------------------------
# 7. Generate reports
# ------------------------------------------------
report_area   > area_fft8_45nm.rpt
report_timing > timing_fft8_45nm.rpt
report_power  > power_fft8_45nm.rpt

# ------------------------------------------------
# 8. Save synthesized netlist
# ------------------------------------------------
write_hdl > fft8_sdf_stream_45nm_netlist.v
write_sdc > fft8_sdf_stream_45nm_constraints.sdc
