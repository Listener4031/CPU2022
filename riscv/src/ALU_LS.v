`include "riscv/src/defines.v"

module ALU_LS(
    input wire clk,
    input wire rst,
    input wire rdy,

    // LSBuffer
    input wire LSB_input_valid,
    input wire [`OpIdBus] LSB_OP_ID,
    input wire [`DataWidth - 1 : 0] LSB_inst_pc,
    input wire [`DataWidth - 1 : 0] LSB_reg_rs1,
    input wire [`DataWidth - 1 : 0] LSB_reg_rs2,
    input wire [`ImmWidth - 1 : 0] LSB_imm,
    input wire [`ROBIDBus] LSB_ROB_id
    

);

endmodule