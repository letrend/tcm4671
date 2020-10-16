`timescale 1ns/1ps
module testbench_TCM4671;
  timeunit 1ns;
  reg clk, reset;
  wire spi_clk;

  TCM4671 DUT(clk,reset,spi_clk);

  initial
  begin
    clk = 0;
    reset = 0;
    # 2
    reset = 1;
    # 2
    reset = 0;
  end

  always
    #5 clk = !clk;

endmodule // testbench_TCM4671
