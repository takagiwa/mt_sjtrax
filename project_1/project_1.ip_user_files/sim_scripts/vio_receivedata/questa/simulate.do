onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib vio_receivedata_opt

do {wave.do}

view wave
view structure
view signals

do {vio_receivedata.udo}

run -all

quit -force
