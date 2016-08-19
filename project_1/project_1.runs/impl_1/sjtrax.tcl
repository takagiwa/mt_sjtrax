proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_param xicom.use_bs_reader 1
  create_project -in_memory -part xc7vx485tffg1761-2
  set_property board_part xilinx.com:vc707:part0:1.1 [current_project]
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir C:/Projects/sjtrax/project_1/project_1.cache/wt [current_project]
  set_property parent.project_path C:/Projects/sjtrax/project_1/project_1.xpr [current_project]
  set_property ip_repo_paths c:/Projects/sjtrax/project_1/project_1.cache/ip [current_project]
  set_property ip_output_repo c:/Projects/sjtrax/project_1/project_1.cache/ip [current_project]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/synth_1/sjtrax.dcp
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/ila_uart_synth_1/ila_uart.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/ila_uart_synth_1/ila_uart.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/uart_tx_fifo_synth_1/uart_tx_fifo.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/uart_tx_fifo_synth_1/uart_tx_fifo.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/vio_uart_synth_1/vio_uart.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/vio_uart_synth_1/vio_uart.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/uartmon_fifo_synth_1/uartmon_fifo.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/uartmon_fifo_synth_1/uartmon_fifo.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/vio_uartmon_ctrl_synth_1/vio_uartmon_ctrl.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/vio_uartmon_ctrl_synth_1/vio_uartmon_ctrl.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/ila_uartmon_synth_1/ila_uartmon.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/ila_uartmon_synth_1/ila_uartmon.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/map_mem_synth_1/map_mem.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/map_mem_synth_1/map_mem.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/vio_botctrl_synth_1/vio_botctrl.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/vio_botctrl_synth_1/vio_botctrl.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/vio_receivedata_synth_1/vio_receivedata.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/vio_receivedata_synth_1/vio_receivedata.dcp]
  add_files -quiet C:/Projects/sjtrax/project_1/project_1.runs/ila_notes_synth_1/ila_notes.dcp
  set_property netlist_only true [get_files C:/Projects/sjtrax/project_1/project_1.runs/ila_notes_synth_1/ila_notes.dcp]
  read_xdc -mode out_of_context -ref ila_uart c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_uart_ooc.xdc]
  read_xdc -ref ila_uart c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_v6_0/constraints/ila.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uart/ila_v6_0/constraints/ila.xdc]
  read_xdc -mode out_of_context -ref uart_tx_fifo -cells U0 c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uart_tx_fifo/uart_tx_fifo_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uart_tx_fifo/uart_tx_fifo_ooc.xdc]
  read_xdc -ref uart_tx_fifo -cells U0 c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uart_tx_fifo/uart_tx_fifo/uart_tx_fifo.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uart_tx_fifo/uart_tx_fifo/uart_tx_fifo.xdc]
  read_xdc -mode out_of_context -ref vio_uart c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uart/vio_uart_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uart/vio_uart_ooc.xdc]
  read_xdc -ref vio_uart c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uart/vio_uart.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uart/vio_uart.xdc]
  read_xdc -mode out_of_context -ref uartmon_fifo -cells U0 c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uartmon_fifo/uartmon_fifo_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uartmon_fifo/uartmon_fifo_ooc.xdc]
  read_xdc -ref uartmon_fifo -cells U0 c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uartmon_fifo/uartmon_fifo/uartmon_fifo.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uartmon_fifo/uartmon_fifo/uartmon_fifo.xdc]
  read_xdc -mode out_of_context -ref vio_uartmon_ctrl c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uartmon_ctrl/vio_uartmon_ctrl_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uartmon_ctrl/vio_uartmon_ctrl_ooc.xdc]
  read_xdc -ref vio_uartmon_ctrl c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uartmon_ctrl/vio_uartmon_ctrl.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uartmon_ctrl/vio_uartmon_ctrl.xdc]
  read_xdc -mode out_of_context -ref ila_uartmon c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uartmon/ila_uartmon_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uartmon/ila_uartmon_ooc.xdc]
  read_xdc -ref ila_uartmon c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uartmon/ila_v6_0/constraints/ila.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uartmon/ila_v6_0/constraints/ila.xdc]
  read_xdc -mode out_of_context -ref map_mem -cells U0 c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/map_mem/map_mem_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/map_mem/map_mem_ooc.xdc]
  read_xdc -mode out_of_context -ref vio_botctrl c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_botctrl/vio_botctrl_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_botctrl/vio_botctrl_ooc.xdc]
  read_xdc -ref vio_botctrl c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_botctrl/vio_botctrl.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_botctrl/vio_botctrl.xdc]
  read_xdc -mode out_of_context -ref vio_receivedata c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_receivedata/vio_receivedata_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_receivedata/vio_receivedata_ooc.xdc]
  read_xdc -ref vio_receivedata c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_receivedata/vio_receivedata.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_receivedata/vio_receivedata.xdc]
  read_xdc -mode out_of_context -ref ila_notes c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_ooc.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_ooc.xdc]
  read_xdc -ref ila_notes c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_v6_0/constraints/ila.xdc
  set_property processing_order EARLY [get_files c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_v6_0/constraints/ila.xdc]
  read_xdc C:/Projects/sjtrax/src/VC707_rev_2.0.ucf.xdc
  link_design -top sjtrax -part xc7vx485tffg1761-2
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force sjtrax_opt.dcp
  report_drc -file sjtrax_drc_opted.rpt
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  catch {write_hwdef -file sjtrax.hwdef}
  place_design 
  write_checkpoint -force sjtrax_placed.dcp
  report_io -file sjtrax_io_placed.rpt
  report_utilization -file sjtrax_utilization_placed.rpt -pb sjtrax_utilization_placed.pb
  report_control_sets -verbose -file sjtrax_control_sets_placed.rpt
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force sjtrax_routed.dcp
  report_drc -file sjtrax_drc_routed.rpt -pb sjtrax_drc_routed.pb
  report_timing_summary -warn_on_violation -max_paths 10 -file sjtrax_timing_summary_routed.rpt -rpx sjtrax_timing_summary_routed.rpx
  report_power -file sjtrax_power_routed.rpt -pb sjtrax_power_summary_routed.pb
  report_route_status -file sjtrax_route_status.rpt -pb sjtrax_route_status.pb
  report_clock_utilization -file sjtrax_clock_utilization_routed.rpt
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  catch { write_mem_info -force sjtrax.mmi }
  write_bitstream -force sjtrax.bit 
  catch { write_sysdef -hwdef sjtrax.hwdef -bitfile sjtrax.bit -meminfo sjtrax.mmi -file sjtrax.sysdef }
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

