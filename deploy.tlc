set proj_name "riscv_led_shell"
set proj_dir [file normalize "./vivado_project"]

if {[file exists $proj_dir]} { file delete -force $proj_dir }

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

set bitfile [get_property BITSTREAM.FILE [get_runs impl_1]]
open_hw
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
refresh_hw_device $dev
set_property PROGRAM.FILE $bitfile $dev
program_hw_devices $dev
after 1000
refresh_hw_device $dev
puts "\n✅ FPGA programmed! UART 115200 or XSDB console ready.\n"
close_hw_target
disconnect_hw_server
exit
