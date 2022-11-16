`include "riscv/src/defines.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy

    //MemController
    /*
    // <- MemCtrl
    input wire MemCtrl_inst_valid, 
    input wire [`InstBus] MemCtrl_inst, 
    // -> MemCtrl
    output reg MemCtrl_inst_read_valid,  
    output reg [`AddressBus] MemCtrl_inst_addr
    */
    /*
     // <- IF
    input wire IF_inst_read_valid, 
    input wire [`AddressBus] IF_inst_addr, 
    // -> IF
    output reg IF_inst_valid,
    output reg [`InstBus] IF_inst, 
    */

    //Predictor

    //InstQueue

    //Decoder

    //Dispatcher
);



endmodule