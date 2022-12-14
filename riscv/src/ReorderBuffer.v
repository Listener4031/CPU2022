`include "riscv/src/defines.v"
// 接受 Decoder 进队尾, 队头检查出队, 接受更新 
module ReorderBuffer(
    input wire clk,
    input wire rst,
    input wire rdy,

    // Decoder
    input wire ID_input_valid,           // `True -> 队尾申请
    output reg ID_ROB_is_full,
    
    // RsvStation
    output reg [`ROBIndexBus] RS_ROB_id,

    // ALU_RS
    input wire ALU_RS_input_valid,
    input wire [`ROBIDBus] ALU_RS_ROB_id,
    input wire [`DataWidth - 1 : 0] ALU_RS_value   

    // RegFile
);

reg [4 : 0] siz; 
reg [`ROBIndexBus] head;
reg [`ROBIndexBus] tail;
// queue index -> ROB_id
reg [`ROBSize - 1 : 0] ready_judger;     // head is `True -> update
reg [`OpIdBus] OP_IDs[`ROBSize - 1 : 0];
reg [`DataWidth - 1 : 0] inst_pcs[`ROBSize - 1 : 0];
reg [`RegIndexBus] rds[`ROBSize - 1 : 0];
reg [`DataWidth - 1 : 0] values[`ROBSize - 1 : 0];

wire ROB_is_full;
assign ROB_is_full = ((siz == 5'b10000) && (ready_judger[head] == `False)) ? `True : `False;

wire in_queue_pos;
assign in_queue_pos = (tail == 4'b1111) ? 4'b0000 : (tail + 4'b0001);

integer i;

always @(posedge clk) begin
    if(rst == `True) begin
        siz <= 5'b00000;
        head <= 4'b0000;
        tail <= 4'b1111;
        for(i = 0; i < `ROBSize; i = i + 1) begin
            ready_judger[i] <= `False;
            OP_IDs[i] <= 5'b00000;
            inst_pcs[i] <= {32{1'b0}};
            rds[i] <= 5'b00000;
            values[i] <= {32{1'b0}};
        end
    end
    else begin
        if(siz != 5'b00000 && ready_judger[head] == `True) begin // 出队
            ready_judger[head] <= `False;
            head <= (head == 4'b1111) ? 4'b0000 : (head + 4'b0001);
            // add1
        end
        if(ALU_RS_input_valid == `True) begin // 更新
            ready_judger[ALU_RS_ROB_id] <= `True;
            values[ALU_RS_ROB_id] <= ALU_RS_value;
        end
        if(ID_input_valid == `True) begin // 队尾
        end
    end
end

always @(posedge clk) begin

end

endmodule