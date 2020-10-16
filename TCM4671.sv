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
    output done
  );

  parameter CLOCK_FREQ_HZ = 50_000_000;
  parameter SPI_FREQ_HZ = 1_000_000;

  reg slow_clk;
  reg [7:0] clk_counter;

  localparam  IDLE = 0, DELAY = 1, TRANSMIT = 2;
  reg [1:0] transmit_state;

  assign SCK = slow_clk;
  assign nSCS = !(transmit_state!=IDLE);

  always @(posedge clk or posedge reset) begin: SPI_CLOCK_GENERATION
    if (reset) begin
      slow_clk <= 0;
      clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ;
    end else begin
      if(transmit_state==TRANSMIT)begin
        clk_counter <= clk_counter-1;
        if(clk_counter==0)begin
          clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ;
          slow_clk <= !slow_clk;
        end
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
    if (reset) begin
      bit_counter <= 39;
      data_out <= 0;
      slow_clk_prev <= 0;
      transmit_state <= 0;
      delay_counter <= 0;
    end else begin
      case (transmit_state)
        IDLE: begin
          if(transmit) begin
            transmit_state <= TRANSMIT;
          end
        end
        TRANSMIT: begin
          slow_clk_prev <= slow_clk;
          if(!slow_clk && slow_clk_prev)begin // slow_clk negative edge
            if(bit_counter==0)begin // transmission done
              bit_counter <= 39;
              transmit_state <= IDLE;
            end else begin
              bit_counter <= bit_counter - 1;
              if(bit_counter==32 && !writeNOTread)begin // if we read we need to make a small pause after transmitting the address
                transmit_state <= DELAY;
                delay_counter <= CLOCK_FREQ_HZ/2_000_000; // 500ns delay
              end
            end
          end else if(!slow_clk && slow_clk_prev)begin // slow_clk positive edge
            if(bit_counter<32)begin // clock in the data available on the MISO line
              data_out[bit_counter] = MISO;
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
