// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4.2 (win64) Build 1494164 Fri Feb 26 04:18:56 MST 2016
// Date        : Mon Aug 08 18:59:04 2016
// Host        : TAKAGIWA-L running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               c:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_notes/ila_notes_stub.v
// Design      : ila_notes
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2015.4.2" *)
module ila_notes(clk, trig_in, trig_in_ack, probe0)
/* synthesis syn_black_box black_box_pad_pin="clk,trig_in,trig_in_ack,probe0[49:0]" */;
  input clk;
  input trig_in;
  output trig_in_ack;
  input [49:0]probe0;
endmodule
