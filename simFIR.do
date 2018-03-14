setenv LMC_TIMEUNIT -9
vlib work
vcom -work work fifo.vhd
vcom -work work FIR_tb2.vhd
vcom -work work FIR_top.vhd
vcom -work work FIR_decimation.vhd
vcom -work work FIR_decimation_complex.vhd

#vsim +notimingchecks -L work work.FIR_tb2 -wlf FIR_decimation_sim.wlf

add wave -noupdate -group TB -radix hexadecimal /FIR_tb2/*
add wave -noupdate -group  FIR_UNIT -radix hexadecimal /FIR_tb2/FIR_top_inst/FIR_unit/*
add wave -noupdate -group  INPUT_FIFO -radix hexadecimal /FIR_tb2/FIR_top_inst/input_fifo/*
add wave -noupdate -group  OUTPUT_FIFO -radix hexadecimal /FIR_tb2/FIR_top_inst/output_fifo/*

#run 1000ns
