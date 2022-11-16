`include "riscv/src/defines.v"

module RegFile(
    input wire clk,
    input wire rst,
    input wire rdy,

    //Dispatcher
    input wire enable,
    input wire [4:0] rd_from_Dispatcher,
    input wire [4:0] Q_from_Dispatcher,
    input wire [4:0] rs1_from_Dispatcher,
    input wire [4:0] rs2_from_Dispatcher,
    output wire [31:0] V1_to_Dispatcher,
    output wire [31:0] V2_to_Dispatcher,
    output wire [4:0] Q1_to_Dispatcher,
    output wire [4:0] Q2_to_Dispatcher,

    //ReorderBuffer
    input wire flag_commit,
    input wire flag_rollback,
    input wire [4:0] rd_from_ReorderBuffer,
    input wire [4:0] Q_from_ReorderBuffer,
    input wire [31:0] V_from_ReorderBuffer
);

reg [4:0] Qs [31:0];
reg [31:0] Vs [31:0];
integer ind;


endmodule