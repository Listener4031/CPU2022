module RegFile(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clear
);

reg [31:0] regs[31:0];
reg [3:0] reorder[31:0];
reg [31:0] busy;



endmodule