`include "riscv/src/defines.v"

module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    // InstCache
    input wire IC_input_valid,                    // `True -> IC_inst could be used
    input wire [`InstWidth - 1 : 0] IC_inst,
    input wire [`AddrWidth - 1 : 0] IC_pc,
    
    // LSBuffer
    input wire LSB_is_full,
    output reg LSB_enable,

    // RegFile
    output reg [`RegIndexBus] RF_rd,           // from RF get ROB_id
    output reg [`RegIndexBus] RF_rs1,
    output reg [`RegIndexBus] RF_rs2,

    // RsvStation
    input wire RS_is_full,                       // `True -> 
    output reg RS_enable,
    output reg [`DataWidth - 1 : 0] RS_inst_pc,
    output reg [`OpIdBus] RS_OP_ID,
    output reg [`RegIndexBus] RS_rd,
    output reg [`ImmWidth - 1 : 0] RS_imm,

    // ReorderBuffer
    input wire ROB_is_full,                      // `True -> 
    output reg ROB_enable,                       // `False -> 不进队
    output reg [`DataWidth - 1 : 0] ROB_inst_pc,
    output reg [`OpIdBus] ROB_OP_ID,
    output reg [`RegIndexBus] ROB_rd,
    output reg [`DataWidth - 1 : 0] ROB_values
);

wire [`InstWidth - 1 : 0] inst;
assign inst = IQ_inst;
wire [`OpcodeBus] opcode;
assign opcode = inst[6:0];
wire [`Funct3Bus] funct3;
assign funct3 = inst[14:12];
wire [`Funct7Bus] funct7;
assign funct7 = inst[31:25];

wire stall;

always @(posedge clk) begin
    if(rst == `True) begin
    end
    else if(stall == `True) begin
    end
    else begin
    end
end

