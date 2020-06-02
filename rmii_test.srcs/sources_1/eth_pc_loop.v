module eth_pc_loop(
    input              clk,
    input              sys_rst_n   ,    //系统复位信号，低电平有效 
    //以太网接口   
    output             eth_ref_clk,
    input              eth_rx_clk  ,    //MII接收数据时钟
    input              eth_rxdv    ,    //MII输入数据有效信号
    input              eth_tx_clk  ,    //MII发送数据时钟
    input       [3:0]  eth_rx_data ,    //MII输入数据
    output             eth_tx_en   ,    //MII输出数据有效信号
    output      [3:0]  eth_tx_data ,    //MII输出数据          
    output             eth_rst_n        //以太网芯片复位信号，低电平有效   
    );

/**
 * MMCM, clk = 200M * CLKFBOUT_MULT_F / CLKOUT5_DIVIDE
 */
wire clk_buf, CLKFB_int, CLKOUT5, usbclk;
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
  .LOCKED       (),             // 1-bit output: LOCK
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

// // Output buffering
// BUFG u_usbclk (
//   .O(usbclk),
//   .I(CLKOUT6)
// );
//parameter define
//开发板MAC地址 00-11-22-33-44-55
parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
//开发板IP地址 192.168.1.123       
parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd123};  
//目的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;    
//目的IP地址 192.168.1.102     
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};  

//wire define
wire            rec_pkt_done;           //以太网单包数据接收完成信号
wire            rec_en      ;           //以太网接收的数据使能信号
wire   [31:0]   rec_data    ;           //以太网接收的数据
wire   [15:0]   rec_byte_num;           //以太网接收的有效字节数 单位:byte 
wire            tx_done     ;           //以太网发送完成信号
wire            tx_req      ;           //读数据请求信号  

wire            tx_start_en ;           //以太网开始发送信号
wire   [31:0]   tx_data     ;           //以太网待发送数据 

//*****************************************************
//**                    main code
//*****************************************************

//UDP模块
udp                                     //参数例化        
   #(
    .BOARD_MAC       (BOARD_MAC),
    .BOARD_IP        (BOARD_IP ),
    .DES_MAC         (DES_MAC  ),
    .DES_IP          (DES_IP   )
    )
   u_udp(
    .eth_rx_clk      (eth_rx_clk  ),           
    .rst_n           (sys_rst_n   ),       
    .eth_rxdv        (eth_rxdv    ),         
    .eth_rx_data     (eth_rx_data ),                   
    .eth_tx_clk      (eth_tx_clk  ),           
    .tx_start_en     (tx_start_en ),        
    .tx_data         (tx_data     ),         
    .tx_byte_num     (rec_byte_num),    
    .tx_done         (tx_done     ),        
    .tx_req          (tx_req      ),          
    .rec_pkt_done    (rec_pkt_done),    
    .rec_en          (rec_en      ),     
    .rec_data        (rec_data    ),         
    .rec_byte_num    (rec_byte_num),            
    .eth_tx_en       (eth_tx_en   ),         
    .eth_tx_data     (eth_tx_data ),             
    .eth_rst_n       (eth_rst_n   )     
    ); 

//脉冲信号同步处理模块
pulse_sync_pro u_pulse_sync_pro(
    .clk_a          (eth_rx_clk),
    .rst_n          (sys_rst_n),
    .pulse_a        (rec_pkt_done),
    .clk_b          (eth_tx_clk),
    .pulse_b        (tx_start_en)
    );

//fifo模块，用于缓存单包数据
// async_fifo_2048x32b u_fifo_2048x32b(
//     .aclr        (~sys_rst_n),
//     .data        (rec_data  ),          //fifo写数据
//     .rdclk       (eth_tx_clk),
//     .rdreq       (tx_req    ),          //fifo读使能 
//     .wrclk       (eth_rx_clk),          
//     .wrreq       (rec_en    ),          //fifo写使能
//     .q           (tx_data   ),          //fifo读数据 
//     .rdempty     (),
//     .wrfull      ()
//     );
xpm_fifo_async #(
      .CDC_SYNC_STAGES(2),       // DECIMAL
      .DOUT_RESET_VALUE("0"),    // String
      .ECC_MODE("no_ecc"),       // String
      .FIFO_MEMORY_TYPE("auto"), // String
      .FIFO_READ_LATENCY(1),     // DECIMAL
      .FIFO_WRITE_DEPTH(2048),   // DECIMAL
      .FULL_RESET_VALUE(0),      // DECIMAL
      .PROG_EMPTY_THRESH(10),    // DECIMAL
      .PROG_FULL_THRESH(10),     // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
      .READ_DATA_WIDTH(32),      // DECIMAL
      .READ_MODE("std"),         // String
      .RELATED_CLOCKS(0),        // DECIMAL
      .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_ADV_FEATURES("0707"), // String
      .WAKEUP_TIME(0),           // DECIMAL
      .WRITE_DATA_WIDTH(32),     // DECIMAL
      .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
   xpm_fifo_async_inst (
      .almost_empty(),
      .almost_full(),
      .data_valid(), 
      .dbiterr(),
      .dout(tx_data),
      .empty(),
      .full(),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(),
      .sbiterr(),
      .underflow(),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(),
      .din(rec_data),
      .injectdbiterr(), 
      .injectsbiterr(),
      .rd_clk(eth_tx_clk),
      .rd_en(tx_req), 
      .rst(~sys_rst_n),
      .sleep(1'b0),
      .wr_clk(eth_rx_clk),
      .wr_en(rec_en)
   );

ila_0 u_ila(
  .clk(eth_ref_clk),
  .probe0(rec_en),
  .probe1(tx_req),
  .probe2(eth_rxdv),
  .probe3(rec_pkt_done),
  .probe4(eth_rx_data),
  .probe5(eth_tx_en),
  .probe6(eth_tx_data),
  .probe7(eth_rst_n),
  .probe8(u_udp.u_ip_receive.next_state),
  .probe9(u_udp.u_ip_receive.cur_state)
);

endmodule