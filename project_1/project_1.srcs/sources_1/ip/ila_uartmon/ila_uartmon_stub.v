// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4.2 (win64) Build 1494164 Fri Feb 26 04:18:56 MST 2016
// Date        : Tue Aug 02 10:29:23 2016
// Host        : TAKAGIWA-L running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/ila_uartmon/ila_uartmon_stub.v
// Design      : ila_uartmon
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2015.4.2" *)
module ila_uartmon(clk, trig_in, trig_in_ack, probe0, probe1, probe2, probe3, probe4)
/* synthesis syn_black_box black_box_pad_pin="clk,trig_in,trig_in_ack,probe0[8:0],probe1[8:0],probe2[13:0],probe3[20:0],probe4[20:0]" */;
  input clk;
  input trig_in;
  output trig_in_ack;
  input [8:0]probe0;
  input [8:0]probe1;
  input [13:0]probe2;
  input [20:0]probe3;
  input [20:0]probe4;
endmodule
