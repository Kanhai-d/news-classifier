# Builds the bitstream with Vivado in batch mode.
# Run from the project folder:  vivado -mode batch -source scripts/build.tcl
set part xc7z020clg484-1
set out  build/vivado
file mkdir $out

read_verilog [glob rtl/*.v]
read_xdc constraints/zedboard.xdc

synth_design -top top -part $part
opt_design
place_design
route_design

report_utilization    -file $out/utilization.rpt
report_timing_summary -file $out/timing.rpt
write_bitstream -force $out/top.bit
puts "Done. Bitstream: $out/top.bit"
