`timescale 1ns/1ps
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */
module core 
(
  input logic clk,
  input logic rst,
  //imem
  output logic [31:0] iaddr,
  input logic [31:0] instruction,
  //dmem
  output logic read,
  output logic write,
  output logic [3:0] byte_en,
  output logic [31:0] daddr, 
  output logic [31:0] write_data,
  input logic [31:0] read_data,
  
  //custom i/o
  input logic [31:0] pc_start
);

  //register file i/o
  logic [4:0]     rs1;
  logic [4:0]     rs2;
  logic [4:0]     rd;
  logic [31:0]    rd_data;
  logic           rd_enable; 
  logic [31:0]    rs1_data;
  logic [31:0]    rs2_data; 

  register_file reg_file(.*);

  //--------------------
  //FETCH
  logic [31:0]    pc_F;
  logic [31:0]    pcplus4_F;
  logic [31:0]    next_pc_F;
  logic [31:0]    instr_F;

  always_ff @( posedge clk, posedge rst ) 
  begin : PROGRAM_COUNTER_FF
    if (rst)
    begin
      pc_F <= pc_start;
    end
    else
    begin
      pc_F <= next_pc_F;
    end
  end

  always_comb 
  begin : FETCH_COMB
    pcplus4_F = pc_F + 4; //saving pc + 4 to pass down pipeline
    next_pc_F = pcplus4_F; //next_pc will be for muxing
    iaddr = pc_F; //pc gets sent to imem to fetch instr
    instr_F = instruction; //instruction gets passed down pipeline
  end

  //--------------------
  //DECODE
  logic [31:0] pc_D;
  logic [31:0] pcplus4_D;
  logic [31:0] instr_D;
  logic [4:0] rd_D;
  logic [31:0] imm_ext_D;
  logic [31:0] rs1_data_D;
  logic [31:0] rs2_data_D;

  always_ff @( posedge clk, posedge rst ) 
  begin : FETCH_DECODE_PIPE
    if(rst)
    begin
      $display("FETCH/DECODE PIPE RST EMPTY");
    end
    else
    begin
      pc_D <= pc_F;
      pcplus4_D <= pcplus4_F;
      instr_D <= instr_F;
    end
  end

  //control signals
  logic [1:0] imm_type_D;
  logic [2:0] alu_op_D;
  logic alu_src_a_D;
  logic alu_src_b_D;
  logic reg_write_D;
  logic [1:0] result_src_D;

  always_comb 
  begin : CONTROL_UNIT
    imm_type_D = '1; //1 for debug
    alu_src_a_D = 0; //default alu port a will be rs1_data
    alu_src_b_D = 0; //default alu port b should not use imm val
    reg_write_D = 0;
    result_src_D = 0; //default result source is alu result
    alu_op_D = 0; //NOP

    //lui and auipc
    if(instr_D[4:0] == 5'b10111)
    begin
      imm_type_D = 0; //this val is for U type instr
      alu_src_b_D = 1; //enable imm on alu port b
      reg_write_D = 1; //enable register writeback
      result_src_D = 0;
      if(instr_D[6:5] == 2'b01)
      begin
        //lui
        alu_op_D = 1; //COPY_B
      end
      else
      begin
        //auipc
        alu_src_a_D = 1; //enable pc on alu port a
        alu_op_D = 2; //ADD
      end
    end

  end

  always_comb 
  begin : REG_FILE
    //in
    rs1 = instr_D[19:15];
    rs2 = instr_D[24:20];
    rd_D = instr_D[11:7];
    //out
    rs1_data_D = rs1_data;
    rs2_data_D = rs2_data;
  end

  always_comb 
  begin : IMM_EXT
    case (imm_type_D)
      0: imm_ext_D = instr_D[31:12] << 12;
      default: imm_ext_D = '0;
    endcase
  end

  //--------------------
  //EXECUTE
  logic [31:0] pc_E;
  logic [31:0] pcplus4_E;
  logic [4:0] rd_E;
  logic [31:0] imm_ext_E;
  logic [31:0] rs1_data_E;
  logic [31:0] rs2_data_E;
  logic [2:0] alu_op_E;
  logic alu_src_a_E;
  logic alu_src_b_E;
  logic reg_write_E;
  logic [1:0] result_src_E;

  always_ff @( posedge clk, posedge rst ) 
  begin : DECODE_EXECUTE_PIPE
    if(rst)
    begin
      $display("DECODE/EXECUTE PIPE RST EMPTY");
    end
    else
    begin
      pc_E <= pc_D;
      pcplus4_E <= pcplus4_D;
      rd_E <= rd_D;
      imm_ext_E <= imm_ext_D;
      rs1_data_E <= rs1_data_D;
      rs2_data_E <= rs2_data_D;
      alu_op_E <= alu_op_D;
      alu_src_a_E <= alu_src_a_D;
      alu_src_b_E <= alu_src_b_D;
      reg_write_E <= reg_write_D;
      result_src_E <= result_src_D;
    end
  end

  //alu signals
  logic [31:0] alu_res_E;
  logic [31:0] alu_port_a_E;
  logic [31:0] alu_port_b_E;
  logic [31:0] write_data_E;

  always_comb 
  begin : ALU
    //defaults
    alu_res_E = '0;  
    alu_port_a_E = rs1_data_E;
    write_data_E = rs2_data_E;
    alu_port_b_E = write_data_E;
    
    //muxes
    if(alu_src_a_E)
    begin
      alu_port_a_E = pc_E;
    end
    if(alu_src_b_E)
    begin
      alu_port_b_E = imm_ext_E;
    end

    //alu operations
    case (alu_op_E)
      0: alu_res_E = '0; //NOP
      1: alu_res_E = alu_port_b_E; //COPY_B
      2: alu_res_E = alu_port_a_E + alu_port_b_E; //ADD
      default: alu_res_E = '0;
    endcase
  end

  //--------------------
  //MEMORY
  logic [31:0] pcplus4_M;
  logic [4:0] rd_M;
  logic [31:0] write_data_M;
  logic [31:0] alu_res_M;
  logic reg_write_M;
  logic [1:0] result_src_M;

  always_ff @( posedge clk, posedge rst ) 
  begin : EXECUTE_MEMORY_PIPE
    if(rst)
    begin
      $display("EXECUTE/MEMORY PIPE RST EMPTY");
    end
    else
    begin
      pcplus4_M <= pcplus4_E;
      rd_M <= rd_E;
      write_data_M <= write_data_E;
      alu_res_M <= alu_res_E;
      reg_write_M <= reg_write_E;
      result_src_M <= result_src_E;
    end
  end

  //dmem 
  logic [31:0] read_data_M;

  always_comb 
  begin : DMEM
    daddr = alu_res_M; 
    write_data = write_data_M;
    read_data_M = read_data;
    byte_en = 4'hF; //for now lets leave all bytes enabled
  end

  //--------------------
  //WRITEBACK
  logic [31:0] alu_res_W;
  logic [31:0] read_data_W;
  logic [4:0] rd_W;
  logic [31:0] pcplus4_W;
  logic reg_write_W;
  logic [1:0] result_src_W;

  always_ff @( posedge clk, posedge rst ) 
  begin : MEMORY_WRITEBACK_PIPE
    if(rst)
    begin
      $display("MEMORY/WRITEBACK PIPE RST EMPTY");
    end
    else
    begin
      alu_res_W <= alu_res_M;
      read_data_W <= read_data_M;
      rd_W <= rd_M;
      pcplus4_W <= pcplus4_M;
      reg_write_W <= reg_write_M;
      result_src_W <= result_src_M;
    end
  end

  //writeback result
  logic [31:0] result_W;

  always_comb 
  begin : WRITEBACK_MUX
    case (result_src_W)
      0: result_W = alu_res_W;
      1: result_W = read_data_W;
      2: result_W = pcplus4_W;
      default: result_W = '0; 
    endcase

    //write back connections to reg file
    rd_data = result_W;
    rd = rd_W;
    rd_enable = reg_write_W;

  end

endmodule
/* verilator lint_on UNDRIVEN */
/* verilator lint_on UNUSEDSIGNAL */



