`timescale 1ns/1ps
module testbench_TCM4671;
  timeunit 1ns;
  reg clk, reset, transmit;
  reg writeNOTread;
  reg [6:0] address;
  reg [31:0] data_in;
  wire [31:0] data_out;
  wire SCK,MOSI,MISO,nSCS;
  wire done;

  TCM4671 DUT(clk,reset,transmit,
    address,writeNOTread,data_in,data_out,
    SCK,MOSI,MISO,nSCS,done);

  initial
  begin
    clk = 0;
    reset = 0;
    #2
    reset = 1;
    #2
    reset = 0;
    #10
    address = 1;
    data_in = 0;
    writeNOTread = 0;
    // trigger transmission
    transmit = 1;
    #2
    transmit = 0;
    wait(done);
    #10
    writeNOTread = 1;
    // trigger transmission
    transmit = 1;
    #2
    transmit = 0;
  end

  always
    #5 clk = !clk;

endmodule // testbench_TCM4671
