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
    output reg done
  );

  parameter CLOCK_FREQ_HZ = 50_000_000;
  parameter SPI_FREQ_HZ = 8_000_000;

  reg slow_clk;
  reg [7:0] clk_counter;

  localparam  IDLE = 0, DELAY = 1, TRANSMIT = 2;
  reg [1:0] transmit_state;

  assign SCK = slow_clk;
  assign nSCS = !(transmit_state!=IDLE);

  always @(posedge clk or posedge reset) begin: SPI_CLOCK_GENERATION
    if (reset) begin
      slow_clk <= 1;
      clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ/2;
    end else begin
      if(transmit_state==TRANSMIT)begin
        clk_counter <= clk_counter-1;
        if(clk_counter==0)begin
          clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ/2;
          slow_clk <= !slow_clk;
        end
      end else if(transmit_state==IDLE)begin
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
    reg nSCS_prev, transmit_prev, initial_negative_edge;
    if (reset) begin
      data_out <= 0;
      slow_clk_prev <= 0;
      transmit_state <= 0;
      delay_counter <= 0;
    end else begin
      done <= 0;
      nSCS_prev <= nSCS;
      transmit_prev <= transmit;
      if(!nSCS_prev && nSCS)begin // posedge nSCS
        done <= 1;
      end
      case (transmit_state)
        IDLE: begin
          if(transmit && !transmit_prev) begin // positive transmit edge
            transmit_state <= TRANSMIT;
            bit_counter <= 39;
            initial_negative_edge <= 1;
          end
        end
        TRANSMIT: begin
          slow_clk_prev <= slow_clk;
          if(!slow_clk && slow_clk_prev)begin // slow_clk negative edge
            if(bit_counter==0)begin // transmission done
              transmit_state <= IDLE;
            end else begin
              if(initial_negative_edge)begin
                initial_negative_edge <= 0;
              end else begin
                bit_counter <= bit_counter - 1;
              end
            end
          end else if(slow_clk && !slow_clk_prev)begin // slow_clk positive edge
            if(bit_counter==32 && !writeNOTread)begin // if we read we need to make a small pause after transmitting the address
              transmit_state <= DELAY;
              delay_counter <= CLOCK_FREQ_HZ/2_000_000; // 500ns delay
            end
            if(bit_counter<=31 && bit_counter>=0)begin // clock in the data available on the MISO line
              data_out[bit_counter] <= MISO;
            end
          end
        end
        DELAY: begin
          delay_counter<=delay_counter-1;
          if(delay_counter==0)begin
            transmit_state <= TRANSMIT;
          end
        end
      endcase
    end
  end


endmodule // TCM4671
