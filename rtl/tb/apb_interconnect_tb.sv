module tb_apb_interconnect;

  //==================================================
  // INPUT SIGNALS TO INTERCONNECT
  //==================================================

  logic [31:0] PADDR;
  logic [31:0] PWDATA;

  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;

  //==================================================
  // OUTPUTS FROM INTERCONNECT
  //==================================================

  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  //==================================================
  // GPIO SLAVE SIGNALS
  //==================================================

  logic        PSEL_GPIO;
  logic [31:0] PRDATA_GPIO;
  logic        PREADY_GPIO;
  logic        PSLVERR_GPIO;

  //==================================================
  // UART SLAVE SIGNALS
  //==================================================

  logic        PSEL_UART;
  logic [31:0] PRDATA_UART;
  logic        PREADY_UART;
  logic        PSLVERR_UART;

  //==================================================
  // SPI SLAVE SIGNALS
  //==================================================

  logic        PSEL_SPI;
  logic [31:0] PRDATA_SPI;
  logic        PREADY_SPI;
  logic        PSLVERR_SPI;

  //==================================================
  // DUT
  //==================================================

  apb_interconnect dut (
      .PADDR (PADDR),
      .PWDATA(PWDATA),

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
  // WAVEFORM
  //==================================================

  initial begin

    $dumpfile("apb_interconnect.vcd");
    $dumpvars(0, tb_apb_interconnect);

  end

  //==================================================
  // MAIN TEST
  //==================================================

  initial begin

    //--------------------------------------------------
    // DEFAULT VALUES
    //--------------------------------------------------

    PADDR = 0;
    PWDATA = 0;

    PWRITE = 0;
    PENABLE = 0;
    PSEL = 0;

    PRDATA_GPIO = 32'h0000_00AA;
    PREADY_GPIO = 1'b1;
    PSLVERR_GPIO = 1'b0;

    PRDATA_UART = 32'h0000_0055;
    PREADY_UART = 1'b1;
    PSLVERR_UART = 1'b0;

    PRDATA_SPI = 32'h0000_00F0;
    PREADY_SPI = 1'b1;
    PSLVERR_SPI = 1'b0;

    #10;

    //--------------------------------------------------
    // GPIO TEST
    //--------------------------------------------------

    PSEL  = 1'b1;
    PADDR = 32'h0000_0000;

    #5;

    if (PSEL_GPIO) $display("[PASS] GPIO SELECTED");
    else $display("[FAIL] GPIO NOT SELECTED");

    if (PRDATA == 32'h0000_00AA) $display("[PASS] GPIO PRDATA MATCH");
    else $display("[FAIL] GPIO PRDATA MISMATCH");

    //--------------------------------------------------
    // UART TEST
    //--------------------------------------------------

    PADDR = 32'h0001_0000;

    #5;

    if (PSEL_UART) $display("[PASS] UART SELECTED");
    else $display("[FAIL] UART NOT SELECTED");

    if (PRDATA == 32'h0000_0055) $display("[PASS] UART PRDATA MATCH");
    else $display("[FAIL] UART PRDATA MISMATCH");

    //--------------------------------------------------
    // SPI TEST
    //--------------------------------------------------

    PADDR = 32'h0002_0000;

    #5;

    if (PSEL_SPI) $display("[PASS] SPI SELECTED");
    else $display("[FAIL] SPI NOT SELECTED");

    if (PRDATA == 32'h0000_00F0) $display("[PASS] SPI PRDATA MATCH");
    else $display("[FAIL] SPI PRDATA MISMATCH");

    //--------------------------------------------------
    // INVALID ADDRESS TEST
    //--------------------------------------------------

    PADDR = 32'h9999_0000;

    #5;

    if (PSLVERR) $display("[PASS] INVALID ADDRESS PSLVERR ASSERTED");
    else $display("[FAIL] INVALID ADDRESS PSLVERR NOT ASSERTED");

    //--------------------------------------------------
    // TEST COMPLETE
    //--------------------------------------------------

    #10;

    $display("[TB] TEST COMPLETED");

    $finish;

  end

endmodule
