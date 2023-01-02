`include "riscv/src/defines.v"
// 周期任务：进ALU_LS、拉进新的、接受ROB更新
module LSBuffer(
    input wire clk,
    input wire rst,
    input wire rdy,

    // InstCache
    output reg IQ_LSB_is_full,

    // Decoder
    input wire ID_input_valid,
    input wire [`DataWidth - 1 : 0] ID_inst_pc, 
    input wire [`OpIdBus] ID_OP_ID,
    input wire [`RegIndexBus] ID_rd,
    input wire [`ImmWidth - 1 : 0] ID_imm,

    // RegFile
    input wire RF_need_rd_flag,
    input wire RF_rd_valid,
    input wire [`ROBIDBus] RF_rd_ROB_id,
    input wire RF_need_rs1_flag,
    input wire RF_rs1_valid,
    input wire [`DataWidth - 1 : 0] RF_reg_rs1,
    input wire [`ROBIDBus] RF_rs1_ROB_id,
    input wire RF_need_rs2_flag,
    input wire RF_rs2_valid,
    input wire [`DataWidth - 1 : 0] RF_reg_rs2,
    input wire [`ROBIDBus] RF_rs2_ROB_id,

    // ReorderBuffer
    input wire [`ROBIDBus] ROB_new_ID,
    input wire ROB_input_valid,
    input wire [`RegIndexBus] ROB_update_ROB_id,
    input wire [`RegIndexBus] ROB_value,

    // ALU_LS
    input wire ALU_ready,
    output reg ALU_output_valid,
    output reg [`OpIdBus] ALU_OP_ID,
    output reg [`DataWidth - 1 : 0] ALU_inst_pc,
    output reg [`DataWidth - 1 : 0] ALU_reg_rs1,
    output reg [`DataWidth - 1 : 0] ALU_reg_rs2,
    output reg [`ImmWidth - 1 : 0] ALU_imm,
    output reg [`ROBIDBus] ALU_ROB_id
);

reg [4 : 0] siz;
reg [`LSBIndexBus] head;
reg [`LSBIndexBus] tail;
reg [`ROBIDBus] ROB_ids[`LSBSize - 1 : 0];           // id of inst
reg [`DataWidth - 1 : 0] inst_pcs[`LSBSize - 1 : 0]; // pc of inst
reg [`OpIdBus] OP_IDs[`LSBSize - 1 : 0];             // what is the op ?
reg [`RegIndexBus] rds[`LSBSize - 1 : 0];            // rd
reg [`LSBSize - 1 : 0] rs1_valid_judger;
reg [`LSBSize - 1 : 0] rs2_valid_judger;             // `Fasle -> need ROB_id
reg [`DataWidth - 1 : 0] reg_rs1s[`LSBSize - 1 : 0]; 
reg [`DataWidth - 1 : 0] reg_rs2s[`LSBSize - 1 : 0];
reg [`ROBIDBus] id1s[`LSBSize - 1 : 0];
reg [`ROBIDBus] id2s[`LSBSize - 1 : 0];
reg [`ImmWidth - 1 : 0] imms[`LSBSize - 1 : 0];
wire [`LSBSize - 1 : 0] ready_judger;                // can the inst be sent to ALU ?
assign ready_judger[0] = ((rs1_valid_judger[0] == `True) && (rs2_valid_judger[0] == `True)) ? `True : `False;
assign ready_judger[1] = ((rs1_valid_judger[1] == `True) && (rs2_valid_judger[1] == `True)) ? `True : `False;
assign ready_judger[2] = ((rs1_valid_judger[2] == `True) && (rs2_valid_judger[2] == `True)) ? `True : `False;
assign ready_judger[3] = ((rs1_valid_judger[3] == `True) && (rs2_valid_judger[3] == `True)) ? `True : `False;
assign ready_judger[4] = ((rs1_valid_judger[4] == `True) && (rs2_valid_judger[4] == `True)) ? `True : `False;
assign ready_judger[5] = ((rs1_valid_judger[5] == `True) && (rs2_valid_judger[5] == `True)) ? `True : `False;
assign ready_judger[6] = ((rs1_valid_judger[6] == `True) && (rs2_valid_judger[6] == `True)) ? `True : `False;
assign ready_judger[7] = ((rs1_valid_judger[7] == `True) && (rs2_valid_judger[7] == `True)) ? `True : `False;
assign ready_judger[8] = ((rs1_valid_judger[8] == `True) && (rs2_valid_judger[8] == `True)) ? `True : `False;
assign ready_judger[9] = ((rs1_valid_judger[9] == `True) && (rs2_valid_judger[9] == `True)) ? `True : `False;
assign ready_judger[10] = ((rs1_valid_judger[10] == `True) && (rs2_valid_judger[10] == `True)) ? `True : `False;
assign ready_judger[11] = ((rs1_valid_judger[11] == `True) && (rs2_valid_judger[11] == `True)) ? `True : `False;
assign ready_judger[12] = ((rs1_valid_judger[12] == `True) && (rs2_valid_judger[12] == `True)) ? `True : `False;
assign ready_judger[13] = ((rs1_valid_judger[13] == `True) && (rs2_valid_judger[13] == `True)) ? `True : `False;
assign ready_judger[14] = ((rs1_valid_judger[14] == `True) && (rs2_valid_judger[14] == `True)) ? `True : `False;
assign ready_judger[15] = ((rs1_valid_judger[15] == `True) && (rs2_valid_judger[15] == `True)) ? `True : `False;

wire LSB_is_full;
assign LSB_is_full = (siz == 5'b10000 && (ready_judger[head] == `False || ALU_ready == `False)) ? `True : `False;

wire [`LSBIndexBus] in_queue_pos;
assign in_queue_pos = (tail == 4'b1111) ? 4'b0000 : (tail + 4'b0001);

always @(*) begin
    IQ_LSB_is_full = LSB_is_full;
end

integer i;
/*
reg [4 : 0] siz;
reg [3 : 0] head;
reg [3 : 0] tail;
reg [`ROBIDBus] ROB_ids[`LSBSize - 1 : 0];           // id of inst
reg [`DataWidth - 1 : 0] inst_pcs[`LSBSize - 1 : 0]; // pc of inst
reg [`OpIdBus] OP_IDs[`LSBSize - 1 : 0];             // what is the op ?
reg [`RegIndexBus] rds[`LSBSize - 1 : 0];            // rd
reg [`LSBSize - 1 : 0] rs1_valid_judger;
reg [`LSBSize - 1 : 0] rs2_valid_judger;             // `Fasle -> need ROB_id
reg [`DataWidth - 1 : 0] reg_rs1s[`LSBSize - 1 : 0]; 
reg [`DataWidth - 1 : 0] reg_rs2s[`LSBSize - 1 : 0];
reg [`ROBIDBus] id1s[`LSBSize - 1 : 0];
reg [`ROBIDBus] id2s[`LSBSize - 1 : 0];
reg [`ImmWidth - 1 : 0] imms[`LSBSize - 1 : 0];
*/
always @(posedge clk) begin
    if(rst == `True) begin
        siz <= 5'b00000;
        head <= 4'b0000;
        tail <= 4'b1111;
    end
    else if(rdy == `False) begin
    end
    else begin
        if(ROB_input_valid == `True) begin
            if(siz != 5'b00000) begin
                for(i = head; i != in_queue_pos; i = ((i == 4'b1111) ? 4'b0000 : (i + 4'b0001))) begin
                    if(rs1_valid_judger[i] == `False && id1s[i] == ROB_update_ROB_id) begin
                        rs1_valid_judger[i] <= `True;
                        reg_rs1s[i] <= ROB_value;
                    end
                    if(rs2_valid_judger[i] == `False && id2s[i] == ROB_update_ROB_id) begin
                        rs2_valid_judger[i] <= `True;
                        reg_rs2s[i] <= ROB_value;
                    end 
                end
            end
        end
        if(ID_input_valid == `True) begin
            if(siz != 5'b00000 && ready_judger[head] == `True && ALU_ready == `True) siz <= siz;
            else siz <= siz + 5'b00001;
        end
        else begin
            if(siz != 5'b00000 && ready_judger[head] == `True && ALU_ready == `True) siz <= siz - 5'b00001;
            else siz <= siz;
        end
        if(ID_input_valid == `True) begin
            ROB_ids[in_queue_pos] <= ROB_new_ID;
            inst_pcs[in_queue_pos] <= ID_inst_pc;
            OP_IDs[in_queue_pos] <= ID_OP_ID;
            rds[in_queue_pos] <= ID_rd;
            if(RF_rs1_valid == `True || RF_need_rs1_flag == `False) begin
                reg_rs1s[in_queue_pos] <= RF_reg_rs1;
                rs1_valid_judger[in_queue_pos] <= `True;
            end
            else begin
                rs1_valid_judger[in_queue_pos] <= `False;
                id1s[in_queue_pos] <= RF_rs1_ROB_id;
            end
            if(RF_rs2_valid == `True || RF_need_rs2_flag == `False) begin
                reg_rs2s[in_queue_pos] <= RF_reg_rs2;
                rs2_valid_judger[in_queue_pos] <= `True;
            end
            else begin
                rs2_valid_judger[in_queue_pos] <= `False;
                id2s[in_queue_pos] <= RF_rs2_ROB_id;
            end
            imms[in_queue_pos] <= ID_imm;
            tail <= in_queue_pos;
        end
        if(siz != 5'b00000 && ready_judger[head] == `True && ALU_ready == `True) begin
            head <= (head == 4'b1111) ? 4'b0000 : (head + 4'b0001);
            ALU_output_valid <= `True;
            ALU_OP_ID <= OP_IDs[head];
            ALU_inst_pc <= inst_pcs[head];
            ALU_reg_rs1 <= reg_rs1s[head];
            ALU_reg_rs2 <= reg_rs2s[head];
            ALU_imm <= imms[head];
            ALU_ROB_id <= ROB_ids[head];
        end
    end
end

endmodule