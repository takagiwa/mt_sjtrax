vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vcom -work xil_defaultlib -64 \
"../../../../project_1.srcs/sources_1/ip/vio_botctrl/sim/vio_botctrl.vhd" \

