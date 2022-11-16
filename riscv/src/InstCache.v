`include "riscv/src/defines.v"

module InstCache(
    input wire clk,
    input wire rst,
    input wire rdy,

    // InstFetcher
    input wire IF_able_read, 
    input wire [31:0] IF_inst_addr, 
    output reg IF_inst_valid,
    output reg [31:0] IF_inst, 

    // MemController
    input wire MC_inst_valid, 
    input wire [31:0] MC_inst, 
    output reg MC_able_read,  
    output reg [31:0] MC_inst_addr
);

reg [31:0] inst[511:0];
reg [6:0] tag[511:0];
reg [511:0] valid;

integer ind;

always @(posedge clk) begin
    if(rst) valid <= {512{1'b0}};
    else if(rdy && MC_inst_valid == 1'b1) begin
        tag[IF_inst_addr[10:2]] <= IF_inst_addr[17:11];
        valid[IF_inst_addr[10:2]] <= 1'b0;
        inst[IF_inst_addr[10:2]] <= MC_inst;
    end
end

always @(*) begin
    if(rst) begin
        IF_inst_valid = 1'b0;
        IF_inst = {32{1'b0}};
        MC_able_read = 1'b0;
        MC_inst_addr = {32{1'b0}};
    end
    else if(rdy && IF_able_read == 1'b1) begin
        if(valid[IF_inst_addr[10:2]] == 1'b1 && tag[IF_inst_addr[10:2]] == IF_inst_addr[17:11]) begin
            IF_inst_valid = 1'b1;
            IF_inst = inst[IF_inst_addr[10:2]];
            MC_able_read = 1'b1;
            MC_inst_addr = {32{1'b0}};
        end
        else if(MC_inst_valid == 1'b1) begin
            IF_inst_valid = 1'b1;
            IF_inst = MC_inst;
            MC_able_read = 1'b0;
            MC_inst_addr = {32{1'b0}};
        end
        else begin
            IF_inst_valid = 1'b0;
            IF_inst = {32{1'b0}};
            MC_able_read = 1'b1;
            MC_inst_addr = IF_inst_addr;
        end
    end
    else begin
        IF_inst_valid = 1'b0;
        IF_inst = {32{1'b0}};
        MC_able_read = 1'b0;
        MC_inst_addr = {32{1'b0}};
    end
end

endmodule