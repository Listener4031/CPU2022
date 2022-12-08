`include "riscv/src/defines.v"

module ALU_RS(
    input wire clk,
    input wire rst,
    input wire rdy,

    // RsvStation
    input wire [`OpIdBus] RS_OP_ID,
    input wire [`DataWidth - 1 : 0] RS_pc,
    input wire [`DataWidth - 1 : 0] RS_reg_rs1,
    input wire [`DataWidth - 1 : 0] RS_reg_rs2,
    input wire [`ImmWidth - 1 : 0] RS_imm
);



endmodule