module MemController(
    input wire clk,
    input wire rst,
    input wire rdy,
    input wire clr,

    input wire global_full,

    // ram
    input wire [7:0] mem_in,     // data from memory     
    output reg [7:0] mem_out,    // data to memory
    output reg [31:0] mem_addr,  // address in memory
    output reg is_write,         // MC is to write memory

    // InstCache
    input wire IC_able_read,          // IC is able to read
    input wire [31:0] IC_inst_addr,   // address in IC
    output reg IC_able_fetch,         // IC is able to fetch instruction
    output reg [31:0] IC_inst,        // instruction to IC

    // LSBuffer
    input wire LSB_valid,              //
    input wire [31:0] LSB_addr,        // address in LSB
    input wire LSB_is_write,           // LSB is to write 
    input wire [31:0] LSB_write_data,  // data from LSB
    input wire [2:0] LSB_data_len,     //
    output reg LSB_data_valid,         // 
    output reg [31:0] LSB_data         // data to LSB
    
);

reg [31:0] data;
reg [1:0] status;  // 00 -> IDLE, 01 -> fetch_inst, 10 -> read, 11 -> write
reg [3:0] stage;   // 0000 -> None, 0001 -> StageOne, 0010 -> StageTwo, 0011 -> StageThree, 0100 -> Done, 0101 -> Wait,
                   // 1000 -> NoneWait, 1001 -> StageOneWait, 1010 -> StageTwoWait

