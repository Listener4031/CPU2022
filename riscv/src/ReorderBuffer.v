`include "riscv/src/defines.v"
// 接受 Decoder 进队尾, 队头检查出队, 接受更新 
module ReorderBuffer(
    input wire clk,
    input wire rst,
    input wire rdy,

    // InstCache
    output reg IC_ROB_is_full,

    // Decoder
    input wire ID_input_valid,           // `True -> 队尾申请
    input wire [`AddrWidth - 1 : 0] ID_inst_pc,
    input wire [`OpIdBus] ID_OP_ID,
    input wire [`RegIndexBus] ID_rd,
    input wire ID_predicted_to_jump,
    input wire [`AddrWidth - 1 : 0] ID_predicted_pc,
    
    // RsvStation
    output reg [`ROBIndexBus] RS_ROB_id,         // new ROB_id for a new RS(当前的)
    output reg RS_output_valid,
    output reg [`RegIndexBus] RS_update_ROB_id,
    output reg [`DataWidth - 1 : 0] RS_value,

    // LSBuffer
    output reg [`ROBIndexBus] LSB_ROB_id,         // new ROB_id for a new LS(当前的)
    output reg LSB_output_valid,
    output reg [`RegIndexBus] LSB_update_ROB_id,
    output reg [`DataWidth - 1 : 0] LSB_value,

    // ALU_RS
    input wire ALU_RS_input_valid,
    input wire [`ROBIDBus] ALU_RS_ROB_id,
    input wire [`DataWidth - 1 : 0] ALU_RS_value,
    input wire [`AddrWidth - 1 : 0] ALU_RS_targeted_pc,
    input wire ALU_RS_jump_flag,                        // 当前指令是不是要跳转

    // RegFile
    output reg [`ROBIndexBus] RF_ROB_id,         // 当前的
    output reg RF_output_valid,
    output reg [`RegIndexBus] RF_rd,
    output reg [`DataWidth - 1 : 0] RF_value
);

