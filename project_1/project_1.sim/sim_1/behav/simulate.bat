@echo off
set xv_path=C:\\Xilinx\\Vivado\\2015.4\\bin
call %xv_path%/xsim sim_bot2_behav -key {Behavioral:sim_1:Functional:sim_bot2} -tclbatch sim_bot2.tcl -view C:/Projects/sjtrax/project_1/sim_lookup_behav.wcfg -view C:/Projects/sjtrax/project_1/sim_getaroundcolors_behav.wcfg -view C:/Projects/sjtrax/project_1/sim_scan_forced_behav.wcfg -view C:/Projects/sjtrax/project_1/sim_getaroundcolors_behav1.wcfg -view C:/Projects/sjtrax/project_1/sim_scan_forced_behav1.wcfg -view C:/Projects/sjtrax/project_1/sim_bot2_behav.wcfg -view C:/Projects/sjtrax/project_1/sim_map_mem_w_behav.wcfg -view C:/Projects/sjtrax/project_1/sim_rnd_note_gen_behav.wcfg -view C:/Projects/sjtrax/project_1/sim_make_mask_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
