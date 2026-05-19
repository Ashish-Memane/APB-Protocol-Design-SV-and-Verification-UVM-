//////////////////////////////////////////////////////////////////////////////////
// Company: NA
// Engineer: Ashish Memane
// 
// Create Date: 19.05.2026 12:26:29
// Design Name: 
// Module Name: apb_master_tb
// Project Name: ABP_PROTOCOL_DESIGN
// Target Devices: 
// Tool Versions: VIVADO
// Description: APB_MASTER (TESTBENCH)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_apb_master;

  //==================================================
  // CLOCK / RESET
  //==================================================

  logic        PCLK;
  logic        PRESETn;

  //==================================================
  // CONTROL INTERFACE
  //==================================================

  logic        start;
  logic        rw;

  logic [31:0] addr;
  logic [31:0] wdata;

  logic [31:0] rdata;

  logic        done;

  //==================================================
  // APB BUS
  //==================================================

  logic [31:0] PADDR;
  logic [31:0] PWDATA;

  logic        PWRITE;
  logic        PENABLE;

  logic        PSEL_GPIO;
  logic        PSEL_UART;
  logic        PSEL_SPI;

  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;

  //==================================================
  // DUT
  //==================================================

  apb_master dut (
      .PCLK   (PCLK),
      .PRESETn(PRESETn),

      .start(start),
      .rw   (rw),

      .addr (addr),
      .wdata(wdata),

      .rdata(rdata),

      .done(done),

      .PADDR (PADDR),
      .PWDATA(PWDATA),

      .PWRITE (PWRITE),
      .PENABLE(PENABLE),

      .PSEL_GPIO(PSEL_GPIO),
      .PSEL_UART(PSEL_UART),
      .PSEL_SPI (PSEL_SPI),

      .PRDATA (PRDATA),
      .PREADY (PREADY),
      .PSLVERR(PSLVERR)
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

    $dumpfile("apb_master.vcd");
    $dumpvars(0, tb_apb_master);

  end

  //==================================================
  // RESET TASK
  //==================================================

  task reset_dut();

    begin

      PRESETn = 0;

      start   = 0;
      rw      = 0;

      addr    = 0;
      wdata   = 0;

      PRDATA  = 0;
      PREADY  = 0;
      PSLVERR = 0;

      repeat (5) @(posedge PCLK);

      PRESETn = 1;

      $display("[TB] RESET DONE");

    end
  endtask

  //==================================================
  // SIMPLE APB SLAVE MODEL
  //==================================================

  initial begin

    forever begin

      @(posedge PCLK);

      //----------------------------------------------
      // DEFAULT
      //----------------------------------------------

      PREADY <= 1'b0;

      //----------------------------------------------
      // ACCESS PHASE RESPONSE
      //----------------------------------------------

      if (PENABLE) begin

        //------------------------------------------
        // READY RESPONSE
        //------------------------------------------

        PREADY <= 1'b1;

        //------------------------------------------
        // READ DATA
        //------------------------------------------

        if (!PWRITE) begin
          PRDATA <= 32'hABCD1234;
        end

      end

    end

  end

  //==================================================
  // WRITE TASK
  //==================================================

  task do_write(input [31:0] wr_addr, input [31:0] wr_data);

    begin

      //--------------------------------------------------
      // START TRANSACTION
      //--------------------------------------------------

      @(posedge PCLK);

      start <= 1'b1;
      rw    <= 1'b1;

      addr  <= wr_addr;
      wdata <= wr_data;

      //--------------------------------------------------
      // REMOVE START
      //--------------------------------------------------

      @(posedge PCLK);

      start <= 1'b0;

      //--------------------------------------------------
      // WAIT FOR DONE
      //--------------------------------------------------

      wait (done);

      @(posedge PCLK);

      $display("[TB] WRITE COMPLETE");

    end
  endtask

  //==================================================
  // READ TASK
  //==================================================

  task do_read(input [31:0] rd_addr);

    begin

      //--------------------------------------------------
      // START TRANSACTION
      //--------------------------------------------------

      @(posedge PCLK);

      start <= 1'b1;
      rw    <= 1'b0;

      addr  <= rd_addr;

      //--------------------------------------------------
      // REMOVE START
      //--------------------------------------------------

      @(posedge PCLK);

      start <= 1'b0;

      //--------------------------------------------------
      // WAIT FOR DONE
      //--------------------------------------------------

      wait (done);

      @(posedge PCLK);

      $display("[TB] READ COMPLETE DATA = 0x%08h", rdata);

    end
  endtask

  //==================================================
  // MONITOR GPIO SELECT
  //==================================================

  initial begin

    forever begin

      @(posedge PCLK);

      if (PSEL_GPIO) begin
        $display("[PASS] GPIO SELECTED");
      end

    end

  end

  //==================================================
  // MONITOR UART SELECT
  //==================================================

  initial begin

    forever begin

      @(posedge PCLK);

      if (PSEL_UART) begin
        $display("[PASS] UART SELECTED");
      end

    end

  end

  //==================================================
  // MONITOR SPI SELECT
  //==================================================

  initial begin

    forever begin

      @(posedge PCLK);

      if (PSEL_SPI) begin
        $display("[PASS] SPI SELECTED");
      end

    end

  end

  //==================================================
  // APB PHASE MONITOR
  //==================================================

  initial begin

    forever begin

      @(posedge PCLK);

      //----------------------------------------------
      // SETUP PHASE
      //----------------------------------------------

      if ((PSEL_GPIO || PSEL_UART || PSEL_SPI) && !PENABLE) begin

        $display("[MONITOR] SETUP PHASE");

      end

      //----------------------------------------------
      // ACCESS PHASE
      //----------------------------------------------

      if ((PSEL_GPIO || PSEL_UART || PSEL_SPI) && PENABLE) begin

        $display("[MONITOR] ACCESS PHASE");

      end

    end

  end

  //==================================================
  // MAIN TEST
  //==================================================

  initial begin

    //--------------------------------------------------
    // RESET
    //--------------------------------------------------

    reset_dut();

    //--------------------------------------------------
    // GPIO WRITE
    //--------------------------------------------------

    do_write(32'h0000_0000, 32'h0000_00AA);

    //--------------------------------------------------
    // UART WRITE
    //--------------------------------------------------

    do_write(32'h0001_0000, 32'h0000_0055);

    //--------------------------------------------------
    // SPI WRITE
    //--------------------------------------------------

    do_write(32'h0002_0000, 32'h0000_00F0);

    //--------------------------------------------------
    // READ TEST
    //--------------------------------------------------

    do_read(32'h0001_0004);

    //--------------------------------------------------
    // CHECK READ DATA
    //--------------------------------------------------

    if (rdata == 32'hABCD1234) $display("[PASS] READ DATA MATCH");
    else $display("[FAIL] READ DATA MISMATCH");

    //--------------------------------------------------
    // FINISH
    //--------------------------------------------------

    #20;

    $display("[TB] TEST COMPLETED");

    $finish;

  end

endmodule
