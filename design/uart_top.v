`timescale 1ns/1ps
// The LEDs show the lower 4 bits of the last received byte.
module uart_top (
  input        CLK12MHZ,       // 12 MHz board clock
  input        uart_txd_in,    // FROM the PC
  output       uart_rxd_out,   // TO the PC  
  output [3:0] led
);

  localparam CLKS_PER_BIT = 104;   // 12,000,000 / 115,200

  wire       w_Rx_DV;
  wire [7:0] w_Rx_Byte;

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

endmodule