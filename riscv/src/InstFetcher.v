`include "riscv/src/defines.v"

module InstFetcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // InstCache
    input wire IC_inst_valid,
    input wire [31:0] IC_inst,
    output reg IC_able_read, 
    output reg [31:0] IC_inst_addr, 

    // InstQueue
    input wire IQ_full, 
    output reg IQ_inst_valid, 
    output reg [31:0] IQ_inst, 
    output reg [31:0] IQ_pc, 

    // ReorderBuffer
    input wire ROB_is_jump, 
    input wire[31:0] ROB_pc
    
);

reg [31:0] pc;
reg [31:0] new_pc;

always @(posedge clk) begin
    if(rst) begin
        pc <= {32{1'b0}};
        new_pc <= {32{1'b0}};
        IC_able_read <= 1'b0;
        IC_inst_addr <= {32{1'b0}};
        IQ_inst_valid <= 1'b0;
    end
    else if(rdy) begin
        if(ROB_is_jump == 1'b1) begin
            pc <= ROB_pc;
            new_pc <= ROB_pc + 32'h4;
            IC_able_read <= 1'b1;
            IC_inst_addr <= ROB_pc;
            IQ_inst_valid <= 1'b0;
            IQ_inst <= {32{1'b0}};
            IQ_pc <= {32{1'b0}};
        end
        else if(IC_inst_valid == 1'b1 && IQ_full == 1'b0) begin
            pc <= new_pc;
            new_pc <= new_pc + 32'h4;
            IC_able_read <= 1'b1;
            IC_inst_addr <= new_pc;
            IQ_inst_valid <= 1'b1;
            IQ_inst <= IC_inst;
            IQ_pc <= pc;
        end
        else begin
            IC_able_read <= 1'b1;
            IC_inst_addr <= pc;
            IQ_inst_valid <= 1'b0;
            IQ_inst <= {32{1'b0}};
            IQ_pc <= {32{1'b0}};
        end
    end
end

endmodule