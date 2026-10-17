`timescale 1ns/1ps

// Burst testbench: the "PC" sends N bytes back to back into uart_top
// and checks every echo that comes back (count AND value).
module uart_burst_tb;

  localparam real    CLK_PERIOD = 83.333;           // 12 MHz board clock
  localparam real    BIT_PERIOD = 1e9 / 115200.0;   // PCs bit time, in ns
  localparam integer N = 8;                         // bytes in the burst

  reg        clk   = 0;
  reg        pc_tx = 1;          // PC to FPGA line (idles high)
  wire       pc_rx;              // FPGA to PC line
  wire [3:0] led;
  wire [1:0] ja;

  integer    rx_count  = 0;      // echoes received
  integer    errors    = 0;      // echoes with the wrong value
  integer    max_count = 0;      // most bytes ever waiting in the FIFO
  reg  [7:0] echo;

  uart_top DUT (
    .CLK12MHZ     (clk),
    .uart_txd_in  (pc_tx),
    .uart_rxd_out (pc_rx),
    .led          (led),
    .ja           (ja)
  );

  always #(CLK_PERIOD/2) clk = ~clk;

  // ---------- PC sends one byte (start, 8 data bits LSB first, stop) ----------
  task pc_send(input [7:0] d);
    integer k;
    begin
      pc_tx = 1'b0;                 #(BIT_PERIOD);   // start bit
      for (k = 0; k < 8; k = k + 1) begin
        pc_tx = d[k];               #(BIT_PERIOD);   // data bits
      end
      pc_tx = 1'b1;                 #(BIT_PERIOD);   // stop bit
    end
  endtask

  // ---------- PC receives one byte from the FPGA ----------
  task pc_receive(output [7:0] d);
    integer k;
    begin
      @(negedge pc_rx);             // wait for a start bit
      #(BIT_PERIOD/2);              // middle of the start bit
      for (k = 0; k < 8; k = k + 1) begin
        #(BIT_PERIOD);              // middle of the next data bit
        d[k] = pc_rx;
      end
      #(BIT_PERIOD);                // middle of the stop bit
    end
  endtask

  // ---------- Watch the FIFO: remember the highest count ----------
  always @(posedge clk)
    if (DUT.FIFO_INST.r_Count > max_count)
      max_count = DUT.FIFO_INST.r_Count;

  // ---------- Process 1: send N bytes back to back (0x00, 0x01, ...) ----------
  integer i;
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, uart_burst_tb);
    #1000;
    for (i = 0; i < N; i = i + 1)
      pc_send(i);                   // no gap between bytes
  end

  // ---------- Process 2: listen to every echo and check its value ----------
  initial begin
    forever begin
      pc_receive(echo);
      if (echo !== rx_count[7:0]) begin           // echo k must be byte k
        $display("%0t ps: echo %0d = 0x%h  WRONG, expected 0x%h",
                 $time, rx_count + 1, echo, rx_count[7:0]);
        errors = errors + 1;
      end
      else
        $display("%0t ps: echo %0d = 0x%h", $time, rx_count + 1, echo);
      rx_count = rx_count + 1;
    end
  end

  // ---------- Process 3: stop after enough time, then report ----------
  initial begin
    #(BIT_PERIOD * 10 * (N + 3));
    $display("----------------------------------");
    $display("Sent %0d bytes back to back, received %0d echoes, %0d wrong", N, rx_count, errors);
    $display("Most bytes waiting in the FIFO at once: %0d", max_count);
    if (rx_count == N && errors == 0) $display("BURST TEST PASSED");
    else                              $display("BURST TEST FAILED");
    $display("----------------------------------");
    $finish;
  end

endmodule