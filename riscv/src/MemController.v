`include "riscv/src/defines.v"

module MemController(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,

    // cpu
    

    // InstFetcher
    output reg IF_enable,
    output reg [`InstWidth - 1 : 0] IF_inst

    // ALU_LS

    /*
    input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
    */
);

reg [1 : 0] status; // 2'b00 -> IDLE, 2'b01 -> Fetch, 2'b10 -> read, 2'b11 -> write

// we need a queue for store

endmodule