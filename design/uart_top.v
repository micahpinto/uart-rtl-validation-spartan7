`timescale 1ns/1ps

// Echo test: every byte received from the PC is sent straight back.
// The LEDs show the lower 4 bits of the last received byte.
// Both UART lines are mirrored onto Pmod JA for the logic analyzer.
// Signals marked mark_debug are kept for the Vivado ILA.
module uart_top (
  input        CLK12MHZ,                                // 12 MHz board clock
  (* mark_debug = "true" *) input  uart_txd_in,         // ILA: PC to FPGA line
  (* mark_debug = "true" *) output uart_rxd_out,        // ILA: FPGA to PC line
  output [3:0] led,
  output [1:0] ja                                       // copies of the UART lines, for the logic analyzer
);

  localparam CLKS_PER_BIT = 104;   // 12,000,000 / 115,200

  (* mark_debug = "true" *) wire       w_Rx_DV;          // ILA: RX's "byte ready" pulse
  (* mark_debug = "true" *) wire [7:0] w_Rx_Byte;        // ILA: the received byte

  uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_RX_INST (
    .i_Clock     (CLK12MHZ),
    .i_Rx_Serial (uart_txd_in),
    .o_Rx_DV     (w_Rx_DV),
    .o_Rx_Byte   (w_Rx_Byte)
  );

  uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_TX_INST (
    .i_Clock     (CLK12MHZ),
    .i_Tx_DV     (w_Rx_DV),
    .i_Tx_Byte   (w_Rx_Byte),
    .o_Tx_Active (),
    .o_Tx_Serial (uart_rxd_out),
    .o_Tx_Done   ()
  );

  reg [3:0] r_Led = 4'b0000;
  always @(posedge CLK12MHZ)
    if (w_Rx_DV)
      r_Led <= w_Rx_Byte[3:0];

  assign led = r_Led;

  // Mirror both UART lines onto Pmod JA for the logic analyzer
  assign ja[0] = uart_txd_in;    // PC to FPGA (bytes going in)
  assign ja[1] = uart_rxd_out;   // FPGA to PC (echo coming back)

endmodule