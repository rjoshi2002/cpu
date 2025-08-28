`timescale 1ns/1ps
/* verilator lint_off UNUSEDSIGNAL */
module imem #(
  parameter MEM_DEPTH = 1024
)
(
  input logic clk,
  input logic [31:0] addr,
  output logic [31:0] instruction
);

  //instruction memory
  logic [31:0] mem[0:MEM_DEPTH-1];

  //read output
  assign instruction = mem[addr[11:2]];

  initial 
  begin
    $readmemh("hex/imem.hex", mem);  
  end
  
endmodule
/* verilator lint_on UNUSEDSIGNAL */
