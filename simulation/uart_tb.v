`timescale 1ns/1ps

// Self-checking loopback testbench: TX output feeds RX input.
// Sends three frames of 0xCC and checks every byte.
module uart_tb ();

  // Same clock and baud rate as the hardware design:
  // 12 MHz clock, 115200 baud -> 12,000,000 / 115,200 = 104 clocks per bit
  parameter real    c_CLOCK_PERIOD_NS = 83.333;
  parameter integer c_CLKS_PER_BIT    = 104;
  parameter integer c_NUM_FRAMES      = 3;
  parameter [7:0]   c_TEST_BYTE       = 8'hCC;   // 11001100

  reg        r_Clock   = 0;
  reg        r_Tx_DV   = 0;
  reg  [7:0] r_Tx_Byte = 0;
  wire       w_Tx_Serial, w_Tx_Active, w_Tx_Done;
  wire       w_Rx_DV;
  wire [7:0] w_Rx_Byte;

  integer errors   = 0;   // how many bytes came back wrong
  integer rx_count = 0;   // how many bytes the RX received
  integer i;

  // ---------- The two instances, connected in loopback ----------
  uart_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST (
    .i_Clock     (r_Clock),
    .i_Tx_DV     (r_Tx_DV),
    .i_Tx_Byte   (r_Tx_Byte),
    .o_Tx_Active (w_Tx_Active),
    .o_Tx_Serial (w_Tx_Serial),
    .o_Tx_Done   (w_Tx_Done)
  );

  uart_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST (
    .i_Clock     (r_Clock),
    .i_Rx_Serial (w_Tx_Serial),        // TX line feeds RX input
    .o_Rx_DV     (w_Rx_DV),
    .o_Rx_Byte   (w_Rx_Byte)
  );

  // ---------- 12 MHz clock ----------
  always #(c_CLOCK_PERIOD_NS/2) r_Clock = !r_Clock;

  // ---------- Waveform dump (delete these 2 lines for console only) ----------
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, uart_tb);
  end

  // ---------- Print each bit at the moment the RX samples it ----------
  // 3'b010 is the RX's s_RX_DATA_BITS state
  always @(posedge r_Clock)
    if (UART_RX_INST.r_SM_Main == 3'b010 &&
        UART_RX_INST.r_Clock_Count == c_CLKS_PER_BIT-1)
      $display("%0t ns:    RX bit %0d = %b",
               $time, UART_RX_INST.r_Bit_Index, UART_RX_INST.r_Rx_Data);

  // ---------- Check each byte when the RX says it's valid ----------
  always @(posedge r_Clock)
    if (w_Rx_DV) begin
      rx_count = rx_count + 1;
      if (w_Rx_Byte === r_Tx_Byte)
        $display("%0t ns:  Frame %0d: RX byte = 0x%h (%b)  PASS",
                 $time, rx_count, w_Rx_Byte, w_Rx_Byte);
      else begin
        $display("%0t ns:  Frame %0d: RX byte = 0x%h, expected 0x%h  FAIL",
                 $time, rx_count, w_Rx_Byte, r_Tx_Byte);
        errors = errors + 1;
      end
    end

  // ---------- Task: send one byte through the TX ----------
  task send_byte(input [7:0] b);
    begin
      @(posedge r_Clock);
      r_Tx_DV   <= 1'b1;
      r_Tx_Byte <= b;
      $display("%0t ns: TX sending 0x%h (%b)", $time, b, b);
      @(posedge r_Clock);
      r_Tx_DV   <= 1'b0;
      @(posedge w_Tx_Done);              // wait until the TX is finished
    end
  endtask

  // ---------- Main test ----------
  initial begin
    repeat (2) @(posedge r_Clock);

    for (i = 0; i < c_NUM_FRAMES; i = i + 1)
      send_byte(c_TEST_BYTE);

    repeat (2 * c_CLKS_PER_BIT) @(posedge r_Clock);   // let the last frame finish

    // Final summary
    $display("----------------------------------");
    if (errors == 0 && rx_count == c_NUM_FRAMES)
      $display("ALL TESTS PASSED (%0d frames)", rx_count);
    else
      $display("TEST FAILED: %0d errors, %0d of %0d frames received",
               errors, rx_count, c_NUM_FRAMES);
    $display("----------------------------------");
    $finish;
  end

endmodule