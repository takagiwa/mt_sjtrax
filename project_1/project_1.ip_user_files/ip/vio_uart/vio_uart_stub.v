// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4.2 (win64) Build 1494164 Fri Feb 26 04:18:56 MST 2016
// Date        : Tue Aug 02 10:25:43 2016
// Host        : TAKAGIWA-L running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               C:/Projects/sjtrax/project_1/project_1.srcs/sources_1/ip/vio_uart/vio_uart_stub.v
// Design      : vio_uart
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "vio,Vivado 2015.4.2" *)
module vio_uart(clk, probe_in0, probe_in1, probe_out0)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[8:0],probe_in1[7:0],probe_out0[8:0]" */;
  input clk;
  input [8:0]probe_in0;
  input [7:0]probe_in1;
  output [8:0]probe_out0;
endmodule
