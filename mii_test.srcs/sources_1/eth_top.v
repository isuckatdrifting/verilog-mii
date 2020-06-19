module eth_top(
  input wire        clk,
  input wire        resetn,
  input wire        eth_col,
  input wire        eth_crs,
 output wire        eth_ref_clk,
  input wire        eth_rx_clk  , 
  input wire        eth_rxdv    ,
  input wire        eth_rxerr,
  input wire        eth_tx_clk  ,
  input wire  [3:0] eth_rx_data ,
 output wire        eth_tx_en   ,
 output wire  [3:0] eth_tx_data ,       
 output wire        eth_rst_n    ,
 output wire        done,
  input wire        send_en
);

/**
 * MMCM, clk = 200M * CLKFBOUT_MULT_F / CLKOUT5_DIVIDE
 */
wire CLKFB_int, CLKOUT5, locked;
// Clocking Primitive
MMCME2_ADV #(
  .BANDWIDTH("HIGH"),        // Jitter programming
  .CLKFBOUT_MULT_F(6.000),          // Multiply value for all CLKOUT
  .CLKFBOUT_PHASE(0.0),           // Phase offset in degrees of CLKFB
  .CLKFBOUT_USE_FINE_PS("FALSE"), // Fine phase shift enable (TRUE/FALSE)
  .CLKIN1_PERIOD(10),            // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
  .CLKOUT5_DIVIDE(24.000),         // Divide amount for CLKOUT5
  .CLKOUT5_DUTY_CYCLE(0.5),       // Duty cycle for CLKOUT5
  .CLKOUT5_PHASE(0.0),            // Phase offset for CLKOUT5
  // .CLKOUT6_DIVIDE(8.000),         // Divide amount for CLKOUT6
  // .CLKOUT6_DUTY_CYCLE(0.5),       // Duty cycle for CLKOUT6
  // .CLKOUT6_PHASE(0.0),            // Phase offset for CLKOUT6
  .CLKOUT5_USE_FINE_PS("FALSE"),  // Fine phase shift enable (TRUE/FALSE)
  .COMPENSATION("ZHOLD"),          // Clock input compensation
  .DIVCLK_DIVIDE(1),              // Master division value
  .STARTUP_WAIT("FALSE")          // Delays DONE until MMCM is locked
  )
