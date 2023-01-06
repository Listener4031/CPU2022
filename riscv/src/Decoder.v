`include "/Users/weijie/Desktop/CPU2022/riscv/src/defines.v"
// 周期任务：分解从IC进来（如果有）的指令
module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    // InstQueue
    input wire IQ_input_valid,                    // `True -> IQ_inst could be used
    input wire [`InstWidth - 1 : 0] IQ_inst,
    input wire [`AddrWidth - 1 : 0] IQ_inst_pc,
    input wire IQ_predicted_to_jump,
    input wire [`AddrWidth - 1 : 0] IQ_predicted_pc,
    
    // LSBuffer
    output reg LSB_output_valid,
    output reg [`DataWidth - 1 : 0] LSB_inst_pc,
    output reg [`OpIdBus] LSB_OP_ID,
    output reg [`RegIndexBus] LSB_rd,
    output reg [`ImmWidth - 1 : 0] LSB_imm,

    // RegFile
    output reg RF_rd_valid,                      // from RF get ROB_id
    output reg [`RegIndexBus] RF_rd,           
    output reg RF_rs1_valid,
    output reg [`RegIndexBus] RF_rs1,
    output reg RF_rs2_valid,
    output reg [`RegIndexBus] RF_rs2,

    // RsvStation
    output reg RS_output_valid,
    output reg [`DataWidth - 1 : 0] RS_inst_pc,
    output reg [`OpIdBus] RS_OP_ID,
    output reg [`RegIndexBus] RS_rd,
    output reg [`ImmWidth - 1 : 0] RS_imm,

    // ReorderBuffer
    output reg ROB_output_valid,                    // `False -> 不进队
    output reg [`DataWidth - 1 : 0] ROB_inst_pc,
    output reg [`OpIdBus] ROB_OP_ID,
    output reg [`RegIndexBus] ROB_rd,
    output reg ROB_predicted_to_jump,
    output reg [`AddrWidth - 1 : 0] ROB_predicted_pc

);

