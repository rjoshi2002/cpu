`timescale 1ns/1ps
/* verilator lint_off UNUSEDSIGNAL */
module dmem #(
  parameter MEM_DEPTH = 1024
)
(
  input logic clk,
  input logic read,
  input logic write,
  input logic [3:0] byte_en,
  input logic [31:0] addr, 
  input logic [31:0] write_data,
  output logic [31:0] read_data
);

  //data memory
  logic [7:0] mem[0:(MEM_DEPTH*4)-1];

  //reads
  always_comb
  begin
    read_data = 
    {
      mem[addr + 3],
      mem[addr + 2],
      mem[addr + 1],
      mem[addr + 0]
    };
  end

  always_ff @(posedge clk)
  begin
    if(write) begin
      if(byte_en[0]) mem[addr + 0] <= write_data[7:0];
      if(byte_en[1]) mem[addr + 1] <= write_data[15:8];
      if(byte_en[2]) mem[addr + 2] <= write_data[23:16];
      if(byte_en[3]) mem[addr + 3] <= write_data[31:24];
    end
  end

  initial 
  begin
    $readmemh("hex/dmem.hex", mem);  
  end
  
endmodule
/* verilator lint_on UNUSEDSIGNAL */

