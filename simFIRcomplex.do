setenv LMC_TIMEUNIT -9
vlib work
vcom -work work CoArray_pkg.vhd
vcom -work work fifo.vhd
vcom -work work FIR_decimation_complex.vhd
vcom -work work FIR_complex_top.vhd
vcom -work work FIR_complex_tb.vhd

vsim +notimingchecks -L work work.FIR_complex_tb -wlf FIR_complex_decimation_sim.wlf

add wave -noupdate -group TB -radix hexadecimal /FIR_complex_tb/*
add wave -noupdate -group  FIR_COMPLEX_UNIT -radix hexadecimal /FIR_complex_tb/FIR_complex_top_inst/FIR_complex_unit/*
add wave -noupdate -group  INPUT_IM -radix hexadecimal /FIR_complex_tb/FIR_complex_top_inst/input_im_fifo/*
add wave -noupdate -group  INPUT_REAL -radix hexadecimal /FIR_complex_tb/FIR_complex_top_inst/input_real_fifo/*
add wave -noupdate -group  OUTPUT_IM -radix hexadecimal /FIR_complex_tb/FIR_complex_top_inst/output_im_fifo/*
add wave -noupdate -group  OUTPUT_REAL -radix hexadecimal /FIR_complex_tb/FIR_complex_top_inst/output_real_fifo/*

run 5000ns
