`timescale 1ns/1ps

module eth_top_tb;

reg clk, resetn;
reg        eth_col;
reg        eth_crs;
wire        eth_ref_clk;
wire        eth_rx_clk  ; 
reg        eth_rxdv    ;
reg        eth_rxerr;
wire        eth_tx_clk  ;
reg  [3:0] eth_rx_data ;
wire        eth_tx_en   ;
wire  [3:0] eth_tx_data ;       
wire        eth_rst_n   ;
reg send_en;

assign eth_rx_clk = eth_ref_clk;
assign eth_tx_clk = eth_ref_clk;

eth_top u_eth(
  .clk(clk),
  .resetn(resetn),
  .eth_col(eth_col),
  .eth_crs(eth_crs),
  .eth_ref_clk(eth_ref_clk),
  .eth_rx_clk(eth_rx_clk),
  .eth_rxdv(eth_rxdv),
  .eth_rxerr(eth_rxerr),
  .eth_tx_clk(eth_tx_clk),
  .eth_rx_data(eth_rx_data),
  .eth_tx_en(eth_tx_en),
  .eth_tx_data(eth_tx_data),
  .eth_rst_n(eth_rst_n),
  .done(),
  .send_en(send_en)
);

initial begin
  clk = 0; resetn = 0;
  eth_col = 0; eth_crs = 0; eth_rxdv = 0; eth_rxerr = 0; eth_rx_data = 4'h0;
  send_en = 0;
  #20 resetn = 1;
  #10000 send_en = 1;
  #5000 send_en = 0;
end

always #5 clk = ~clk;

// ff ff ff ff ff ff 00 00 5e 00 fa ce 08 00 45 00 00 36 00 01 40 00 80 11 72 84 c0 a8 03 7b c0 a8 03 66 04 d2 04 d2 00 22 00 00 
// 01 02 03 04 05 06 07 08 09 0a 0b 0c 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e
// 0xDDE5C603
endmodule