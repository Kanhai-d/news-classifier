# Loads the bitstream into the ZedBoard over JTAG.
# Run from the project folder:  vivado -mode batch -source scripts/program.tcl
open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices xc7z020*] 0]
current_hw_device $dev
set_property PROGRAM.FILE build/vivado/top.bit $dev
program_hw_devices $dev
puts "ZedBoard programmed."
