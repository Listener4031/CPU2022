module CPU(
    input wire clock_in,
    input wire reset_in,
    input wire ready_in,

    input wire [7:0] memory_din,
    output wire [7:0] memory_dout,
    output wire [31:0] memory_addr,
    output wire memory_wr,             //write=1/read=0

    input wire io_buffer_full,        //=1 if buffer is full

    output wire [31:0] dbgreg_dout    // cpu register output
);



endmodule