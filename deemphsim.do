
setenv LMC_TIMEUNIT -9
vlib work
vcom -work work CoArray_pkg.vhd
vcom -work work fifo.vhd
vcom -work work deemphtb.vhd
vcom -work work deemph_top.vhd
vcom -work work FIR_deemph.vhd

vsim +notimingchecks -L work work.deemphtb -wlf FIR_deemph_sim.wlf

add wave -noupdate -group TB -radix hexadecimal /deemphtb/*
add wave -noupdate -group  FIR_UNIT -radix hexadecimal /deemphtb/deemph_top_inst/fir_unit/*
add wave -noupdate -group  INPUT_FIFO -radix hexadecimal /deemphtb/deemph_top_inst/input_fifo/*
add wave -noupdate -group  OUTPUT_FIFO -radix hexadecimal /deemphtb/deemph_top_inst/output_fifo/*
run 5000ns