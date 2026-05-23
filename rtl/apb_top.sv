//////////////////////////////////////////////////////////////////////////////////
// Company: NA
// Engineer: Ashish Memane
// 
// Create Date: 19.05.2026 12:26:29
// Design Name: 
// Module Name: apb_top
// Project Name: ABP_PROTOCOL_DESIGN
// Target Devices: 
// Tool Versions: VIVADO
// Description: APB_TOP
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module apb_top (

    //==================================================
    // CLOCK / RESET
    //==================================================

    input logic PCLK,
    input logic PRESETn,
    //==================================================
    // MASTER INTERFACE SIGNALS
    //==================================================

    input logic        start,
    input logic        rw,
    input logic [31:0] addr,
    input logic [31:0] wdata,

    // External Outputs
    output logic [31:0] rdata,
    output logic        done,
    output logic        err

);
  //==================================================
  // APB BUS (MASTER → INTERCONNECT)
  //==================================================

  logic [31:0] PADDR;
  logic [31:0] PWDATA;
  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;

  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  //==================================================
  // SLAVE SELECTS (FROM INTERCONNECT)
  //==================================================

  logic        PSEL_GPIO;
  logic        PSEL_UART;
  logic        PSEL_SPI;

  //==================================================
  // SLAVE SIDE SIGNALS
  //==================================================

  logic [31:0] PRDATA_GPIO, PRDATA_UART, PRDATA_SPI;
  logic PREADY_GPIO, PREADY_UART, PREADY_SPI;
  logic PSLVERR_GPIO, PSLVERR_UART, PSLVERR_SPI;


  //==================================================
  // APB MASTER
  //==================================================

  apb_master u_master (
      .PCLK   (PCLK),
      .PRESETn(PRESETn),

      .start(start),
      .rw   (rw),
      .addr (addr),
      .wdata(wdata),
      .rdata(rdata),
      .done (done),
      .err(err),  

      .PADDR  (PADDR),
      .PWDATA (PWDATA),
      .PWRITE (PWRITE),
      .PENABLE(PENABLE),
      .PSEL   (PSEL),

      .PRDATA (PRDATA),
      .PREADY (PREADY),
      .PSLVERR(PSLVERR)
  );

  //==================================================
  // APB INTERCONNECT (DECODER + MUX)
  //==================================================

  apb_interconnect u_interconnect (
      .PADDR  (PADDR),
      .PWDATA (PWDATA),
      .PWRITE (PWRITE),
      .PENABLE(PENABLE),
      .PSEL   (PSEL),

      .PRDATA (PRDATA),
      .PREADY (PREADY),
      .PSLVERR(PSLVERR),

      .PSEL_GPIO   (PSEL_GPIO),
      .PRDATA_GPIO (PRDATA_GPIO),
      .PREADY_GPIO (PREADY_GPIO),
      .PSLVERR_GPIO(PSLVERR_GPIO),

      .PSEL_UART   (PSEL_UART),
      .PRDATA_UART (PRDATA_UART),
      .PREADY_UART (PREADY_UART),
      .PSLVERR_UART(PSLVERR_UART),

      .PSEL_SPI   (PSEL_SPI),
      .PRDATA_SPI (PRDATA_SPI),
      .PREADY_SPI (PREADY_SPI),
      .PSLVERR_SPI(PSLVERR_SPI)
  );

  //==================================================
  // GPIO SLAVE
  //==================================================

  gpio u_gpio (
      .PCLK   (PCLK),
      .PRESETn(PRESETn),

      .PSEL   (PSEL_GPIO),
      .PENABLE(PENABLE),
      .PWRITE (PWRITE),
      .PADDR  (PADDR),
      .PWDATA (PWDATA),

      .PRDATA (PRDATA_GPIO),
      .PREADY (PREADY_GPIO),
      .PSLVERR(PSLVERR_GPIO)
  );

  //==================================================
  // UART SLAVE
  //==================================================

  uart u_uart (
      .PCLK   (PCLK),
      .PRESETn(PRESETn),

      .PSEL   (PSEL_UART),
      .PENABLE(PENABLE),
      .PWRITE (PWRITE),
      .PADDR  (PADDR),
      .PWDATA (PWDATA),

      .PRDATA (PRDATA_UART),
      .PREADY (PREADY_UART),
      .PSLVERR(PSLVERR_UART)
  );

  //==================================================
  // SPI SLAVE
  //==================================================

  spi u_spi (
      .PCLK   (PCLK),
      .PRESETn(PRESETn),

      .PSEL   (PSEL_SPI),
      .PENABLE(PENABLE),
      .PWRITE (PWRITE),
      .PADDR  (PADDR),
      .PWDATA (PWDATA),

      .PRDATA (PRDATA_SPI),
      .PREADY (PREADY_SPI),
      .PSLVERR(PSLVERR_SPI)
  );

endmodule
