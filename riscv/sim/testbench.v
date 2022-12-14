// testbench top module file
// for simulation only
`include "riscv/src/test001.v"

`timescale 1ns/1ps
module testbench;

reg clk;
reg rst;

Test test_module(
  .clk(clk),
  .rst(rst)
);

/*
riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .Tx(),
    .Rx(),
    .led()
);
*/

initial begin
  clk=0;
  rst=1;
  repeat(50) #1 clk=!clk;
  rst=0; 
  forever #1 clk=!clk;

  $finish;
end

initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, testbench);
     #300000000 $finish;
end

endmodule
