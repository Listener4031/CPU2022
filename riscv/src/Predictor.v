`include "riscv/src/defines.v"

module Predictor(
    input wire clk,
    input wire rst,
    input wire rdy,

    // InstFetcher
    input wire [`InstWidth - 1 : 0] IF_inst,
    input wire [`AddrWidth - 1 : 0] IF_pc,
    output reg IF_need_jump,
    output reg IF_jumped_pc
);

endmodule