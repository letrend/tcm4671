`timescale 10ns/10ns
module testbench_TCM4671;
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
    #3
    reset = 1;
    #1
    reset = 0;
    #1
    address = 1;
    data_in = 0;
    writeNOTread = 0;
    transmit = 0;
    #2
    // trigger transmission
    transmit = 1;
    #1
    transmit = 0;
    wait(done);
    writeNOTread = 1;
    // trigger transmission
    transmit = 1;
    #3
    transmit = 0;
  end

  always
    #1 clk = !clk;

endmodule // testbench_TCM4671
