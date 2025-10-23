
---

## ⚙️ `create_project.tcl`

```tcl
set proj_name "riscv_led_shell"
set proj_dir [file normalize "./vivado_project"]

create_project $proj_name $proj_dir -part xc7z020clg400-1
set_property board_part digilentinc.com:arty-z7-20:part0:1.1 [current_project]
add_files [glob ./src/*.v]
add_files -fileset constrs_1 [glob ./constrs/*.xdc]
set_property file_type {Memory Initialization Files} [get_files ./src/rom_init.mem]
set_property top top [current_fileset]

launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "✅ Build complete — bitstream in $proj_dir/$proj_name.runs/impl_1/top.bit"
