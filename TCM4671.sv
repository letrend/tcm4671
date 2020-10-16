module TCM4671 (
    input clk,
    input reset,
    output spi_clk
  );

  parameter CLOCK_FREQ_HZ = 50_000_000;
  parameter SPI_FREQ_HZ = 25_000_000;

  reg slow_clk;
  reg [7:0] clk_counter;

  assign spi_clk = slow_clk;

  always @(posedge clk or posedge reset) begin: SPI_CLOCK_GENERATION
    if (reset) begin
      slow_clk <= 0;
      clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ;
    end else begin
      clk_counter <= clk_counter-1;
      if(clk_counter==0)begin
        clk_counter <= CLOCK_FREQ_HZ/SPI_FREQ_HZ;
        slow_clk <= !slow_clk;
      end
    end
  end

  reg [6:0] address;
  reg writeNOTread;
  reg [31:0] data_in;
  reg [31:0] data_out;
  wire [39:0] datagram;
  reg [5:0] bit_counter;

  assign datagram[39] = writeNOTread;
  assign datagram[38:32] = address;
  assign datagram[31:0] = writeNOTread?data_in:data_out;

  always @ ( posedge clk or posedge reset ) begin
    if (reset) begin
      bit_counter <= 39;
      data_out <= 0;
      data_in <= 0;
      writeNOTread <= 1;
      address <= 1;
    end
  end


endmodule // TCM4671
