`timescale 1ns/1ps

// Unit test for fifo.v: tests the FIFO on its own, before connecting it to the UART.
// Uses DEPTH = 4 so it's quick to fill.
module fifo_tb;

  reg        clk     = 0;
  reg        wr_en   = 0;
  reg        rd_en   = 0;
  reg  [7:0] wr_data = 0;
  wire [7:0] rd_data;
  wire       empty, full;
  integer    errors  = 0;

  always #5 clk = ~clk;                      // any clock works for a unit test

  fifo #(.WIDTH(8), .DEPTH(4)) DUT (         // override DEPTH: only 4 slots
    .i_Clk     (clk),
    .i_Wr_En   (wr_en),
    .i_Wr_Data (wr_data),
    .i_Rd_En   (rd_en),
    .o_Rd_Data (rd_data),
    .o_Empty   (empty),
    .o_Full    (full)
  );

  // ---------- print PASS or FAIL ----------
  task check(input ok, input [8*48-1:0] what);
    begin
      if (ok) $display("PASS: %0s", what);
      else begin
        $display("FAIL: %0s", what);
        errors = errors + 1;
      end
    end
  endtask

  // ---------- RX side: write one byte ----------
  task push(input [7:0] d);
    begin
      @(negedge clk); wr_en = 1; wr_data = d;   // set inputs between clock edges
      @(negedge clk); wr_en = 0;                // the rising edge in between did the write
    end
  endtask

  // ---------- TX side: check the front byte, then read it ----------
  task pop(input [7:0] expected);
    begin
      @(negedge clk);
      if (rd_data !== expected) begin
        $display("FAIL: front byte is %h, expected %h", rd_data, expected);
        errors = errors + 1;
      end
      rd_en = 1;
      @(negedge clk); rd_en = 0;
    end
  endtask

  // ---------- write and read in the SAME clock ----------
  task push_pop(input [7:0] d);
    begin
      @(negedge clk); wr_en = 1; rd_en = 1; wr_data = d;
      @(negedge clk); wr_en = 0; rd_en = 0;
    end
  endtask

  initial begin
    #1;
    check(empty == 1 && full == 0, "starts empty");

    // Test 1: first in, first out
    push(8'hA1); push(8'hA2); push(8'hA3);
    check(DUT.r_Count == 3, "count = 3 after 3 writes");
    pop(8'hA1); pop(8'hA2); pop(8'hA3);      // must come out in the same order
    check(empty == 1, "empty after reading all 3");

    // Test 2: fill it up, then try one more write
    push(8'h10); push(8'h11); push(8'h12); push(8'h13);
    check(full == 1, "full after 4 writes");
    push(8'hEE);                              // FIFO is full: must be refused
    check(DUT.r_Count == 4, "write when full is refused");
    pop(8'h10); pop(8'h11); pop(8'h12); pop(8'h13);   // EE must NOT appear
    check(empty == 1, "empty after reading all 4");

    // Test 3: read when empty
    @(negedge clk); rd_en = 1;
    @(negedge clk); rd_en = 0;
    check(empty == 1 && DUT.r_Count == 0, "read when empty is refused");

    // Test 4: write and read in the same clock
    push(8'h55);                              // 1 byte inside
    push_pop(8'h66);                          // 55 out, 66 in, same clock
    check(DUT.r_Count == 1, "write + read same clock: count unchanged");
    pop(8'h66);
    check(empty == 1, "empty at the end");

    $display("----------------------------------");
    if (errors == 0) $display("ALL FIFO TESTS PASSED");
    else             $display("%0d ERRORS", errors);
    $display("----------------------------------");
    $finish;
  end

endmodule