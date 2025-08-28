`timescale 1ns/1ps

module register_file 
(
  input logic         clk,
  input logic         rst,

  input logic [4:0]   rs1,
  input logic [4:0]   rs2,
  input logic [4:0]   rd,
  input logic [31:0]  rd_data,
  input logic         rd_enable, 

  output logic [31:0] rs1_data,
  output logic [31:0] rs2_data 
);

  logic [31:0] regs[31:0];

  //output data comb logic
  assign rs1_data = (rs1 == 5'h0) ? 32'h0 : regs[rs1];
  assign rs2_data = (rs2 == 5'h0) ? 32'h0 : regs[rs2];

  //reg file ff
  always_ff @( posedge clk, posedge rst ) begin : reg_file_ff
    if (rst)
    begin
      for (int i = 0; i < 32; i++) 
      begin
        regs[i] <= 0;  
      end
    end
    else if (rd_enable && (rd != 5'h0))
    begin
      regs[rd] <= rd_data;
    end
  end
    
endmodule
