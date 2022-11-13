`include "riscv/src/defines.v"

module Decoder(
    input wire [31:0] inst,

    output reg [5:0] OP_ID,
    output reg [4:0] rd,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [31:0] imm,
    output reg is_load,
    output reg is_store,
    output reg is_jump,
    output reg is_branch
);

always @(*) begin
    OP_ID=`NOP;
    rd=inst[11:7];
    rs1=inst[19:15];
    rs2=inst[24:20];
    imm=32'h0;
    is_load=0;
    is_store=0;
    is_jump=0;
    is_branch=0;

    if(inst[6:0]==`OPCODE_LUI) begin
        OP_ID=`LUI;
        imm={inst[31:12],12'b000000000000};
    end
    else if(inst[6:0]==`OPCODE_AUIPC) begin
        OP_ID=`AUIPC;
        imm={inst[31:12],12'b000000000000};
    end
    else if(inst[6:0]==`OPCODE_JAL) begin
        OP_ID=`JAL;
        imm={{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
        is_jump=1;
    end
    else if(inst[6:0]==`OPCODE_JALR) begin
        OP_ID=`JALR;
        imm={{21{inst[31]}},inst[30:20]};
        is_jump=1;
    end
    else if(inst[6:0]==`OPCODE_B) begin
        if(inst[14:12]==`FUNCT3_BEQ) begin
            OP_ID=`BEQ;
        end
        else if(inst[14:12]==`FUNCT3_BNE) begin
            OP_ID=`BNE;
        end
        else if(inst[14:12]==`FUNCT3_BLT) begin
            OP_ID=`BLT;
        end
        else if(inst[14:12]==`FUNCT3_BGE) begin
            OP_ID=`BGE;
        end
        else if(inst[14:12]==`FUNCT3_BLTU) begin
            OP_ID=`BLTU;
        end
        else if(inst[14:12]==`FUNCT3_BGEU) begin
            OP_ID=`BGEU;
        end
        else begin
        end
        rd=5'b00000;
        imm={{20{inst[31]}},inst[7:7],inst[30:25],inst[11:8],1'b0};
        is_jump=1;
        is_branch=1;
    end
    else if(inst[6:0]==`OPCODE_L) begin
        if(inst[14:12]==`FUNCT3_LB) OP_ID=`LB;
        else if(inst[14:12]==`FUNCT3_LH) OP_ID=`LH;
        else if(inst[14:12]==`FUNCT3_LW) OP_ID=`LW;
        else if(inst[14:12]==`FUNCT3_LBU) OP_ID=`LBU;
        else if(inst[14:12]==`FUNCT3_LHU) OP_ID=`LHU;
        imm={{21{inst[31]}},inst[30:20]};
        is_load=1;
    end
    else if(inst[6:0]==`OPCODE_S) begin
        if(inst[14:12]==`FUNCT3_SB) OP_ID=`SB;
        else if(inst[14:12]==`FUNCT3_SH) OP_ID=`SH;
        else if(inst[14:12]==`FUNCT3_SW) OP_ID=`SW;
        rd=5'b00000;
        imm={{21{inst[31]}},inst[30:25],inst[11:7]};
        is_store=1;
    end
    else if(inst[6:0]==`OPCODE_R) begin
        if(inst[14:12]==`FUNCT3_SUB&&inst[31:25]==`FUNCT7_SUB) OP_ID=`SUB;
        else if(inst[14:12]==`FUNCT3_SRA&&inst[31:25]==`FUNCT7_SRA) OP_ID=`SRA;
        else begin
            if(inst[14:12]==`FUNCT3_ADD) OP_ID=`ADD;
            else if(inst[14:12]==`FUNCT3_SLT) OP_ID=`SLT;
            else if(inst[14:12]==`FUNCT3_SLTU) OP_ID=`SLTU;
            else if(inst[14:12]==`FUNCT3_XOR) OP_ID=`XOR;
            else if(inst[14:12]==`FUNCT3_OR) OP_ID=`OR;
            else if(inst[14:12]==`FUNCT3_AND) OP_ID=`AND;
            else if(inst[14:12]==`FUNCT3_SLL) OP_ID=`SLL;
            else if(inst[14:12]==`FUNCT3_SRL) OP_ID=`SRL;
        end
    end
    else if(inst[6:0]==`OPCODE_I) begin
        imm={{21{inst[31]}},inst[30:20]};
        if(inst[14:12]==`FUNCT3_SRAI&&inst[31:25]==`FUNCT7_SRA) OP_ID=`SRAI;
        else if(inst[31:25]==`FUNCT3_ADDI) OP_ID=`ADDI;
        else if(inst[31:25]==`FUNCT3_SLTI) OP_ID=`SLTI;
        else if(inst[31:25]==`FUNCT3_SLTIU) OP_ID=`SLTIU;
        else if(inst[31:25]==`FUNCT3_XORI) OP_ID=`XORI;
        else if(inst[31:25]==`FUNCT3_ORI) OP_ID=`ORI;
        else if(inst[31:25]==`FUNCT3_ANDI) OP_ID=`ANDI;
        else if(inst[31:25]==`FUNCT3_SLLI) OP_ID=`SLLI;
        else if(inst[31:25]==`FUNCT3_SRLI) OP_ID=`SRLI;
        if(OP_ID==`SLLI||OP_ID==`SRLI||OP_ID==`SRAI) imm=imm[4:0];
    end
    else begin
        OP_ID=`NOP;
        imm=32'h0;
    end
end

endmodule