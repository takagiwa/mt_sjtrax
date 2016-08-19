onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib vio_uartmon_ctrl_opt

do {wave.do}

view wave
view structure
view signals

do {vio_uartmon_ctrl.udo}

run -all

quit -force
