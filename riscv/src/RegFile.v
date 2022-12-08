`include "riscv/src/defines.v"

module RegFile(
    input wire clk,
    input wire rst,
    input wire rdy,

    // Decoder
    input wire [`RegIndexBus] ID_rd,
    input wire [`RegIndexBus] ID_rs1,
    input wire [`RegIndexBus] ID_rs2,

    // RsvStation
    output reg RS_rd_valid,
    output reg [`ROBIDBus] RS_rd_ROB_id,
    output reg RS_rs1_valid,
    output reg [`DataWidth - 1 : 0] RS_reg_rs1,
    output reg [`ROBIDBus] RS_rs1_ROB_id,
    output reg RS_rs2_valid,
    output reg [`DataWidth - 1 : 0] RS_reg_rs2,
    output reg [`ROBIDBus] RS_rs2_ROB_id
);

reg [`DataWidth - 1 : 0] register[`RegSize - 1 : 0];
reg [`RegSize - 1 : 0] invalid_judger;                // `True -> need ROB_id
reg [`ROBIDBus] ROB_ids[`RegSize - 1 : 0];

always @(*) begin
    if(invalid_judger[ID_rd] == `True) begin
        RS_rd_valid = `False;
        RS_rd_ROB_id = ROB_ids[ID_rd];
    end
    else begin
        RS_rd_valid = `True;
    end
    if(invalid_judger[ID_rs1] == `True) begin
        RS_rs1_valid = `False;
        RS_rs1_ROB_id = ROB_ids[ID_rs1];
    end
    else begin
        RS_rs1_valid = `True;
        RS_reg_rs1 = register[ID_rs1];
    end
    if(invalid_judger[ID_rs2] == `True) begin
        RS_rs2_valid = `False;
        RS_rs2_ROB_id = ROB_ids[ID_rs2];
    end
    else begin
        RS_rs2_valid = `True;
        RS_reg_rs2 = register[ID_rs2];
    end
end

endmodule