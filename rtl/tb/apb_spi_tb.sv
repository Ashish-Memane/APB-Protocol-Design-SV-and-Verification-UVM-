module tb_apb_spi;

  //==================================================
  // APB SIGNALS
  //==================================================

  logic        PCLK;
  logic        PRESETn;

  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;

  logic [31:0] PADDR;
  logic [31:0] PWDATA;

  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  //==================================================
  // SPI SIGNALS
  //==================================================

  logic        sclk;
  logic        mosi;
  logic        miso;
  logic        cs;

  //==================================================
  // DUT
  //==================================================

  apb_spi dut (
      .PCLK   (PCLK),
      .PRESETn(PRESETn),

      .PSEL   (PSEL),
      .PENABLE(PENABLE),
      .PWRITE (PWRITE),

      .PADDR (PADDR),
      .PWDATA(PWDATA),

      .PRDATA (PRDATA),
      .PREADY (PREADY),
      .PSLVERR(PSLVERR),

      .sclk(sclk),
      .mosi(mosi),
      .miso(miso),
      .cs  (cs)
  );

  //==================================================
  // CLOCK GENERATION
  //==================================================

  initial begin

    PCLK = 0;

    forever #5 PCLK = ~PCLK;

  end

  //==================================================
  // WAVEFORM DUMP
  //==================================================

  initial begin

    $dumpfile("spi_wave.vcd");
    $dumpvars(0, tb_apb_spi);

  end

  //==================================================
  // RESET TASK
  //==================================================

  task reset_dut();

    begin

      PRESETn = 0;

      PSEL    = 0;
      PENABLE = 0;
      PWRITE  = 0;

      PADDR   = 0;
      PWDATA  = 0;

      miso    = 0;

      repeat (5) @(posedge PCLK);

      PRESETn = 1;

      $display("[TB] RESET DONE");

    end
  endtask

  //==================================================
  // APB WRITE TASK
  //==================================================

  task apb_write(input [31:0] addr, input [31:0] data);

    begin

      //--------------------------------------------------
      // SETUP PHASE
      //--------------------------------------------------

      @(posedge PCLK);

      PSEL    <= 1'b1;
      PENABLE <= 1'b0;
      PWRITE  <= 1'b1;

      PADDR   <= addr;
      PWDATA  <= data;

      //--------------------------------------------------
      // ACCESS PHASE
      //--------------------------------------------------

      @(posedge PCLK);

      PENABLE <= 1'b1;

      wait (PREADY);

      @(posedge PCLK);

      //--------------------------------------------------
      // RETURN TO IDLE
      //--------------------------------------------------

      PSEL    <= 1'b0;
      PENABLE <= 1'b0;
      PWRITE  <= 1'b0;

      $display("[TB] WRITE ADDR=0x%08h DATA=0x%08h", addr, data);

    end
  endtask

  //==================================================
  // APB READ TASK
  //==================================================

  task apb_read(input [31:0] addr, output [31:0] data);

    begin

      //--------------------------------------------------
      // SETUP
      //--------------------------------------------------

      @(posedge PCLK);

      PSEL    <= 1'b1;
      PENABLE <= 1'b0;
      PWRITE  <= 1'b0;

      PADDR   <= addr;

      //--------------------------------------------------
      // ACCESS
      //--------------------------------------------------

      @(posedge PCLK);

      PENABLE <= 1'b1;

      wait (PREADY);

      data = PRDATA;

      @(posedge PCLK);

      //--------------------------------------------------
      // IDLE
      //--------------------------------------------------

      PSEL    <= 1'b0;
      PENABLE <= 1'b0;

      $display("[TB] READ ADDR=0x%08h DATA=0x%08h", addr, data);

    end
  endtask

  //==================================================
  // SPI SLAVE MODEL
  //==================================================
  //
  // RETURNS FIXED DATA = 8'h3C
  //
  //==================================================

  logic   [7:0] slave_data;
  integer       bit_ptr;

  initial begin

    slave_data = 8'h3C;
    bit_ptr    = 7;

  end

  always @(negedge sclk) begin

    if (!cs) begin

      miso <= slave_data[bit_ptr];

      if (bit_ptr == 0) bit_ptr <= 7;
      else bit_ptr <= bit_ptr - 1;

    end else begin

      miso <= 1'b0;
      bit_ptr <= 7;

    end
  end

  //==================================================
  // TEST VARIABLES
  //==================================================

  logic [31:0] read_data;

  //==================================================
  // MAIN TEST
  //==================================================

  initial begin

    //--------------------------------------------------
    // RESET
    //--------------------------------------------------

    reset_dut();

    //--------------------------------------------------
    // WRITE TXDATA
    //--------------------------------------------------

    apb_write(32'h0000_0000, 32'h0000_00A5);

    //--------------------------------------------------
    // START SPI TRANSFER
    //--------------------------------------------------

    apb_write(32'h0000_000C, 32'h0000_0001);

    //--------------------------------------------------
    // CHECK BUSY FLAG
    //--------------------------------------------------

    apb_read(32'h0000_0008, read_data);

    if (read_data[0]) $display("[PASS] SPI BUSY SET");
    else $display("[FAIL] SPI BUSY NOT SET");

    //--------------------------------------------------
    // WAIT FOR TRANSFER COMPLETE
    //--------------------------------------------------

    repeat (30) @(posedge PCLK);

    //--------------------------------------------------
    // CHECK TRANSFER DONE
    //--------------------------------------------------

    apb_read(32'h0000_0008, read_data);

    if (read_data[1]) $display("[PASS] TRANSFER DONE");
    else $display("[FAIL] TRANSFER NOT DONE");

    //--------------------------------------------------
    // READ RXDATA
    //--------------------------------------------------

    apb_read(32'h0000_0004, read_data);

    if (read_data[7:0] == 8'h3C) $display("[PASS] RX DATA MATCH");
    else $display("[FAIL] RX DATA MISMATCH");

    //--------------------------------------------------
    // INVALID ADDRESS TEST
    //--------------------------------------------------

    @(posedge PCLK);

    PSEL    <= 1'b1;
    PENABLE <= 1'b0;
    PWRITE  <= 1'b0;

    PADDR   <= 32'h0000_1000;

    @(posedge PCLK);

    PENABLE <= 1'b1;

    #1;

    if (PSLVERR) $display("[PASS] PSLVERR ASSERTED");
    else $display("[FAIL] PSLVERR NOT ASSERTED");

    //--------------------------------------------------
    // FINISH
    //--------------------------------------------------

    #20;

    $display("[TB] TEST COMPLETED");

    $finish;

  end

endmodule
