`include "riscv/src/defines.v"

module InstCache(
    input wire clk,
    input wire rst,
    input wire rdy,

    // ReorderBuffer
    input wire ROB_is_full,

    // RsvStation
    input wire RS_is_full,

    // LSBuffer
    input wire LSB_is_full

    // InstFetcher

    // Decoder

);

endmodule