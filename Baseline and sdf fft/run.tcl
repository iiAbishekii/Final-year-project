# =====================================================
# 45nm Genus Synthesis + Power Script
# Design: fft8_dif_sdf
# =====================================================

# -----------------------------------------------------
# 1. 45nm Library Setup
# -----------------------------------------------------

set_db init_lib_search_path {/home/install/FOUNDRY/digital/45nm/LIBS/lib/max}
set_db library {slow.lib}

# -----------------------------------------------------
# 2. Read RTL (DUT only, NOT testbench)
# -----------------------------------------------------

read_hdl { fft8_dif_sdf.v }

# -----------------------------------------------------
# 3. Elaborate Top Module
# -----------------------------------------------------

elaborate fft8_dif_sdf

# -----------------------------------------------------
# 4. Read Timing Constraints
# -----------------------------------------------------

read_sdc constraints_top.sdc

# -----------------------------------------------------
# 5. Synthesis Flow
# -----------------------------------------------------

syn_generic
syn_map
syn_opt

# -----------------------------------------------------
# 6. Reports
# -----------------------------------------------------

report_area   > area_45nm.rpt
report_timing > timing_45nm.rpt
report_power  > power_45nm.rpt

# -----------------------------------------------------
# 7. Save Netlist
# -----------------------------------------------------

write_hdl > fft8_dif_sdf_45nm_netlist.v
write_sdc > fft8_dif_sdf_45nm_sdc.sdc

gui_show
