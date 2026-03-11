# Cadence Genus(TM) Synthesis Solution, Version 21.14-s082_1, built Jun 23 2022 14:32:08

# Date: Wed Mar 11 16:03:49 2026
# Host: vlsi25 (x86_64 w/Linux 4.18.0-425.3.1.el8.x86_64) (20cores*28cpus*1physical cpu*Intel(R) Core(TM) i7-14700 33792KB)
# OS:   Red Hat Enterprise Linux release 8.7 (Ootpa)

set_db init_lib_search_path {/home/install/FOUNDRY/digital/45nm/LIBS/lib/max}
set_db library {slow.lib}
get_db init_lib_search_path
get_db library
read_hdl { \
stage1_sdf_csd_andbypass.V \
stage2_sdf_csd_andbypass.v \
stage3_sdf_csd_andbypass.v \
fft8_sdf_csd_andbypass_top.v \
}
elaborate fft8_sdf_csd_andbypass_top
read_sdc constraints_top.sdc
syn_generic
syn_map
syn_opt
report_area
report_power > power_45nm.rpt
