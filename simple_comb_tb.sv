`timescale 1ns / 1ps

module alu4_tb;

  // ---- DUT signals ----------------------------------------------------
  logic [3:0] a, b;
  logic [2:0] op;
  logic [3:0] result;
  logic       cout;

  // Mirror the DUT's opcode encoding for readable test code.
  logic [2:0] OP_ADD = 3'b000;
  logic [2:0] OP_SUB = 3'b001;
  logic [2:0] OP_AND = 3'b010;
  logic [2:0] OP_OR  = 3'b011;
  logic [2:0] OP_XOR = 3'b100;
  logic [2:0] OP_NOT = 3'b101;
  logic [2:0] OP_SHL = 3'b110;
  logic [2:0] OP_SHR = 3'b111;

  // ---- DUT instance ---------------------------------------------------
  alu4 dut (.*);

  // ---- Reference model -------------------------------------------------
  // A struct lets us return both expected outputs from one function call
  // and compare them as a unit. This is a common verification pattern.
  typedef struct packed{
    logic [3:0] result;
    logic       cout;
  } alu_expected_t;

  function automatic alu_expected_t reference (
    input logic [3:0] a,
    input logic [3:0] b,
    input logic [2:0] op
  );
    logic [4:0] full;
    alu_expected_t exp;
    exp.result = '0;
    exp.cout   = 1'b0;
    unique case (op)
      OP_ADD: begin
        full = {1'b0, a} + {1'b0, b};
        exp.result = full[3:0];
        exp.cout   = full[4];
      end
      OP_SUB: begin
        full = {1'b0, a} - {1'b0, b};
        exp.result = full[3:0];
        exp.cout   = full[4];
      end
      OP_AND: exp.result = a & b;
      OP_OR:  exp.result = a | b;
      OP_XOR: exp.result = a ^ b;
      OP_NOT: exp.result = ~a;
      OP_SHL: begin
        exp.result = {a[2:0], 1'b0};
        exp.cout   = a[3];
      end
      OP_SHR: begin
        exp.result = {1'b0, a[3:1]};
        exp.cout   = a[0];
      end
    endcase
    return exp;
  endfunction


  int errors  = 0;
  int checks  = 0;

  function automatic string op_name(logic [2:0] op);
    unique case (op)
      OP_ADD: return "ADD";
      OP_SUB: return "SUB";
      OP_AND: return "AND";
      OP_OR : return "OR ";
      OP_XOR: return "XOR";
      OP_NOT: return "NOT";
      OP_SHL: return "SHL";
      OP_SHR: return "SHR";
    endcase
  endfunction

  // Apply a single stimulus, wait for combinational settling, and check.
  task automatic check_one(logic [3:0] ta, logic [3:0] tb, logic [2:0] top);
    alu_expected_t exp;
    a  = ta;
    b  = tb;
    op = top;
    // The ALU is purely combinational, but a small delay lets the
    // simulator settle and makes waveforms readable.
    #1;
    exp = reference(ta, tb, top);
    checks++;

    // Two immediate assertions — one per output. Each carries a
    // descriptive failure message including the operands.
    assert (result === exp.result)
      else begin
        $error("[%0t] %s a=%0h b=%0h: result=%0h expected %0h",
               $time, op_name(top), ta, tb, result, exp.result);
        errors++;
      end

    assert (cout === exp.cout)
      else begin
        $error("[%0t] %s a=%0h b=%0h: cout=%0b expected %0b",
               $time, op_name(top), ta, tb, cout, exp.cout);
        errors++;
      end
  endtask

  // ---- Targeted sanity checks -----------------------------------------
  // A small set of hand-picked cases run before the exhaustive sweep.
  // If these fail, the bug is probably basic enough that we shouldn't
  // bother continuing.
  task automatic sanity_checks();
    $display("--- Sanity checks ---");
    check_one(4'h0, 4'h0, OP_ADD);   // 0 + 0 = 0
    check_one(4'hF, 4'h1, OP_ADD);   // 0xF + 1 = 0x0 with carry
    check_one(4'h5, 4'h5, OP_SUB);   // equal -> 0, no borrow
    check_one(4'h3, 4'h7, OP_SUB);   // a < b -> borrow set
    check_one(4'hA, 4'hA, OP_AND);   // x AND x = x
    check_one(4'hA, 4'h5, OP_OR );   // 0xA | 0x5 = 0xF
    check_one(4'hF, 4'hF, OP_XOR);   // x XOR x = 0
    check_one(4'h0, 4'h0, OP_NOT);   // ~0 = 0xF (b ignored)
    check_one(4'h8, 4'h0, OP_SHL);   // 0x8 << 1 = 0x0, cout = 1
    check_one(4'h1, 4'h0, OP_SHR);   // 0x1 >> 1 = 0x0, cout = 1
    if (errors > 0) $fatal(1, "Sanity checks failed; aborting.");
  endtask
  

  // ---- Main test -------------------------------------------------------
  initial begin
    // $monitor would print every change of the listed signals — useful
    // when debugging, but for an exhaustive sweep of 2048 cases it
    // produces too much output. We leave it commented as an example.
    // $monitor("[%0t] op=%s a=%0h b=%0h -> result=%0h cout=%0b",
    //          $time, op_name(op), a, b, result, cout);

    $display("=== ALU exhaustive test ===");
    sanity_checks();

    $display("--- Exhaustive sweep ---");
    for (int oi = 0; oi < 8; oi++) begin
      for (int ai = 0; ai < 16; ai++) begin
        for (int bi = 0; bi < 16; bi++) begin
          check_one(ai[3:0], bi[3:0], oi[2:0]);
        end
      end
    end

    $display("=== Done. %0d checks, %0d errors ===", checks, errors);
    if (errors > 0)
      $fatal(1, "Test FAILED with %0d errors", errors);
    else
      $display("Test PASSED");
    $finish;
  end

  // ---- Watchdog --------------------------------------------------------
  // If something goes catastrophically wrong (infinite loop in stimulus,
  // X propagating into a comparison and hanging things), don't run forever.
  initial begin
    #1_000_000;
    $fatal(1, "Watchdog timeout");
  end

endmodule
