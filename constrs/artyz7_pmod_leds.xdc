# constrs/artyz7_pmod_leds.xdc
# Fixed XDC — use this as a drop-in (replace project XDC with this file)

# Clock input (100 MHz)
set_property PACKAGE_PIN W5 [get_ports {clk_100mhz}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk_100mhz}]
create_clock -period 10.0 [get_ports {clk_100mhz}]

# Reset button (use board reset port name rst_btn)
set_property PACKAGE_PIN T18 [get_ports {rst_btn}]
set_property IOSTANDARD LVCMOS33 [get_ports {rst_btn}]

# UART pins
set_property PACKAGE_PIN Y11 [get_ports {uart_tx}]
set_property PACKAGE_PIN AA11 [get_ports {uart_rx}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_tx uart_rx}]

# LEDs (explicit mapping — one PACKAGE_PIN per port)
set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]
# I/O standard for all LEDs
set_property IOSTANDARD LVCMOS33 [get_ports {led[0] led[1] led[2] led[3] led[4] led[5] led[6] led[7]}]
