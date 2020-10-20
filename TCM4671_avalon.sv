module TCM4671_avalon (
    input clk,
    input reset,
    input [6:0] address,
    input write,
    input unsigned [31:0] writedata,
    input read,
    output unsigned [31:0] readdata,
    output waitrequest,
    output nSCS,
    output nSDR,
    output SCK,
    output MOSI,
    input MISO
  );

  parameter CLOCK_FREQ_HZ = 50_000_000;
  parameter SPI_FREQ_HZ = 8_000_000;

  reg waitFlag;
  assign waitrequest = (waitFlag && (read||write));

  reg [6:0] addr;
  reg [31:0] data_in;
  wire [31:0] data_out;
  reg transmit, writeNOTread;
  assign readdata = data_out;
  wire busy;
  wire n_ss;
  reg tmc4671_select;

  assign nSCS = tmc4671_select?n_ss:1'hZ;
  assign nSDR = tmc4671_select?1'hZ:n_ss;

  TCM4671 #(CLOCK_FREQ_HZ,SPI_FREQ_HZ)tcm4671(
    clk,reset,transmit,addr,writeNOTread,data_in,data_out,SCK,MOSI,MISO,n_ss,busy
    );

  always @ ( posedge clk, posedge reset ) begin: AVALON_INTERFACE
    reg read_prev, write_prev, busy_prev;
    integer timeout_counter;
    if(reset)begin
      waitFlag <= 1;
      transmit <= 0;
      addr <= 0;
      data_in <= 0;
      writeNOTread <= 0;
      tmc4671_select <= 0;
      timeout_counter <= CLOCK_FREQ_HZ/20_000; // 50us timout
    end else begin
      transmit <= 0;
      waitFlag <= 1;
      read_prev <= read;
      write_prev <= write;
      busy_prev <= busy;
      if(read)begin
        writeNOTread <= 0;
        addr <= address;
        if(!read_prev) begin // positive edge
          transmit <= 1;
        end else if(busy_prev && !busy)begin // when the transmission is done we release the waitFlag
          waitFlag <= 0;
        end
        data_in <= 0;
      end else if(write)begin
        if(address==7'h7F)begin // switches slave select lines
          tmc4671_select <= writedata[0];
          waitFlag <= 0;
        end else begin
          writeNOTread <= 1;
          addr <= address;
          if(!write_prev) begin // positive edge
            transmit <= 1;
          end else if(busy_prev && !busy)begin // when the transmission is done we release the waitFlag
            waitFlag <= 0;
          end
          data_in <= writedata;
        end
      end else begin
        timeout_counter <= CLOCK_FREQ_HZ/20_000; // 50us timout
      end

      if(read||write)begin
        timeout_counter <= timeout_counter-1;
        if(timeout_counter==0)begin // timeout, release waitFlag to prevent system lockup
          waitFlag <= 0;
          timeout_counter <= CLOCK_FREQ_HZ/20_000; // 50us timout
        end
      end
    end
  end


endmodule //TCM4671_avalon
