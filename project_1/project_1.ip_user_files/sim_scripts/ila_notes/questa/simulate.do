onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib ila_notes_opt

do {wave.do}

view wave
view structure
view signals

do {ila_notes.udo}

run -all

quit -force
