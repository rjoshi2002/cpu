`timescale 1ns/1ps

//Top Level Testbench
//DUT: Core
//CLK + RST
//Will contain all i/o from the Core
//Will provide Instruction and Data Memory

module tb ();

  //CLK + RST
  logic clk, rst;
  
  //100 MHz CLK
  parameter PERIOD = 10;
  initial clk = 0;
  always #(PERIOD/2) clk = ~clk;
  
  //Start in reset
  initial rst = 1;

  //core i/o
  logic [31:0] pc_start;
  //imem
  logic [31:0] iaddr;
  logic [31:0] instruction;
  //dmem
  logic read;
  logic write;
  logic [3:0] byte_en;
  logic [31:0] daddr;
  logic [31:0] write_data;
  logic [31:0] read_data;
    
  core riscv(.*);

  imem instruction_memory(
    .clk(clk),
    .addr(iaddr),
    .instruction(instruction)
  );

  dmem data_memory(
    .clk(clk),
    .read(read),
    .write(write),
    .byte_en(byte_en),
    .addr(daddr),
    .write_data(write_data),
    .read_data(read_data)
  );
    
initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0, tb);
  #(PERIOD * 5);
  rst = 0;
  pc_start = 0;
  #(PERIOD * 100);
  
  $writememh("hex/imem.hex_dump", instruction_memory.mem);
  $writememh("hex/dmem.hex_dump", data_memory.mem);
  $finish;
end
endmodule
