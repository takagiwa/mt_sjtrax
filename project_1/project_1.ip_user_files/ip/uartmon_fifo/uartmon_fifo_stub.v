// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4.2 (win64) Build 1494164 Fri Feb 26 04:18:56 MST 2016
// Date        : Wed Aug 31 17:20:15 2016
// Host        : TAKAGIWA-L running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/uartmon_fifo/uartmon_fifo_stub.v
// Design      : uartmon_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_0_1,Vivado 2015.4.2" *)
module uartmon_fifo(clk, rst, din, wr_en, rd_en, dout, full, empty, valid)
/* synthesis syn_black_box black_box_pad_pin="clk,rst,din[73:0],wr_en,rd_en,dout[73:0],full,empty,valid" */;
  input clk;
  input rst;
  input [73:0]din;
  input wr_en;
  input rd_en;
  output [73:0]dout;
  output full;
  output empty;
  output valid;
endmodule
