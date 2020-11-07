`timescale 1ns/1ps
module TCM4671 (
    input clk,
    input reset,
    input transmit,
    input [6:0] address,
    input writeNOTread,
    input [31:0] data_in,
    output reg [31:0] data_out,
    output SCK,
    output MOSI,
    input MISO,
    output nSCS,
    output reg busy
  );

  parameter CLOCK_FREQ_HZ = 50_000_000;
  parameter SPI_FREQ_HZ = 8_000_000;

  reg slow_clk;
  reg [7:0] clk_counter;

  localparam  IDLE = 0, DELAY = 1, TRANSMIT = 2, DELAY_DONE = 3;
  reg [1:0] transmit_state;

  assign SCK = slow_clk;
  assign nSCS = !(transmit_state==TRANSMIT || transmit_state==DELAY);

  always @(posedge clk or posedge reset) begin: SPI_CLOCK_GENERATION
    if (reset) begin
      slow_clk <= 1;
      clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ/2-1;
    end else begin
      if(transmit_state==TRANSMIT)begin
        clk_counter <= clk_counter-1;
        if(clk_counter==0)begin
          clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ/2-1;
          slow_clk <= !slow_clk;
        end
      end else if(transmit_state==IDLE || transmit_state==DELAY_DONE)begin
        slow_clk = 1;
      end
    end
  end

  wire [39:0] datagram;
  reg [5:0] bit_counter;

  assign datagram[39] = writeNOTread;
  assign datagram[38:32] = address;
  assign datagram[31:0] = data_in;
  assign MOSI = datagram[bit_counter];

  always @ ( posedge clk or posedge reset ) begin
    reg slow_clk_prev;
    reg [7:0] delay_counter;
    reg initial_negative_edge;
    reg [5:0] delay_done_counter;
    if (reset) begin
      data_out <= 0;
      slow_clk_prev <= 0;
      transmit_state <= 0;
      delay_counter <= 0;
      bit_counter <= 39;
    end else begin
      case (transmit_state)
        IDLE: begin
          busy <= 0;
          if(transmit) begin
            transmit_state <= TRANSMIT;
            bit_counter <= 39;
            initial_negative_edge <= 1;
            busy <= 1;
          end
        end
        TRANSMIT: begin
          slow_clk_prev <= slow_clk;
          if(!slow_clk && slow_clk_prev)begin // slow_clk negative edge
            if(bit_counter==32 && !writeNOTread)begin // if we read we need to make a small pause after transmitting the address
              transmit_state <= DELAY;
              delay_counter <= CLOCK_FREQ_HZ/2_000_000; // 500ns delay
            end
            if(bit_counter<=31 && bit_counter>=0)begin // clock in the data available on the MISO line
              data_out[bit_counter] <= MISO;
            end
            if(bit_counter==0)begin // transmission done
              transmit_state <= DELAY_DONE;
              delay_done_counter <= 10;
            end else begin
              if(initial_negative_edge)begin
                initial_negative_edge <= 0;
              end else begin
                bit_counter <= bit_counter - 1;
              end
            end
          end
        end
        DELAY: begin
          delay_counter<=delay_counter-1;
          if(delay_counter==0)begin
            transmit_state <= TRANSMIT;
          end
        end
        DELAY_DONE: begin
          delay_done_counter<=delay_done_counter-1;
          if(delay_done_counter==0)begin
            transmit_state <= IDLE;
          end
        end
      endcase
    end
  end


endmodule // TCM4671
