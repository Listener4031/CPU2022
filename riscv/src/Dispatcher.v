`include "riscv/src/defines.v"

module Dispatcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    //Decoder
    input wire ID_valid, 
    input wire [`OpIdBus] ID_OP_ID, 
    input wire [`AddrWidth - 1 : 0] ID_pc,
    input wire [`ImmWidth - 1 : 0] ID_imm,
    input wire [3:0] ID_rd_tag
    
    //ReorderBuffer

    //RegFile

    //RsvStation

    //LSBuffer

    //CDB
);

endmodule