MMCME2_ADV_inst (
  .CLKFBOUT     (CLKFB_int),         // 1-bit output: Feedback clock
  .CLKFBOUTB    (),       // 1-bit output: Inverted CLKFBOUT
  .CLKFBSTOPPED (), // 1-bit output: Feedback clock stopped
  .CLKINSTOPPED (), // 1-bit output: Input clock stopped
  .CLKOUT5      (CLKOUT5),           // 1-bit output: CLKOUT5
  // .CLKOUT6      (CLKOUT6),           // 1-bit output: CLKOUT6
  .DO           (),                     // 16-bit output: DRP data output
  .DRDY         (),                 // 1-bit output: DRP ready
  .LOCKED       (locked),             // 1-bit output: LOCK
  .PSDONE       (),             // 1-bit output: Phase shift done
  .CLKFBIN      (CLKFB_int),           // 1-bit input: Feedback clock
  .CLKIN1       (clk),             // 1-bit input: Primary clock
  .CLKIN2       (1'b0),             // 1-bit input: Secondary clock
  .CLKINSEL     (1'b1),         // 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
  .DADDR        (7'h0),               // 7-bit input: DRP address
  .DCLK         (1'b0),                 // 1-bit input: DRP clock
  .DEN          (1'b0),                   // 1-bit input: DRP enable
  .DI           (16'h0),                     // 16-bit input: DRP data input
  .DWE          (1'b0),                   // 1-bit input: DRP write enable
  .PSCLK        (1'b0),               // 1-bit input: Phase shift clock
  .PSEN         (1'b0),                 // 1-bit input: Phase shift enable
  .PSINCDEC     (1'b0),         // 1-bit input: Phase shift increment/decrement
  .PWRDWN       (1'b0),             // 1-bit input: Power-down
  .RST          (1'b0)                    // 1-bit input: Reset
);
// Output buffering
BUFG u_mainclk (
  .O(eth_ref_clk),
  .I(CLKOUT5)
);

wire [12:0] s_axi_araddr;
wire        s_axi_arready;
wire        s_axi_arvalid;
wire [12:0] s_axi_awaddr;
wire        s_axi_awready;
wire        s_axi_awvalid;
wire        s_axi_bready;
wire  [1:0] s_axi_bresp;
wire        s_axi_bvalid;
wire [31:0] s_axi_rdata;
wire        s_axi_rready;
wire [1:0] s_axi_rresp;
wire        s_axi_rvalid;
wire [31:0] s_axi_wdata;
wire        s_axi_wready;
wire  [3:0] s_axi_wstrb;
wire        s_axi_wvalid;

assign s_axi_araddr = 13'h0;
assign s_axi_arvalid = 0;
assign s_axi_rready = 0;

axi_ethernetlite_0 u_eth(
  .s_axi_aclk     (clk),
  .s_axi_aresetn  (resetn & locked),
  .s_axi_araddr   (s_axi_araddr),
  .s_axi_arready  (s_axi_arready),
  .s_axi_arvalid  (s_axi_arvalid),
  .s_axi_awaddr   (s_axi_awaddr),
  .s_axi_awready  (s_axi_awready),
  .s_axi_awvalid  (s_axi_awvalid),
  .s_axi_bready   (s_axi_bready),
  .s_axi_bresp    (s_axi_bresp),
  .s_axi_bvalid   (s_axi_bvalid),
  .s_axi_rdata    (s_axi_rdata),
  .s_axi_rready   (s_axi_rready),
  .s_axi_rresp    (s_axi_rresp),
  .s_axi_rvalid   (s_axi_rvalid),
  .s_axi_wdata    (s_axi_wdata),
  .s_axi_wready   (s_axi_wready),
  .s_axi_wstrb    (s_axi_wstrb),
  .s_axi_wvalid   (s_axi_wvalid),

  .phy_col        (eth_col),
  .phy_crs        (eth_crs),
  .phy_rst_n      (eth_rst_n),
  .phy_rx_clk     (eth_rx_clk),
  .phy_dv         (eth_rxdv),
  .phy_rx_er      (eth_rxerr),
  .phy_rx_data    (eth_rx_data),
  .phy_tx_clk     (eth_tx_clk),
  .phy_tx_en      (eth_tx_en),
  .phy_tx_data    (eth_tx_data),
  .ip2intc_irpt   ()
);
reg atg_en; 
reg [15:0] eth_cnt; 
axi_traffic_gen_0 u_atg(
  .s_axi_aclk(clk),
  .s_axi_aresetn(resetn & locked & atg_en),
  .m_axi_lite_ch1_awaddr(s_axi_awaddr),
  .m_axi_lite_ch1_awprot(),
  .m_axi_lite_ch1_awready(s_axi_awready),
  .m_axi_lite_ch1_awvalid(s_axi_awvalid),
  .m_axi_lite_ch1_bready(s_axi_bready),
  .m_axi_lite_ch1_bresp(s_axi_bresp),
  .m_axi_lite_ch1_bvalid(s_axi_bvalid),
  .m_axi_lite_ch1_wdata(s_axi_wdata),
  .m_axi_lite_ch1_wready(s_axi_wready),
  .m_axi_lite_ch1_wstrb(s_axi_wstrb),
  .m_axi_lite_ch1_wvalid(s_axi_wvalid),
  .done(done),
  .status()
);

localparam EDGE = 1'b1;
reg send_en_reg;
wire send_en_edge;
always @(posedge clk or negedge resetn) begin
  if(!resetn)
    send_en_reg <= ~EDGE;
  else
    send_en_reg <= send_en;
end
assign send_en_edge = EDGE ? send_en & ~send_en_reg : ~send_en & send_en_reg;

always @(posedge clk or negedge resetn) begin
  if(!resetn) begin
    atg_en <= 1;
    eth_cnt <= 0;
  end else begin
    if(send_en_edge) begin
      atg_en <= 0;
    end else begin
      atg_en <= 1;
    end
  end
end 


reg eth_tx_en_ila, eth_rxdv_ila, eth_rst_n_ila;
reg [3:0] eth_tx_data_ila, eth_rx_data_ila;
always @(posedge eth_tx_clk or negedge resetn) begin
  if(!resetn) begin
    eth_tx_en_ila <= 0;
    eth_tx_data_ila <= 4'h0;
    eth_rst_n_ila <= 0;
  end else begin
    eth_tx_en_ila <= eth_tx_en;
    eth_tx_data_ila <= eth_tx_data;
    eth_rst_n_ila <= eth_rst_n;
  end
end

always @(posedge eth_rx_clk or negedge resetn) begin
  if(!resetn) begin
    eth_rxdv_ila <= 0;
    eth_rx_data_ila <= 4'h0;
  end else begin
    eth_rxdv_ila <= eth_rxdv;
    eth_rx_data_ila <= eth_rx_data;
  end
end

ila_0 u_ila(
  .clk(eth_ref_clk),
  .probe0(1'b0),
  .probe1(1'b0),
  .probe2(1'b0),
  .probe3(eth_rxdv_ila),
  .probe4(eth_rx_data_ila),
  .probe5(eth_tx_en_ila),
  .probe6(eth_rst_n_ila),
  .probe7(eth_tx_data_ila),
  .probe8(7'h00),
  .probe9(7'h00)
);

endmodule