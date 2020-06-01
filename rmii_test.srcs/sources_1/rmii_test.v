module rmii_test(
  input wire clk,
  input wire resetn,
 output wire RMII_CLK_50M,
 output wire RMII_RST_N,
  input wire RMII_CRS_DV,
  input wire RMII_RXD0,
  input wire RMII_RXD1,
  input wire RMII_RXERR,
 output wire RMII_TXEN,
 output wire RMII_TXD0,
 output wire RMII_TXD1,
 output wire RMII_MDC,
  inout wire RMII_MDIO
);

FC1001_RMII u_rmii(
  .Clk          (Clk),
  .Reset        (~resetn),
  .UseDHCP      (1'b0),
  .IP_Addr      ({8'd192, 8'd168, 8'd0, 8'd2}),
  .IP_Ok        (),
  .RMII_CLK_50M (RMII_CLK_50M),
  .RMII_RST_N   (RMII_RST_N),
  .RMII_CRS_DV  (RMII_CRS_DV),
  .RMII_RXD0    (RMII_RXD0),
  .RMII_RXD1    (RMII_RXD1),
  .RMII_RXERR   (RMII_RXERR),
  .RMII_TXEN    (RMII_TXEN),
  .RMII_TXD0    (RMII_TXD0),
  .RMII_TXD1    (RMII_TXD1),
  .RMII_MDC     (RMII_MDC),
  .RMII_MDIO    (RMII_MDIO),

  .UDP0_Reset     (~resetn),
  .UDP0_Service   (16'h0112),
  .UDP0_ServerPort(16'hE001),
  .UDP0_Connected (),
  .UDP0_OutIsEmpty(),
  .UDP0_TxData    (),
  .UDP0_TxValid   (),
  .UDP0_TxReady   (),
  .UDP0_TxLast    (),
  .UDP0_RxData    (),
  .UDP0_RxValid   (),
  .UDP0_RxReady   (),
  .UDP0_RxLast    ()
);
endmodule
