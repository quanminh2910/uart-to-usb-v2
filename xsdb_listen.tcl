connect
open_hw
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
refresh_hw_device $dev
set bitfile ./vivado_project/riscv_led_shell.runs/impl_1/top.bit
program_hw_devices $dev
puts "✅ FPGA programmed. Listening for JTAG UART..."
after 500
set h [jtag open 1]
while {1} {
    set d [jtag read $h 256]
    if {[string length $d]} {puts -nonewline $d; flush stdout}
    after 50
}
