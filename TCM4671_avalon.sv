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
    output SCK,
    output MOSI,
    input MISO
  );

  parameter CLOCK_FREQ_HZ = 50_000_000;
  parameter SPI_FREQ_HZ = 1_000_000;

  reg waitFlag;
  assign waitrequest = (waitFlag && (read||write));

  reg [6:0] addr;
  reg [31:0] data_in;
  wire [31:0] data_out;
  reg transmit, writeNOTread;
  assign readdata = data_out;
  wire done;

  TCM4671 #(CLOCK_FREQ_HZ,SPI_FREQ_HZ)tcm4671(
    clk,reset,transmit,addr,writeNOTread,data_in,data_out,SCK,MOSI,MISO,nSCS,done
    );

  always @ ( posedge clk, posedge reset ) begin: AVALON_INTERFACE
    reg read_prev, write_prev;
    if(reset)begin
      waitFlag <= 1;
      transmit <= 0;
    end else begin
      transmit <= 0;
      if(read)begin
        writeNOTread <= 0;
        addr <= address;
        transmit <= 1;
      end else if(write)begin
        writeNOTread <= 1;
        addr <= address;
        transmit <= 1;
        data_in <= writedata;
      end
      if(done)begin // when the transmission is done we release the waitFlag
        waitFlag <= 0;
      end else begin
        waitFlag <= 1;
      end
    end
  end


endmodule //TCM4671_avalon
