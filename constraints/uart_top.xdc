## 12 MHz clock
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports CLK12MHZ]
create_clock -period 83.333 -name sys_clk_pin -waveform {0.000 41.667} -add [get_ports CLK12MHZ]

## USB-UART
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports uart_rxd_out]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports uart_txd_in]

## LEDs
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## Pmod JA: logic analyzer probe points
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports {ja[0]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {ja[1]}]

## Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]