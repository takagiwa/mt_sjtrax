# 
# Synthesis run script generated by Vivado
# 

set_param xicom.use_bs_reader 1
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
read_ip c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes.xci
set_property is_locked true [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes.xci]

synth_design -top ila_notes -part xc7vx485tffg1761-2 -mode out_of_context
rename_ref -prefix_all ila_notes_
write_checkpoint -noxdef ila_notes.dcp
catch { report_utilization -file ila_notes_utilization_synth.rpt -pb ila_notes_utilization_synth.pb }
if { [catch {
  file copy -force C:/Projects/sjtrax/project_1/project_1.runs/ila_notes_synth_1/ila_notes.dcp c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes.dcp
} _RESULT ] } { 
  send_msg_id runtcl-3 error "ERROR: Unable to successfully create or copy the sub-design checkpoint file."
  error "ERROR: Unable to successfully create or copy the sub-design checkpoint file."
}
if { [catch {
  write_verilog -force -mode synth_stub c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_stub.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a Verilog synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode synth_stub c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_stub.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a VHDL synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_verilog -force -mode funcsim c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_sim_netlist.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the Verilog functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode funcsim c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_sim_netlist.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the VHDL functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}

if {[file isdir C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_notes]} {
  catch { 
    file copy -force c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_stub.v C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_notes
  }
}

if {[file isdir C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_notes]} {
  catch { 
    file copy -force c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_stub.vhdl C:/Projects/sjtrax/project_1/project_1.ip_user_files/ip/ila_notes
  }
}
