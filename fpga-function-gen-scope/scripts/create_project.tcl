# Makes a normal Vivado project that you can open in the Vivado window.
# In Vivado: Tools > Run Tcl Script... and pick this file,
# or from a terminal in the project folder:  vivado -mode batch -source scripts/create_project.tcl
# The project is made in build/vivado_project/zed_scope.xpr

set root [file normalize [file dirname [info script]]/..]
create_project zed_scope $root/build/vivado_project -part xc7z020clg484-1 -force

add_files -norecurse [glob $root/rtl/*.v]
add_files -fileset constrs_1 -norecurse $root/constraints/zedboard.xdc
set_property top top [current_fileset]

add_files -fileset sim_1 -norecurse [glob $root/sim/*.v]
set_property top tb_top [get_filesets sim_1]
# Run until the testbench calls $finish (the full test needs about 52 ms of sim time).
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Project ready: $root/build/vivado_project/zed_scope.xpr"
