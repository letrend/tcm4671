`timescale 10ns/10ns
module testbench_TCM4671_avalon;
  reg clk, reset, write, read;
  reg [6:0] address;
  reg [31:0] writedata;
  wire [31:0] readdata;
  wire waitrequest;
  wire SCK,MOSI,MISO,nSCS,nSDR;

  TCM4671_avalon DUT(clk,reset,address,
    write,writedata,read,readdata,waitrequest,
    nSCS,nSDR,SCK,MOSI,MISO);

  initial
  begin
    clk = 0;
    reset = 0;
    write = 0;
    read = 0;
    address = 0;
    #2
    reset = 1;
    #2
    reset = 0;
    #2
    // slave select switch test
    read = 0;

    write = 1;
    writedata = 0;
    address = 7'h7f;
    #2
    wait(!waitrequest)
    write = 0;
    #2
    write = 1;
    writedata = 1;
    address = 7'h7f;
    #2
    wait(!waitrequest)
    write = 0;
    #2
    write = 1;
    writedata = 32'hF0F0F0F0;
    address = 7'h01;
    #2
    wait(!waitrequest)
    write = 0;
    #2
    read = 1;
    address = 7'h01;
    #2
    wait(!waitrequest)
    read = 0;
  end

  always
    #1 clk = !clk;

endmodule // testbench_TCM4671
