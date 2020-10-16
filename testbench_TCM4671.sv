`timescale 1ns/1ps
module testbench_TCM4671;
  timeunit 1ns;
  reg clk, reset, transmit;
  wire SCK,MOSI,MISO,nSCS;

  TCM4671 DUT(clk,reset,transmit,SCK,MOSI,MISO,nSCS);

  initial
  begin
    clk = 0;
    reset = 0;
    #2
    reset = 1;
    #2
    reset = 0;
    #10
    // trigger transmission
    transmit = 1;
    #2
    transmit = 0;
  end

  always
    #5 clk = !clk;

endmodule // testbench_TCM4671
