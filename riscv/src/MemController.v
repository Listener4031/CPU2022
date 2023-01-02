`include "riscv/src/defines.v"

module MemController(
    input wire clk,
    input wire rst,
    input wire rdy,

    // cpu
    input wire uart_buffer_is_full,
    output reg is_write,
    output reg [`AddrWidth - 1 : 0] addr_to_ram,
    input wire [7 : 0] data_in,
    output reg [7 : 0] data_out,

    // InstFetcher
    input wire IF_need_fetch,
    input wire [`AddrWidth - 1 : 0] IF_fetch_pc,
    output reg IF_output_valid,
    output reg [`InstWidth - 1 : 0] IF_inst,

    // ALU_LS
    input wire ALU_LS_need_load,
    input wire [`OpIdBus] ALU_LS_OP_ID,
    input wire [`AddrWidth - 1 : 0] ALU_LS_addr,
    output reg ALU_LS_MSB_is_full,
    output reg ALU_LS_output_valid,
    output reg [`DataWidth - 1 : 0] ALU_LS_value,

    // ReorderBuffer
    input wire ROB_input_valid,
    input wire [`OpIdBus] ROB_OP_ID,
    input wire [`DataWidth - 1 : 0] ROB_value,
    input wire [`AddrWidth - 1 : 0] ROB_addr
);

reg [1 : 0] status; // 2'b00 -> IDLE, 2'b01 -> fetch, 2'b10 -> read, 2'b11 -> write

// we need a queue for store  -  000 001 010 011 100 101 110 111
reg [3 : 0] size_of_MSB;
reg [`MSBIndexBus] head_of_MSB;
reg [`MSBIndexBus] tail_of_MSB;
reg [`AddrWidth - 1 : 0] addrs[`MSBSize - 1 : 0];
reg [`DataWidth - 1 : 0] values[`MSBSize - 1 : 0];
reg [`OpIdBus] OP_IDs[`MSBSize - 1 : 0];

wire [`MSBIndexBus] in_queue_pos;
assign in_queue_pos = (tail_of_MSB == 3'b111) ? 3'b000 : (tail_of_MSB + 3'b001);

// fetch area
reg [3 : 0] fetch_stage; // 4'b0000 -> IDLE, 4'b0001 -> WAIT, 4'b0010 -> first_l, 4'b0011 -> second_l, 4'b0100 -> third_l && g_first,
                         // 4'b0101 -> fourth_l && g_second, 4'b0110 -> g_third, 4'b0111 -> g_fourth, 4'b1000 -> done
reg [`AddrWidth - 1 : 0] fetch_addr;
reg [`InstWidth - 1 : 0] fetch_inst;

// load area
reg [3 : 0] load_stage; // 4'b0000 -> IDLE, 4'b0001 -> WAIT, 
reg [`OpIdBus] load_OP_ID;
reg [`AddrWidth - 1 : 0] load_addr;
reg [`DataWidth - 1 : 0] load_value;

// store area
reg [3 : 0] store_stage; // 4'b0000 -> IDLE, 4'b0001 -> WAIT, 
reg [`OpIdBus] store_OP_ID;
reg [`AddrWidth - 1 : 0] store_addr;
reg [`DataWidth - 1 : 0] store_value;

always @(*) begin
  ALU_LS_MSB_is_full = (size_of_MSB == 4'b1000) ? `True : `False;
end

always @(posedge clk) begin
  if(rst == `True) begin
    // store_buffer
    size_of_MSB <= 4'b0000;
    head_of_MSB <= 3'b000;
    tail_of_MSB <= 3'b111;
    // fetch
    fetch_stage <= 3'b000;
    // load
    load_stage <= 3'b000;
    // store 
    store_stage <= 3'b000;
  end
  else if(rdy == `False) begin
  end
  else begin
    if(ALU_LS_need_load == `True) begin
      load_stage <= 3'b001;
      load_OP_ID <= ALU_LS_OP_ID;
      load_addr <= ALU_LS_addr;
    end
    if(ROB_input_valid == `True) begin // 直接进队
      addrs[in_queue_pos] <= ROB_addr;
      values[in_queue_pos] <= ROB_value;
      OP_IDs[in_queue_pos] <= ROB_OP_ID;
      tail_of_MSB <= in_queue_pos;
    end
    // size_of_store_buffer
    if(status == 2'b00) begin      // IDLE
    end
    else if(status == 2'b01) begin
    end
    else if(status == 2'b10) begin // read
    end
    else begin                     // write
    end
  end
end

endmodule