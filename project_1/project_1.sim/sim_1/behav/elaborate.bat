@echo off
set xv_path=C:\\Xilinx\\Vivado\\2015.4\\bin
call %xv_path%/xelab  -wto ba9a2f5613954139a6250146efaba237 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L fifo_generator_v13_0_1 -L blk_mem_gen_v8_3_1 -L secureip --snapshot sim_bot2_behav xil_defaultlib.sim_bot2 -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
