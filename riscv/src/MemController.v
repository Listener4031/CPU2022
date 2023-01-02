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
reg [3 : 0] fetch_stage; // 4'b0000 -> IDLE, 4'b0001 -> WAIT, 
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
    // store buffer
    if(ROB_input_valid == `True) begin // 直接进队
      addrs[in_queue_pos] <= ROB_addr;
      values[in_queue_pos] <= ROB_value;
      OP_IDs[in_queue_pos] <= ROB_OP_ID;
      tail_of_MSB <= in_queue_pos;
    end
    // load area
    if(ALU_LS_need_load == `True) begin
      load_stage <= 4'b0001;
      load_OP_ID <= ALU_LS_OP_ID;
      load_addr <= ALU_LS_addr;
    end
    // store area
    if(size_of_MSB != 4'b0000 && store_stage == 4'b0000) begin
      // store_queue
      head_of_MSB <= (head_of_MSB == 3'b111) ? 3'b000 : (head_of_MSB + 3'b001);
      // store area
      store_stage <= 4'b0001;
      store_OP_ID <= OP_IDs[head_of_MSB];
      store_addr <= addrs[head_of_MSB];
      store_value <= values[head_of_MSB];
    end
    // fetch area
    if(IF_need_fetch == `True) begin
      fetch_stage <= 4'b0001;
      fetch_addr <= IF_fetch_pc;
    end
    // size_of_store_buffer
    if(ROB_input_valid == `True) begin
      if(size_of_MSB != 4'b0000 && store_stage == 4'b0000) size_of_MSB <= size_of_MSB;
      else size_of_MSB <= size_of_MSB + 4'b0001;
    end
    else begin
      if(size_of_MSB != 4'b0000 && store_stage == 4'b0000) size_of_MSB <= size_of_MSB - 4'b0001;
      else size_of_MSB <= size_of_MSB;
    end
    if(status == 2'b00) begin      // IDLE
      is_write <= `False;
      addr_to_ram <= {32{1'b0}};
      // IF
      IF_output_valid <= `True;
      // ALU_LS
      ALU_LS_output_valid <= `False;
      // update 
      if(store_stage == 4'b0001) status <= 2'b11;
      else if(fetch_stage == 4'b0001) status <= 2'b01;
      else if(load_stage == 4'b0001) status <= 2'b10;
      else begin
      end
    end
    else if(status == 2'b01) begin // fetch
      ALU_LS_output_valid <= `False; 
      if(fetch_stage == 4'b0000) begin
        is_write <= `False;
        addr_to_ram <= {32{1'b0}};
        // IF
        IF_output_valid <= `False;
      end
      else if(fetch_stage == 4'b0001) begin // WAIT -> first_launch -> StageOne 
        is_write <= `False;
        addr_to_ram <= fetch_addr;
        // fetch area
        fetch_stage <= 4'b0010;
        // IF
        IF_output_valid <= `False;
      end
      else if(fetch_stage == 4'b0010) begin // StageOne -> second_launch -> StageTwo
        is_write <= `False;
        addr_to_ram <= fetch_addr + 32'h1;
        // fetch area
        fetch_stage <= 4'b0011;
        // IF
        IF_output_valid <= `False;
      end
      else if(fetch_stage == 4'b0011) begin // StageTwo -> third_launch && get_first -> StageThree
        is_write <= `False;
        addr_to_ram <= fetch_addr + 32'h2;
        // fetch area
        fetch_inst[7 : 0] <= data_in;
        fetch_stage <= 4'b0100;
        // IF
        IF_output_valid <= `False;
      end
      else if(fetch_stage == 4'b0100) begin // StageThree -> fourth_launch && get_second -> StageFour
        is_write <= `False;
        addr_to_ram <= fetch_addr + 32'h3;
        // fetch area
        fetch_inst[15 : 8] <= data_in;
        fetch_stage <= 4'b0101;
        // IF
        IF_output_valid <= `False;
      end
      else if(fetch_stage == 4'b0101) begin // StageFour -> get_third -> StageFive
        is_write <= `False;
        addr_to_ram <= {32{1'b0}};
        // fetch area
        fetch_inst[23 : 16] <= data_in;
        fetch_stage <= 4'b0110;
        // IF
        IF_output_valid <= `False;
      end
      else if(fetch_stage == 4'b0110) begin
        is_write <= `False;
        addr_to_ram <= {32{1'b0}};
        // fetch area
        fetch_inst[31: 24] <= data_in;
        fetch_stage <= 4'b0111;
        // IF
        IF_output_valid <= `False;
      end
      else if(fetch_stage == 4'b0111) begin
        is_write <= `False;
        addr_to_ram <= {32{1'b0}};
        // fetch area
        fetch_stage <= 4'b0000;
        // IF
        IF_output_valid <= `True;
        IF_inst <= fetch_inst;
        // update status
        if(store_stage == 4'b0001) status <= 2'b11;
        else if(load_stage == 4'b0001) status <= 2'b10;
        else status <= 2'b00;
      end
      else begin
        is_write <= `False;
        addr_to_ram <= {32{1'b0}};
        // IF
        IF_output_valid <= `False;
      end
    end
    else if(status == 2'b10) begin // read
      IF_output_valid <= `False;
      if(load_OP_ID == `LB || load_OP_ID == `LBU) begin
        if(load_stage == 4'b0000) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0001) begin
          is_write <= `False;
          addr_to_ram <= load_addr;
          // load area
          load_stage <= 4'b0010;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0010) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0011;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0011) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0100;
          load_value[7 : 0] <= data_in;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0100) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0000;
          // ALU_LS
          ALU_LS_output_valid <= `True;
          ALU_LS_value <= (load_OP_ID == `LB) ? $signed(load_value) : load_value;
        end
        else begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
      end
      else if(load_OP_ID == `LH || load_OP_ID == `LBU) begin
        if(load_stage == 4'b0000) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0001) begin
          is_write <= `False;
          addr_to_ram <= load_addr;
          // load area
          load_stage <= 4'b0010;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0010) begin
          is_write <= `False;
          addr_to_ram <= load_addr + 32'h1;
          // load area
          load_stage <= 4'b0011;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0011) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0100;
          load_value[7 : 0] <= data_in;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0100) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0101;
          load_value[15 : 8] <= data_in;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0101) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0000;
          // ALU_LS
          ALU_LS_output_valid <= `True;
          ALU_LS_value <= (load_OP_ID == `LH) ? $signed(load_value) : load_value;
          // update status
          if(store_stage == 4'b0001) status <= 2'b11;
          else if(fetch_stage == 4'b0001) status <= 2'b01;
          else status <= 2'b00;
        end
        else begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
      end
      else begin
        if(load_stage == 4'b0000) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0001) begin
          is_write <= `False;
          addr_to_ram <= load_addr;
          // load area
          load_stage <= 4'b0010;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0010) begin
          is_write <= `False;
          addr_to_ram <= load_addr + 32'h1;
          // load area
          load_stage <= 4'b0011;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0011) begin
          is_write <= `False;
          addr_to_ram <= load_addr + 32'h2;
          // load area
          load_stage <= 4'b0100;
          load_value[7 : 0] <= data_in;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0100) begin
          is_write <= `False;
          addr_to_ram <= load_addr + 32'h3;
          // load area
          load_stage <= 4'b0101;
          load_value[15 : 8] <= data_in;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0101) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0110;
          load_value[23 : 16] <= data_in;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0110) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b0111;
          load_value[31 : 24] <= data_in;
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
        else if(load_stage == 4'b0111) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // load area
          load_stage <= 4'b000;
          // ALU_LS
          ALU_LS_output_valid <= `True;
          ALU_LS_value <= $signed(load_value);
          // update status
          if(store_stage == 4'b0001) status <= 2'b11;
          else if(fetch_stage == 4'b0001) status <= 2'b01;
          else status <= 2'b00;
        end
        else begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
          // ALU_LS
          ALU_LS_output_valid <= `False;
        end
      end
    end
    else begin                     // write
      IF_output_valid <= `False;
      ALU_LS_output_valid <= `False;
      if(store_OP_ID == `SB) begin
        if(store_stage == 4'b0000) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
        end
        else if(store_stage == 4'b0001) begin
          is_write <= `True;
          addr_to_ram <= store_addr;
          data_out <= store_value[7 : 0];
          // store area
          store_stage <= 4'b0000;
          // update status
          if(size_of_MSB == 4'b0000) begin
            if(fetch_stage == 4'b0001) status <= 2'b01;
            else if(load_stage == 4'b0001) status <= 2'b10;
            else status <= 2'b00;
          end
          else status <= 2'b00;
        end
        else begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
        end
      end
      else if(store_OP_ID == `SH) begin
        if(store_stage == 4'b0000) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
        end
        else if(store_stage == 4'b0001) begin
          is_write <= `True;
          addr_to_ram <= store_addr;
          data_out <= store_value[7 : 0];
          // store area
          store_stage <= 4'b0010;
        end
        else if(store_stage == 4'b0010) begin
          is_write <= `True;
          addr_to_ram <= store_addr + 32'h1;
          data_out <= store_value[15 : 8];
          // store area
          store_stage <= 4'b0000;
          // update status
          if(size_of_MSB == 4'b0000) begin
            if(fetch_stage == 4'b0001) status <= 2'b01;
            else if(load_stage == 4'b0001) status <= 2'b10;
            else status <= 2'b00;
          end
          else status <= 2'b00;
        end
        else begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
        end
      end
      else begin
        if(store_stage == 4'b0000) begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
        end
        else if(store_stage == 4'b0001) begin
          is_write <= `True;
          addr_to_ram <= store_addr;
          data_out <= store_value[7 : 0];
          // store area
          store_stage <= 4'b0010;
        end
        else if(store_stage == 4'b0010) begin
          is_write <= `True;
          addr_to_ram <= store_addr + 32'h1;
          data_out <= store_value[15 : 8];
          // store area
          store_stage <= 4'b0011;
        end
        else if(store_stage == 4'b0011) begin
          is_write <= `True;
          addr_to_ram <= store_addr + 32'h2;
          data_out <= store_value[23 : 16];
          // store area
          store_stage <= 4'b0100;
        end
        else if(store_stage == 4'b0100) begin
          is_write <= `True;
          addr_to_ram <= store_addr + 32'h3;
          data_out <= store_value[31 : 24];
          // store area
          store_stage <= 4'b0000;
          // update status
          if(size_of_MSB == 4'b0000) begin
            if(fetch_stage == 4'b0001) status <= 2'b01;
            else if(load_stage == 4'b0001) status <= 2'b10;
            else status <= 2'b00;
          end
          else status <= 2'b00;
        end
        else begin
          is_write <= `False;
          addr_to_ram <= {32{1'b0}};
        end
      end
    end
  end
end

endmodule