always @(*) begin
    if(stall == 1'b1) begin
        IQ_enable = 1'b0;
        ROB_enable = 1'b0;
        ROB_ready = 1'b0;
        ROB_rd = 5'b00000;
        ROB_type = 3'b000;
        RF_rd_valid = 1'b0;
        RF_ind_rd = 5'b00000;
        RF_rs1_valid = 1'b0;
        RF_ind_rs1 = 5'b00000;
        RF_rs2_valid = 1'b0;
        RF_ind_rs2 = 5'b00000;
        RF_rd_tag = 4'b0000;
        Dispatcher_enable = 1'b0;
        Dispatcher_OP_ID = `NOP;
        Dispatcher_pc = {32{1'b0}};
        Dispatcher_imm = {32{1'b0}};
        Dispatcher_rd_tag = 4'b0000;
    end
    else begin
        IQ_enable = 1'b1;
        Dispatcher_enable = 1'b1;
        Dispatcher_OP_ID = `NOP;
        Dispatcher_pc = IQ_pc;
        if(opcode == `OPCODE_LUI) begin
            Dispatcher_OP_ID = `LUI;
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b000;
            RF_rd_valid = 1'b1;
            RF_ind_rd = inst[11:7];
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = 5'b00000;
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = 5'b00000;
            RF_rd_tag = ROB_tag;
            Dispatcher_imm = {inst[31:12],{12{1'b0}}};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_AUIPC) begin
            Dispatcher_OP_ID = `AUIPC;
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b000;
            RF_rd_valid = 1'b0;
            RF_ind_rd = inst[11:7];
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = 5'b00000;
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = 5'b00000;
            RF_rd_tag = ROB_tag;
            Dispatcher_imm = {inst[31:12],{12{1'b0}}};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_JAL) begin
            Dispatcher_OP_ID = `JAL;
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b100;
            RF_rd_valid = 1'b1;
            //RF_ind_rd = inst[11:7];
            //RF_rs1_valid = 1'b1;
            //RF_ind_rs1 = 5'b00000;
            //RF_rs2_valid = 1'b1;
            //RF_ind_rs2 = 5'b00000;
            RF_rd_tag = ROB_tag;
            Dispatcher_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_JALR) begin
            Dispatcher_OP_ID = `JALR;
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b100;
            RF_rd_valid = 1'b1;
            //RF_ind_rd = inst[11:7];
            //RF_rs1_valid = 1'b1;
            //RF_ind_rs1 = inst[19:15];
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = 5'b00000;
            RF_rd_tag = ROB_tag;
            Dispatcher_imm = {{20{inst[31]}}, inst[31:20]};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_B) begin
            if(funct3 == `FUNCT3_BEQ) Dispatcher_OP_ID = `BEQ;
            else if(funct3 == `FUNCT3_BNE) Dispatcher_OP_ID = `BNE;
            else if(funct3 == `FUNCT3_BLT) Dispatcher_OP_ID = `BLT;
            else if(funct3 == `FUNCT3_BGE) Dispatcher_OP_ID = `BGE;
            else if(funct3 == `FUNCT3_BLTU) Dispatcher_OP_ID = `BLTU;
            else if(funct3 == `FUNCT3_BGEU) Dispatcher_OP_ID = `BGEU;
            //ROB_enable = 1'b1;
            //ROB_ready = 1'b0;
            //ROB_rd = inst[11:7];
            //ROB_type = 3'b001;
            //RF_rd_valid = 1'b0;
            RF_ind_rd = 5'b00000;
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = inst[19:15];
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = inst[24:20];
            RF_rd_tag = 4'b0000;
            Dispatcher_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_L) begin
            if(funct3 == `FUNCT3_LB) Dispatcher_OP_ID = `LB;
            else if(funct3 == `FUNCT3_LH) Dispatcher_OP_ID = `LH;
            else if(funct3 == `FUNCT3_LW) Dispatcher_OP_ID = `LW;
            else if(funct3 == `FUNCT3_LBU) Dispatcher_OP_ID = `LBU;
            else if(funct3 == `FUNCT3_LHU) Dispatcher_OP_ID = `LHU;
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b011;
            RF_rd_valid = 1'b1;
            RF_ind_rd = inst[11:7];
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = inst[19:15];
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = 5'b00000;
            RF_rd_tag = ROB_tag;
            Dispatcher_imm = {{20{inst[31]}}, inst[31:20]};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_S) begin
            if(funct3 == `FUNCT3_SB) Dispatcher_OP_ID = `SB;
            else if(funct3 == `FUNCT3_SH) Dispatcher_OP_ID = `SH;
            else if(funct3 == `FUNCT3_SW) Dispatcher_OP_ID = `SW;
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = 5'b00000;
            ROB_type = 3'b010;
            RF_rd_valid = 1'b0;
            RF_ind_rd = 5'b00000;
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = inst[19:15];
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = inst[24:20];
            RF_rd_tag = ROB_tag;
            Dispatcher_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_R) begin
            if(funct3 == `FUNCT3_ADD) begin
                if(funct7 == `FUNCT7_ADD) Dispatcher_OP_ID = `ADD;
                else if(funct7 == `FUNCT7_SUB) Dispatcher_OP_ID = `SUB;
            end
            else if(funct3 == `FUNCT3_SLL) Dispatcher_OP_ID = `SLL;
            else if(funct3 == `FUNCT3_SLT) Dispatcher_OP_ID = `SLT;
            else if(funct3 == `FUNCT3_SLTU) Dispatcher_OP_ID = `SLTU;
            else if(funct3 == `FUNCT3_XOR) Dispatcher_OP_ID = `XOR;
            else if(funct3 == `FUNCT3_SRL) begin
                if(funct7 == `FUNCT7_SRL) Dispatcher_OP_ID = `SRL;
                else if(funct7 == `FUNCT7_SRA) Dispatcher_OP_ID = `SRA;
            end
            else if(funct3 == `FUNCT3_OR) Dispatcher_OP_ID = `OR;
            else if(funct3 == `FUNCT3_AND) Dispatcher_OP_ID = `AND;
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b000;
            RF_rd_valid = 1'b1;
            RF_ind_rd = inst[11:7];
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = inst[19:15];
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = inst[24:20];
            RF_rd_tag = ROB_tag;
            Dispatcher_imm = {32{1'b0}};
            Dispatcher_rd_tag = ROB_tag;
        end
        else if(opcode == `OPCODE_I) begin
            if(funct3 == `FUNCT3_ADDI) Dispatcher_OP_ID = `ADDI;
            else if(funct3 == `FUNCT3_SLTI) Dispatcher_OP_ID = `SLTI;
            else if(funct3 == `FUNCT3_SLTIU) Dispatcher_OP_ID = `SLTIU;
            else if(funct3 == `FUNCT3_XORI) Dispatcher_OP_ID = `XORI;
            else if(funct3 == `FUNCT3_ORI) Dispatcher_OP_ID = `ORI;
            else if(funct3 == `FUNCT3_ANDI) Dispatcher_OP_ID = `ANDI;
            else if(funct3 == `FUNCT3_SLLI) Dispatcher_OP_ID = `SLLI;
            else if(funct3 == `FUNCT3_SRLI) begin
                if(funct7 == `FUNCT7_SRLI) Dispatcher_OP_ID = `SRLI;
                else if(funct7 == `FUNCT7_SRAI) Dispatcher_OP_ID = `SRAI;
            end
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b000;
            RF_rd_valid = 1'b1;
            RF_ind_rd = inst[11:7];
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = inst[19:15];
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = 5'b00000;
            RF_rd_tag = ROB_tag;
            if(funct3 == `FUNCT3_SLLI || funct3 == `FUNCT3_SRLI) Dispatcher_imm = {{26{1'b0}}, inst[25:20]};
            else Dispatcher_imm = {{20{inst[31]}}, inst[31:20]};
            Dispatcher_rd_tag = ROB_tag;
        end
        else begin
            ROB_enable = 1'b0;
            ROB_ready = 1'b0;
            ROB_rd = 5'b00000;
            ROB_type = 3'b000;
            RF_rd_valid = 1'b0;
            RF_ind_rd = 5'b00000;
            RF_rs1_valid = 1'b0;
            RF_ind_rs1 = 5'b00000;
            RF_rs2_valid = 1'b0;
            RF_ind_rs2 = 5'b00000;
            RF_rd_tag = 4'b0000;
            Dispatcher_imm = {32{1'b0}};
            Dispatcher_rd_tag = 4'b0000;
        end
    end
end

endmodule