wire [`OpcodeBus] opcode;
assign opcode = IQ_inst[6 : 0];
wire [`Funct3Bus] funct3;
assign funct3 = IQ_inst[14 : 12];
wire [`Funct7Bus] funct7;
assign funct7 = IQ_inst[31 : 25];

/*
    output reg LSB_output_valid,
    output reg [`DataWidth - 1 : 0] LSB_inst_pc,
    output reg [`OpIdBus] LSB_OP_ID,
    output reg [`RegIndexBus] LSB_rd,
    output reg [`ImmWidth - 1 : 0] LSB_imm,

    output reg RF_rd_valid,                      // from RF get ROB_id
    output reg [`RegIndexBus] RF_rd,           
    output reg RF_rs1_valid,
    output reg [`RegIndexBus] RF_rs1,
    output reg RF_rs2_valid,
    output reg [`RegIndexBus] RF_rs2,

    output reg RS_output_valid,
    output reg [`DataWidth - 1 : 0] RS_inst_pc,
    output reg [`OpIdBus] RS_OP_ID,
    output reg [`RegIndexBus] RS_rd,
    output reg [`ImmWidth - 1 : 0] RS_imm,

    output reg ROB_output_valid,                  // `False -> 不进队
    output reg [`DataWidth - 1 : 0] ROB_inst_pc,
    output reg [`OpIdBus] ROB_OP_ID,
    output reg ROB_predicted_to_jump,
    output reg [`AddrWidth - 1 : 0] ROB_predicted_pc
*/

always @(posedge clk) begin
    if(rst == `True) begin
    end
    else if(rdy == `False) begin
    end
    else if(IQ_input_valid == `True) begin
        if(opcode == `OPCODE_LUI) begin
            // LSB
            LSB_output_valid <= `False;
            // RF
            RF_rd_valid <= `True;
            RF_rd <= IQ_inst[11 : 7];
            RF_rs1_valid <= `False;
            RF_rs2_valid <= `False;
            // RS
            RS_output_valid <= `True;
            RS_inst_pc <= IQ_inst_pc;
            RS_OP_ID <= `LUI;
            RS_rd <= IQ_inst[11 : 7];
            RS_imm <= {IQ_inst[31 : 12], {12{1'b0}}};
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_OP_ID <= `LUI;
            ROB_rd <= IQ_inst[11 : 7];
            ROB_predicted_to_jump <= `False;
            ROB_predicted_pc <= IQ_inst_pc + 32'h4;
        end
        else if(opcode == `OPCODE_AUIPC) begin
            // LSB
            LSB_output_valid <= `False;
            // RF
            RF_rd_valid <= `True;
            RF_rd <= IQ_inst[11 : 7];
            RF_rs1_valid <= `False;
            RF_rs2_valid <= `False;
            // RS
            RS_output_valid <= `True;
            RS_inst_pc <= IQ_inst_pc;
            RS_OP_ID <= `AUIPC;
            RS_rd <= IQ_inst[11 : 7];
            RS_imm <= {IQ_inst[31 : 12], {12{1'b0}}};
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_OP_ID <= `AUIPC;
            ROB_rd <= IQ_inst[11 : 7];
            ROB_predicted_to_jump <= `False;
            ROB_predicted_pc <= IQ_inst_pc + 32'h4;
        end
        else if(opcode == `OPCODE_JAL) begin
            // LSB
            LSB_output_valid <= `False;
            // RF
            RF_rd_valid <= `True;
            RF_rd <= IQ_inst[11 : 7];
            RF_rs1_valid <= `False;
            RF_rs2_valid <= `False;
            // RS
            RS_output_valid <= `True;
            RS_inst_pc <= IQ_inst_pc;
            RS_OP_ID <= `JAL;
            RS_rd <= IQ_inst[11 : 7];
            RS_imm <= {{12{IQ_inst[31]}}, IQ_inst[19:12], IQ_inst[20], IQ_inst[30:21], 1'b0};
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_OP_ID <= `JAL;
            ROB_rd <= IQ_inst[11 : 7];
            ROB_predicted_to_jump <= IQ_predicted_to_jump;
            ROB_predicted_pc <= IQ_predicted_pc;
        end
        else if(opcode == `OPCODE_JALR) begin
            // LSB
            LSB_output_valid <= `False;
            // RF
            RF_rd_valid <= `True;
            RF_rd <= IQ_inst[11 : 7];
            RF_rs1_valid <= `True;
            RF_rs1 <= IQ_inst[19 : 15];
            RF_rs2_valid <= `False;
            // RS
            RS_output_valid <= `True;
            RS_inst_pc <= IQ_inst_pc;
            RS_OP_ID <= `JALR;
            RS_rd <= IQ_inst[11 : 7];
            RS_imm <= {{20{IQ_inst[31]}}, IQ_inst[31 : 20]};
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_OP_ID <= `JALR;
            ROB_rd <= IQ_inst[11 : 7];
            ROB_predicted_to_jump <= IQ_predicted_to_jump;
            ROB_predicted_pc <= IQ_predicted_pc;
        end
        else if(opcode == `OPCODE_B) begin
            // LSB
            LSB_output_valid <= `False;
            // RF
            RF_rd_valid <= `False;
            RF_rs1_valid <= `True;
            RF_rs1 <= IQ_inst[19 : 15];
            RF_rs2_valid <= `True;
            RF_rs2 <= IQ_inst[24 : 20];
            // RS
            RS_output_valid <= `True;
            RS_inst_pc <= IQ_inst_pc;
            RS_rd <= 5'b00000;
            RS_imm <= {{20{IQ_inst[31]}}, IQ_inst[7], IQ_inst[30:25], IQ_inst[11:8], 1'b0};
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_rd <= 5'b00000;
            ROB_predicted_to_jump <= IQ_predicted_to_jump;
            ROB_predicted_pc <= IQ_predicted_pc;
            if(funct3 == `FUNCT3_BEQ) begin
                RS_OP_ID <= `BEQ;
                ROB_OP_ID <= `BEQ;
            end
            else if(funct3 == `FUNCT3_BNE) begin
                RS_OP_ID <= `BNE;
                ROB_OP_ID <= `BNE;
            end
            else if(funct3 == `FUNCT3_BLT) begin
                RS_OP_ID <= `BLT;
                ROB_OP_ID <= `BLT;
            end
            else if(funct3 == `FUNCT3_BGE) begin
                RS_OP_ID <= `BGE;
                ROB_OP_ID <= `BGE;
            end
            else if(funct3 == `FUNCT3_BLTU) begin
                RS_OP_ID <= `BLTU;
                ROB_OP_ID <= `BLTU;
            end
            else if(funct3 == `FUNCT3_BGEU) begin
                RS_OP_ID <= `BGEU;
                ROB_OP_ID <= `BGEU;
            end
        end     
        else if(opcode == `OPCODE_L) begin
            // LSB
            LSB_output_valid <= `True;
            LSB_inst_pc <= IQ_inst_pc;
            LSB_rd <= IQ_inst[11 : 7];
            LSB_imm <= {{20{IQ_inst[31]}}, IQ_inst[31:20]};
            // RF
            RF_rd_valid <= `True;
            RF_rd <= IQ_inst[11 : 7];
            RF_rs1_valid <= `True;
            RF_rs1 <= IQ_inst[19 : 15];
            RF_rs2_valid <= `False;
            // RS
            RS_output_valid <= `False;
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_rd <= IQ_inst[11 : 7];
            ROB_predicted_to_jump <= `False;
            ROB_predicted_pc <= IQ_inst_pc + 32'h4;
            if(funct3 == `FUNCT3_LB) begin
                LSB_OP_ID <= `LB;
                ROB_OP_ID <= `LB;
            end
            else if(funct3 == `FUNCT3_LH) begin
                LSB_OP_ID <= `LH;
                ROB_OP_ID <= `LH;
            end
            else if(funct3 == `FUNCT3_LW) begin
                LSB_OP_ID <= `LW;
                ROB_OP_ID <= `LW;
            end
            else if(funct3 == `FUNCT3_LBU) begin
                LSB_OP_ID <= `LBU;
                ROB_OP_ID <= `LBU;
            end
            else if(funct3 == `FUNCT3_LHU) begin
                LSB_OP_ID <= `LHU;
                ROB_OP_ID <= `LHU;
            end
        end
        else if(opcode == `OPCODE_S) begin
            // LSB
            LSB_output_valid <= `True;
            LSB_inst_pc <= IQ_inst_pc;
            LSB_rd <= 5'b00000;
            LSB_imm <= {{20{IQ_inst[31]}}, IQ_inst[31 : 25], IQ_inst[11 : 7]};
            // RF
            RF_rd_valid <= `False;
            RF_rs1_valid <= `True;
            RF_rs1 <= IQ_inst[19 : 15];
            RF_rs2_valid <= `True;
            RF_rs2 <= IQ_inst[24 : 20];
            // RS
            RS_output_valid <= `False;
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_rd <= 5'b00000;
            ROB_predicted_to_jump <= `False;
            ROB_predicted_pc <= IQ_inst_pc + 32'h4;
            if(funct3 == `FUNCT3_SB) begin
                LSB_OP_ID <= `SB;
                ROB_OP_ID <= `SB;
            end
            else if(funct3 == `FUNCT3_SH) begin
                LSB_OP_ID <= `SH;
                ROB_OP_ID <= `SH;
            end
            else if(funct3 == `FUNCT3_SW) begin
                LSB_OP_ID <= `SW;
                ROB_OP_ID <= `SW;
            end
        end
        else if(opcode == `OPCODE_R) begin
            // LSB
            LSB_output_valid <= `False;
            // RF
            RF_rd_valid <= `True;
            RF_rd <= IQ_inst[11 : 7];
            RF_rs1_valid <= `True;
            RF_rs1 <= IQ_inst[19 : 15];
            RF_rs2_valid <= `True;
            RF_rs2 <= IQ_inst[24 : 20];
            // RS
            RS_output_valid <= `True;
            RS_inst_pc <= IQ_inst_pc;
            RS_rd <= IQ_inst[11 : 7];
            RS_imm <= {32{1'b0}};
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_rd <= IQ_inst[11 : 7];
            ROB_predicted_to_jump <= `False;
            ROB_predicted_pc <= IQ_inst_pc + 32'h4;
            if(funct3 == `FUNCT3_ADD) begin
                if(funct7 == `FUNCT7_ADD) begin
                    RS_OP_ID <= `ADD;
                    ROB_OP_ID <= `ADD;
                end
                else if(funct7 == `FUNCT7_SUB) begin
                    RS_OP_ID <= `SUB;
                    ROB_OP_ID <= `SUB;
                end
            end
            else if(funct3 == `FUNCT3_SLL) begin
                RS_OP_ID <= `SLL;
                ROB_OP_ID <= `SLL;
            end
            else if(funct3 == `FUNCT3_SLT) begin
                RS_OP_ID <= `SLT;
                ROB_OP_ID <= `SLT;
            end
            else if(funct3 == `FUNCT3_SLTU) begin
                RS_OP_ID <= `SLTU;
                ROB_OP_ID <= `SLTU;
            end
            else if(funct3 == `FUNCT3_XOR) begin
                RS_OP_ID <= `XOR;
                ROB_OP_ID <= `XOR;
            end
            else if(funct3 == `FUNCT3_SRL) begin
                if(funct7 == `FUNCT7_SRL) begin
                    RS_OP_ID <= `SRL;
                    ROB_OP_ID <= `SRL;
                end
                else if(funct7 == `FUNCT7_SRA) begin
                    RS_OP_ID <= `SRA;
                    ROB_OP_ID <= `SRA;
                end
            end
            else if(funct3 == `FUNCT3_OR) begin
                RS_OP_ID <= `OR;
                ROB_OP_ID <= `OR;
            end
            else if(funct3 == `FUNCT3_AND) begin
                RS_OP_ID <= `AND;
                ROB_OP_ID <= `AND;
            end
        end 
        else if(opcode == `OPCODE_I) begin
            // LSB
            LSB_output_valid <= `False;
            // RF
            RF_rd_valid <= `True;
            RF_rd <= IQ_inst[11 : 7];
            RF_rs1_valid <= `True;
            RF_rs1 <= IQ_inst[19 : 15];
            RF_rs2_valid <= `False;
            // RS
            RS_output_valid <= `True;
            RS_inst_pc <= IQ_inst_pc;
            RS_rd <= IQ_inst[11 : 7];
            if(funct3 == `FUNCT3_SLLI || funct3 == `FUNCT3_SRLI) RS_imm <= {{26{1'b0}}, IQ_inst[25 : 20]};
            else RS_imm <= {{20{IQ_inst[31]}}, IQ_inst[31 : 20]};
            // ROB
            ROB_output_valid <= `True;
            ROB_inst_pc <= IQ_inst_pc;
            ROB_rd <= IQ_inst[11 : 7];
            ROB_predicted_to_jump <= `False;
            ROB_predicted_pc <= IQ_inst_pc + 32'h4;
            if(funct3 == `FUNCT3_ADDI) begin
                RS_OP_ID <= `ADDI;
                ROB_OP_ID <= `ADDI;
            end
            else if(funct3 == `FUNCT3_SLTI) begin
                RS_OP_ID <= `SLTI;
                ROB_OP_ID <= `SLTI;
            end
            else if(funct3 == `FUNCT3_SLTIU) begin
                RS_OP_ID <= `SLTIU;
                ROB_OP_ID <= `SLTIU;
            end
            else if(funct3 == `FUNCT3_XORI) begin
                RS_OP_ID <= `XORI;
                ROB_OP_ID <= `XORI;
            end
            else if(funct3 == `FUNCT3_ORI) begin
                RS_OP_ID <= `ORI;
                ROB_OP_ID <= `ORI;
            end
            else if(funct3 == `FUNCT3_ANDI) begin
                RS_OP_ID <= `ANDI;
                ROB_OP_ID <= `ANDI;
            end
            else if(funct3 == `FUNCT3_SLLI) begin
                RS_OP_ID <= `SLLI;
                ROB_OP_ID <= `SLLI;
            end
            else if(funct3 == `FUNCT3_SRLI) begin
                if(funct7 == `FUNCT7_SRLI) begin
                    RS_OP_ID <= `SRLI;
                    ROB_OP_ID <= `SRLI;
                end
                else if(funct7 == `FUNCT7_SRAI) begin
                    RS_OP_ID <= `SRAI;
                    ROB_OP_ID <= `SRAI;
                end
            end
        end
        else begin
        end
    end
    else begin
        // LSB
        LSB_output_valid <= `False;
        // RF
        RF_rd_valid <= `False;
        RF_rs1_valid <= `False;
        RF_rs2_valid <= `False;
        // RS
        RS_output_valid <= `False;
        // ROB
        ROB_output_valid <= `False;
    end
end

/*
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
            RF_ind_rd = inst[11:7];
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = 5'b00000;
            RF_rs2_valid = 1'b1;
            RF_ind_rs2 = 5'b00000;
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
            RF_ind_rd = inst[11:7];
            RF_rs1_valid = 1'b1;
            RF_ind_rs1 = inst[19:15];
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
            ROB_enable = 1'b1;
            ROB_ready = 1'b0;
            ROB_rd = inst[11:7];
            ROB_type = 3'b001;
            RF_rd_valid = 1'b0;
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
*/

endmodule