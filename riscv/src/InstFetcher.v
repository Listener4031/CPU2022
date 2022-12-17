`include "riscv/src/defines.v"

module InstFetcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    // MemControllor
    input wire MC_input_valid,
    input wire [`InstWidth - 1 : 0] MC_inst,

    // Predictor
    input wire PDC_need_jump,
    input wire [`AddrWidth - 1 : 0] PDC_jumped_pc,
    output reg [`InstWidth - 1 : 0] PDC_inst,
    output reg [`AddrWidth - 1 : 0] PDC_pc
    
);


endmodule