reg [4 : 0] siz; 
reg [`ROBIndexBus] head; // 指向第一个
reg [`ROBIndexBus] tail; // 指向最后一个
// queue index -> ROB_id
reg [`ROBSize - 1 : 0] ready_judger;     // head is `True -> update
reg [`OpIdBus] OP_IDs[`ROBSize - 1 : 0];
reg [`DataWidth - 1 : 0] inst_pcs[`ROBSize - 1 : 0];
reg [`RegIndexBus] rds[`ROBSize - 1 : 0];
reg [`DataWidth - 1 : 0] values[`ROBSize - 1 : 0];
reg [`AddrWidth - 1 : 0] addrs[`ROBSize - 1 : 0]; // ls
reg [`AddrWidth - 1 : 0] predicted_pcs[`ROBSize - 1 : 0]; // jal, jalr, br

wire ROB_is_full;
assign ROB_is_full = ((siz == 5'b10000) && (ready_judger[head] == `False)) ? `True : `False;

wire in_queue_pos;
assign in_queue_pos = (tail == 4'b1111) ? 4'b0000 : (tail + 4'b0001);

wire roll_back_flag;
assign roll_back_flag = (siz == 5'b00000) ? `False : 
                        (ready_judger[head] == `False) ? `False : 
                        (OP_IDs[head] == `JALR) ? `True : 
                        (OP_IDs[head] == `JAL) ? `False : 
                        (OP_IDs[head] != `BEQ && OP_IDs[head] != `BNE && OP_IDs[head] != `BLT && OP_IDs[head] != `BGE && OP_IDs[head] != `BLTU && OP_IDs[head] != `BGEU) ? `False : 
                        (ALU_RS_targeted_pc == predicted_pcs[head]) ? `False : `True; // 预测是否错误，预测正确啥事不干，预测错误需要回滚

wire will_launch_to_RF;
assign will_launch_to_RF = (OP_IDs[head] == `LUI || OP_IDs[head] == `AUIPC || OP_IDs[head] == `JAL || OP_IDs[head] == `JALR
                          || OP_IDs[head] == `LB || OP_IDs[head] == `LH || OP_IDs[head] == `LW || OP_IDs[head] == `LBU
                           || OP_IDs[head] == `ADD || OP_IDs[head] == `SUB || OP_IDs[head] == `SLL || OP_IDs[head] == `SLT
                            || OP_IDs[head] == `SLTU || OP_IDs[head] == `XOR || OP_IDs[head] == `SRL || OP_IDs[head] == `SRA
                             || OP_IDs[head] == `OR || OP_IDs[head] == `AND || OP_IDs[head] == `ADDI || OP_IDs[head] == `SLTI
                              || OP_IDs[head] == `SLTIU || OP_IDs[head] == `XORI || OP_IDs[head] == `ORI || OP_IDs[head] == `ANDI
                               || OP_IDs[head] == `SLLI || OP_IDs[head] == `SRLI || OP_IDs[head] == `SRAI) ? `True : `False;

always @(*) begin
    IC_ROB_is_full = ROB_is_full;
end

integer i;
/*
reg [4 : 0] siz; 
reg [`ROBIndexBus] head; // 指向第一个
reg [`ROBIndexBus] tail; // 指向最后一个
// queue index -> ROB_id
reg [`ROBSize - 1 : 0] ready_judger;     // head is `True -> update
reg [`OpIdBus] OP_IDs[`ROBSize - 1 : 0];
reg [`DataWidth - 1 : 0] inst_pcs[`ROBSize - 1 : 0];
reg [`RegIndexBus] rds[`ROBSize - 1 : 0];
reg [`DataWidth - 1 : 0] values[`ROBSize - 1 : 0];
reg [`AddrWidth - 1 : 0] addrs[`ROBSize - 1 : 0]; // ls
reg [`AddrWidth - 1 : 0] predicted_pcs[`ROBSize - 1 : 0]; // jal, jalr, br
*/
always @(posedge clk) begin
    if(rst == `True) begin
        siz <= 5'b00000;
        head <= 4'b0000;
        tail <= 4'b1111;
        for(i = 0; i < `ROBSize; i = i + 1) begin
            ready_judger[i] <= `False;
        end
    end
    else if(rdy == `False) begin
    end
    else if(roll_back_flag == `False) begin
        if(ID_input_valid <= `True) begin
            if(siz != 5'b00000 && ready_judger[head] == `True) siz <= siz;
            else siz <= siz + 5'b00001;
        end
        else begin
            if(siz != 5'b00000 && ready_judger[head] == `True) siz <= siz - 5'b00001;
            else siz <= siz;
        end
        RS_ROB_id <= in_queue_pos;
        LSB_ROB_id <= in_queue_pos;
        RF_ROB_id <= in_queue_pos;
        if(ID_input_valid <= `True) begin
            ready_judger[in_queue_pos] <= `False;
            OP_IDs[in_queue_pos] <= ID_OP_ID;
            inst_pcs[in_queue_pos] <= ID_inst_pc;
            rds[in_queue_pos] <= ID_rd;
            if(ID_predicted_to_jump == `True) predicted_pcs[in_queue_pos] <= ID_predicted_pc;
            else predicted_pcs[in_queue_pos] <= ID_inst_pc + 32'h4;
            tail <= in_queue_pos;
        end
        if(siz != 5'b00000 && ready_judger[head] == `True) begin // 发射队首指令
            head <= (head == 4'b1111) ? 4'b0000 : (head + 4'b0001);
            if(will_launch_to_RF == `True) begin
                RS_output_valid <= `True;
                RS_update_ROB_id <= head;
                RS_value <= values[head];
                LSB_output_valid <= `True;
                LSB_update_ROB_id <= head;
                LSB_value <= values[head];
                RF_output_valid <= `True;
                RF_rd <= rds[head];
                RF_value <= values[head];
            end
            else begin
                RS_output_valid <= `False;
                LSB_output_valid <= `False;
                RF_output_valid <= `False;
            end
        end
        if(ALU_RS_input_valid == `True) begin
            ready_judger[ALU_RS_ROB_id] <= `True;
            values[ALU_RS_ROB_id] <= ALU_RS_value;
        end
    end
    else begin // roll back, modify pc
    end
end

endmodule