always @(*) begin
    if(rst||clr) begin
        is_write = 1'b0;
        mem_addr = {32{1'b0}};
        mem_out = {8{1'b0}};
    end
    else if(rdy) begin
        if(status==2'b00) begin 
            is_write = 1'b0;
            mem_addr = {32{1'b0}};
            mem_out = {8{1'b0}};
        end
        else if(status==2'b01) begin 
            if(stage==4'b0100) begin 
                is_write = 1'b0;
                mem_addr = {32{1'b0}};
                mem_out = {8{1'b0}};
            end
            else begin 
                is_write = 1'b0;
                mem_addr = IC_inst_addr + stage * 32'h1;
                mem_out=8'b0;
            end
        end
        else if(status==2'b01) begin
            if(stage == 4'b0100||stage == 4'b0101||stage == LSB_data_len) begin
                is_write = 1'b0;
                mem_addr = {32{1'b0}};
                mem_out = {8{1'b0}};
            end
            else begin
                is_write = 1'b0;
                mem_addr = LSB_addr + stage * 32'h1;
                mem_out = {8{1'b0}};
            end
        end
        else begin
            if(global_full == 1'b1) begin
                is_write = 1'b0;
                mem_addr = {32{1'b0}};
                mem_out = {8{1'b0}};
            end
            else if(stage == 4'b0000) begin
                is_write = 1'b1;
                mem_addr = LSB_addr;
                mem_out = LSB_write_data[7:0];
            end
            else if(stage == 4'b0001) begin
                if(stage == LSB_data_len) begin
                    is_write = 1'b0;
                    mem_addr = {32{1'b0}};
                    mem_out = {8{1'b0}};
                end
                else begin
                    is_write = 1'b1;
                    mem_addr = LSB_addr + stage * 31'h1;
                    mem_out = LSB_write_data[15:8];
                end
            end
            else if(stage == 4'b0010) begin
                if(stage == LSB_data_len) begin
                    is_write = 1'b0;
                    mem_addr = {32{1'b0}};
                    mem_out = {8{1'b0}};
                end
                else begin
                    is_write = 1'b1;
                    mem_addr = LSB_addr + stage * 31'h1;
                    mem_out = LSB_write_data[23:16];
                end
            end
            else if(stage == 4'b0011) begin
                is_write = 1'b1;
                mem_addr = LSB_addr + stage * 31'h1;
                mem_out = LSB_write_data[31:24];
            end
            else begin
                is_write = 1'b0;
                mem_addr = {32{1'b0}};
                mem_out = {8{1'b0}};
            end
        end
    end
    else begin
        is_write = 1'b0;
        mem_addr = {32{1'b0}};
        mem_out = {8{1'b0}};
    end
end

always @(posedge clk or negedge rst) begin
    if(rst||clr) begin
        status <= 2'b00;
        stage <= 4'b0000;
        IC_able_fetch <= 1'b0;
        LSB_data_valid <= 1'b0;
    end
    else if(rdy) begin
        if(status == 2'b00) begin
            IC_able_fetch <= 1'b0;
            LSB_data_valid <= 1'b0;
            if(LSB_valid == 1'b1) begin
                if(LSB_is_write == 1'b1) status <= 2'b11;
                else status <= 2'b10;
            end
            else if(IC_able_read == 1'b1) status <= 2'b01;
            else status <= 2'b00;
            stage <= 4'b0000;
        end
        else if(status == 2'b01) begin
            LSB_data_valid <= 1'b0;
            IC_able_fetch <= 1'b0;
            if(stage == 4'b0000) stage <= 4'b0001;
            else if(stage == 4'b0001) begin
                data[7:0] <= mem_in;
                stage <= 4'b0010;
            end
            else if(stage == 4'b0010) begin
                data[15:8] <= mem_in;
                stage <= 4'b0011;
            end
            else if(stage == 4'b0011) begin
                data[23:16] <= mem_in;
                stage <= 4'b0100;
            end
            else if(stage == 4'b0100) begin
                data[31:24] <= mem_in;
                stage <= 4'b0000;
                status <=2'b00;
                IC_inst <= {mem_in,data[23:0]};
            end
        end
        else if(status == 2'b10) begin
            IC_able_fetch <= 1'b0;
            if(stage == 4'b0000) begin
                stage <= 4'b0001;
                LSB_data_valid <= 1'b0;
            end
            else if(stage == 4'b0001) begin
                data[7:0] <= mem_in;
                if(stage == LSB_data_len) begin
                    stage <= 4'b0101;
                    LSB_data_valid <= 1'b1;
                    LSB_data <= {{24{1'b0}},mem_in};
                end
                else begin
                    stage <= 4'b0010;
                    LSB_data_valid <= 1'b0;
                end
            end
            else if(stage == 4'b0010) begin
                data[15:8] <= mem_in;
                if(stage == LSB_data_len) begin
                    stage <= 4'b0101;
                    LSB_data_valid <= 1'b1;
                    LSB_data <= {{16{1'b0}},mem_in,data[7:0]};
                end
                else begin
                    stage <= 4'b0011;
                    LSB_data_valid <= 1'b0;
                end
            end
            else if(stage == 4'b0011) begin
                data[23:16] <= mem_in;
                stage <= 4'b0100;
                LSB_data_valid <= 1'b0;
            end
            else if(stage == 4'b0100) begin
                data[31:24] <= mem_in;
                stage <= 4'b0101;
                LSB_data_valid <= 1'b1;
                LSB_data <= {mem_in, data[23:0]};
            end
            else if(stage == 4'b0101) begin
                status <= 2'b00;
                IC_able_fetch <= 1'b0;
                LSB_data_valid <= 1'b0;
            end
        end
        else begin
            IC_able_fetch <= 1'b0;
            if(global_full == 1'b1) LSB_data_valid <= 1'b0;
            else if(stage == 4'b0000) begin
                if(LSB_data_len == 4'b0001) begin
                    stage <= 4'b0100;
                    LSB_data_valid <= 1'b1;
                    LSB_data <= {32{1'b0}};
                    IC_able_fetch <= 1'b0;
                end
                else begin
                    stage <= 4'b1000;
                    LSB_data_valid <= 1'b0;
                    IC_able_fetch <= 1'b0;
                end
            end
            else if(stage == 4'b1000) begin
                stage <= 4'b0001;
                LSB_data_valid <= 1'b0;
                IC_able_fetch <= 1'b0;
            end
            else if(stage == 4'b0001) begin
                if(LSB_data_len == 4'b0010) begin
                    stage <= 4'b0100;
                    LSB_data_valid <= 1'b1;
                    LSB_data <= {32{1'b0}};
                    IC_able_fetch <= 1'b0;
                end
                else begin
                    stage <= 4'b1001;
                    LSB_data_valid <= 1'b0;
                    IC_able_fetch <= 1'b0;
                end
            end
            else if(stage == 4'b1001) begin
                stage <= 4'b0010;
                LSB_data_valid <= 1'b0;
                IC_able_fetch <= 1'b0;
            end
            else if(stage == 4'b0010) begin
                stage <= 4'b1010;
                LSB_data_valid <= 1'b0;
                IC_able_fetch <= 1'b0;
            end
            else if(stage == 4'b1010) begin
                stage <= 4'b0011;
                LSB_data_valid <= 1'b0;
                IC_able_fetch <= 1'b0;
            end
            else if(stage == 4'b0011) begin
                stage <= 4'b0100;
                LSB_data_valid <= 1'b1;
                LSB_data <= {32{1'b0}};
                IC_able_fetch <= 1'b0;
            end
            else if(stage == 4'b0100) begin
                status <= 2'b00;
                LSB_data_valid <= 1'b0;
                LSB_data <= {32{1'b0}};
                IC_able_fetch <= 1'b0;
            end
        end
    end
    else begin
        LSB_data_valid <= 1'b0;
        IC_able_fetch <= 1'b0;
    end
end

endmodule