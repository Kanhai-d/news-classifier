## ZedBoard pin file for the function generator and oscilloscope.
## Pins and IO standards match the official Digilent Zedboard-Master.xdc.
## Banks 34 and 35 (button and switches) use LVCMOS18, which needs the VADJ
## jumper J18 on its default 1.8 V setting. If J18 is set to 2.5 V or 3.3 V,
## change those lines to LVCMOS25 or LVCMOS33.

## 100 MHz clock
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Switches SW0 to SW7
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS18} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS18} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS18} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS18} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS18} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS18} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS18} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS18} [get_ports {sw[7]}]

## Center push button (reset)
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS18} [get_ports btnc]

## LEDs LD0 to LD7
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN U21 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN V22 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led[7]}]

## VGA, 4 bits per colour
set_property -dict {PACKAGE_PIN V20  IOSTANDARD LVCMOS33} [get_ports {vga_r[0]}]
set_property -dict {PACKAGE_PIN U20  IOSTANDARD LVCMOS33} [get_ports {vga_r[1]}]
set_property -dict {PACKAGE_PIN V19  IOSTANDARD LVCMOS33} [get_ports {vga_r[2]}]
set_property -dict {PACKAGE_PIN V18  IOSTANDARD LVCMOS33} [get_ports {vga_r[3]}]
set_property -dict {PACKAGE_PIN AB22 IOSTANDARD LVCMOS33} [get_ports {vga_g[0]}]
set_property -dict {PACKAGE_PIN AA22 IOSTANDARD LVCMOS33} [get_ports {vga_g[1]}]
set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS33} [get_ports {vga_g[2]}]
set_property -dict {PACKAGE_PIN AA21 IOSTANDARD LVCMOS33} [get_ports {vga_g[3]}]
set_property -dict {PACKAGE_PIN Y21  IOSTANDARD LVCMOS33} [get_ports {vga_b[0]}]
set_property -dict {PACKAGE_PIN Y20  IOSTANDARD LVCMOS33} [get_ports {vga_b[1]}]
set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS33} [get_ports {vga_b[2]}]
set_property -dict {PACKAGE_PIN AB19 IOSTANDARD LVCMOS33} [get_ports {vga_b[3]}]
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVCMOS33} [get_ports vga_hs]
set_property -dict {PACKAGE_PIN Y19  IOSTANDARD LVCMOS33} [get_ports vga_vs]


## Pmod DA2 on JA (top row, pins 1 to 4). Bank 13 is fixed at 3.3 V.
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports da2_sync]
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports da2_dina]
set_property -dict {PACKAGE_PIN Y10  IOSTANDARD LVCMOS33} [get_ports da2_dinb]
set_property -dict {PACKAGE_PIN AA9  IOSTANDARD LVCMOS33} [get_ports da2_sclk]

## Pmod AD1 on JB (top row, pins 1, 2 and 4). Pin 3 (D1, second channel) is not used.
set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33} [get_ports ad1_cs]
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports ad1_d0]
set_property -dict {PACKAGE_PIN W8   IOSTANDARD LVCMOS33} [get_ports ad1_sclk]
