module InstQueue(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,

    // InstFetcher
    input wire IF_inst_valid,    // IF_inst is valid
    input wire [31:0] IF_inst,   
    input wire [31:0] IF_pc,     
    output reg IF_queue_full, 

    // Decoder
    input wire ID_valid,         // 1'b1 -> enable IQ to launch inst to Decoder
    output reg ID_inst_valid,    // 1'b0 -> IQ is empty, no inst to launch
    output reg [31:0] ID_inst, 
    output reg [31:0] ID_pc

);

reg [31:0] queue_pc[15:0];
reg [31:0] queue_inst[15:0];
reg [3:0] head, tail;

wire [3:0] new_head, new_tail;

assign new_head = (ID_valid == 1'b1) ? ((head == 4'b1111) ? 4'b0000 : head + 4'b0001) : head;
assign new_tail = (IF_inst_valid == 1'b1) ? ((tail == 4'b1111) ? 4'b0000 : tail + 4'b0001) : tail;

wire [3:0] head_next, tail_next;

assign head_next = (head == 4'b1111) ? 4'b0000 : head + 4'b0001;
assign tail_next = (tail == 4'b1111) ? 4'b0000 : tail + 4'b0001;

always @(*) begin
    if(rst || clr) IF_queue_full = 1'b0;
    else begin
        if(tail_next == head) IF_queue_full = 1'b1;
        else begin
            if(tail_next == 4'b1111) begin
                if(head == 4'b0000) IF_queue_full = 1'b1;
                else IF_queue_full = 1'b0;
            end
            else begin
                if(head == tail_next + 4'b0001) IF_queue_full = 1'b1;
                else IF_queue_full = 1'b0;
            end
        end
    end
end

always @(posedge clk) begin
    if(rst || clr) begin
        ID_inst_valid <= 1'b0;
        ID_inst <= {32{1'b0}};
        ID_pc <= {32{1'b0}};
        head <= 4'b0000;
        tail <= 4'b0000;
    end
    else if(rdy) begin
        if(new_head == new_tail) ID_inst_valid <= 1'b0;
        else ID_inst_valid <= 1'b1;
        head <= new_head;
        tail <= new_tail;
        if(IF_inst_valid == 1'b1 && new_head == tail) begin
            ID_inst <= IF_inst;
            ID_pc <= IF_pc;
        end
        else if(ID_inst_valid == 1'b1) begin
            queue_inst[tail] <= IF_inst;
            queue_pc[tail] <= IF_pc;
        end
        else begin
            ID_inst <= queue_inst[new_head];
            ID_pc <= queue_pc[new_head];
        end
    end
end

endmodule