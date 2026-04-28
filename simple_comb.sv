`timescale 1ns / 1ps

module alu4 (
  input  logic [3:0] a,
  input  logic [3:0] b,
  input  logic [2:0] op,
  output logic [3:0] result,
  output logic       cout
);

  logic [2:0] OP_ADD = 3'b000;
  logic [2:0] OP_SUB = 3'b001;
  logic [2:0] OP_AND = 3'b010;
  logic [2:0] OP_OR  = 3'b011;
  logic [2:0] OP_XOR = 3'b100;
  logic [2:0] OP_NOT = 3'b101;
  logic [2:0] OP_SHL = 3'b110;
  logic [2:0] OP_SHR = 3'b111;

  logic [4:0] add_full;
  logic [4:0] sub_full;

  assign add_full = {1'b0, a} + {1'b0, b};
  assign sub_full = {1'b0, a} - {1'b0, b};

  always_comb begin
    result = 4'b0000;
    cout   = 1'b0;

    case (op)
      OP_ADD: begin
        result = add_full[3:0];
        cout   = add_full[4];
      end
      OP_SUB: begin
        result = sub_full[3:0];
        cout   = sub_full[4];   
      end
      OP_AND: result = a & b;
      OP_OR:  result = a | b;
      OP_XOR: result = a ^ b;
      OP_NOT: result = ~a;
      OP_SHL: begin
        result = {a[2:0], 1'b0};
        cout   = a[3];          
      end
      OP_SHR: begin
        result = {1'b0, a[3:1]};
        cout   = a[0]; 
      end
    endcase
  end

endmodule
