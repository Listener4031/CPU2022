`include "riscv/src/defines.v"

module ALU_RS(
    input wire clk,
    input wire rst,
    input wire rdy,

    // RsvStation
    input wire RS_input_valid,
    input wire [`OpIdBus] RS_OP_ID,
    input wire [`DataWidth - 1 : 0] RS_pc,
    input wire [`DataWidth - 1 : 0] RS_reg_rs1,
    input wire [`DataWidth - 1 : 0] RS_reg_rs2,
    input wire [`ImmWidth - 1 : 0] RS_imm,
    input wire [`ROBIDBus] RS_ROB_id,

    // ReorderBuffer
    output reg ROB_enable,
    output reg [`ROBIDBus] ROB_ROB_id,
    output reg [`DataWidth - 1 : 0] ROB_value
);

always @(posedge clk) begin
    ROB_enable <= RS_input_valid;
    if(rst == `True) begin
    end
    else if(RS_input_valid == `True) begin
        if(RS_OP_ID == `LUI) begin
        end
        else if(RS_OP_ID == `AUIPC) begin
        end
        else if(RS_OP_ID == `JAL) begin
        end
        else if(RS_OP_ID == `JALR) begin
        end
        else if(RS_OP_ID == `BEQ) begin
        end
        else if(RS_OP_ID == `BNE) begin
        end
        else if(RS_OP_ID == `BLT) begin
        end
        else if(RS_OP_ID == `BGE) begin
        end
        else if(RS_OP_ID == `BLTU) begin
        end
        else if(RS_OP_ID == `BGEU) begin
        end
        else if(RS_OP_ID == `ADD) begin
        end
        else if(RS_OP_ID == `SUB) begin
        end
        else if(RS_OP_ID == `SLL) begin
        end
        else if(RS_OP_ID == `SLT) begin
        end
        else if(RS_OP_ID == `SLTU) begin
        end
        else if(RS_OP_ID == `XOR) begin
        end
        else if(RS_OP_ID == `SRL) begin
        end
        else if(RS_OP_ID == `SRA) begin
        end
        else if(RS_OP_ID == `OR) begin
        end
        else if(RS_OP_ID == `AND) begin
        end
        else if(RS_OP_ID == `ADDI) begin
        end
        else if(RS_OP_ID == `SLTI) begin
        end
        else if(RS_OP_ID == `SLTIU) begin
        end
        else if(RS_OP_ID == `XORI) begin
        end
        else if(RS_OP_ID == `ORI) begin
        end
        else if(RS_OP_ID == `ANDI) begin
        end
        else if(RS_OP_ID == `SLLI) begin
        end
        else if(RS_OP_ID == `SRLI) begin
        end
        else if(RS_OP_ID == `SRAI) begin
        end
    end
end

endmodule