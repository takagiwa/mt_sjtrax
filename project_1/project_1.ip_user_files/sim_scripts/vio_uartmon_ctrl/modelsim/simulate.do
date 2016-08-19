onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L secureip -L xil_defaultlib -lib xil_defaultlib xil_defaultlib.vio_uartmon_ctrl

do {wave.do}

view wave
view structure
view signals

do {vio_uartmon_ctrl.udo}

run -all

quit -force
