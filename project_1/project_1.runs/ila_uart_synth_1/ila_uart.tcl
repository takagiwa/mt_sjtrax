# 
# Synthesis run script generated by Vivado
# 

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7vx485tffg1761-2

set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir C:/Projects/sjtrax/project_1/project_1.cache/wt [current_project]
set_property parent.project_path C:/Projects/sjtrax/project_1/project_1.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
set_property board_part xilinx.com:vc707:part0:1.1 [current_project]
set_property vhdl_version vhdl_2k [current_fileset]
read_ip C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart.xci
set_property is_locked true [get_files C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart.xci]

synth_design -top ila_uart -part xc7vx485tffg1761-2 -mode out_of_context
rename_ref -prefix_all ila_uart_
write_checkpoint -noxdef ila_uart.dcp
catch { report_utilization -file ila_uart_utilization_synth.rpt -pb ila_uart_utilization_synth.pb }
if { [catch {
  file copy -force C:/Projects/sjtrax/project_1/project_1.runs/ila_uart_synth_1/ila_uart.dcp C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart.dcp
} _RESULT ] } { 
  send_msg_id runtcl-3 error "ERROR: Unable to successfully create or copy the sub-design checkpoint file."
  error "ERROR: Unable to successfully create or copy the sub-design checkpoint file."
}
if { [catch {
  write_verilog -force -mode synth_stub C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_stub.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a Verilog synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode synth_stub C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_stub.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a VHDL synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_verilog -force -mode funcsim C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_sim_netlist.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the Verilog functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode funcsim C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_sim_netlist.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the VHDL functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}

if {[file isdir C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_uart]} {
  catch { 
    file copy -force C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_stub.v C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_uart
  }
}

if {[file isdir C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_uart]} {
  catch { 
    file copy -force C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_stub.vhdl C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_uart
  }
}
