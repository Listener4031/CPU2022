module MemController(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,

    input wire global_full,

    // ram
    input wire [7:0] mem_in,     // data from memory     
    output reg [7:0] mem_out,    // data to memory
    output reg [31:0] mem_addr,  // address in memory
    output reg is_write         // MC is to write memory

    // InstCache

    // LSBuffer
    
);

endmodule