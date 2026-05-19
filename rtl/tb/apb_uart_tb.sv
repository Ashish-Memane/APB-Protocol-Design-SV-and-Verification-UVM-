module tb_apb_uart;

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
  // UART SIGNALS
  //==================================================

  logic        tx;
  logic        rx;

  //==================================================
  // DUT
  //==================================================

  apb_uart dut (
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

      .tx(tx),
      .rx(rx)
  );

  //==================================================
  // CLOCK GENERATION
  //==================================================

  initial begin

    PCLK = 0;

    forever #5 PCLK = ~PCLK;

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

      rx      = 1'b1;

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

      //--------------------------------------------------
      // WAIT READY
      //--------------------------------------------------

      wait (PREADY == 1'b1);

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
      // SETUP PHASE
      //--------------------------------------------------

      @(posedge PCLK);

      PSEL    <= 1'b1;
      PENABLE <= 1'b0;
      PWRITE  <= 1'b0;

      PADDR   <= addr;

      //--------------------------------------------------
      // ACCESS PHASE
      //--------------------------------------------------

      @(posedge PCLK);

      PENABLE <= 1'b1;

      //--------------------------------------------------
      // WAIT READY
      //--------------------------------------------------

      wait (PREADY == 1'b1);

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
  // UART SEND BYTE TASK
  //==================================================
  //
  // SEND UART FRAME:
  // START + 8 DATA + STOP
  //
  //==================================================

  task uart_send_byte(input [7:0] data);

    integer i;

    begin

      //--------------------------------------------------
      // IDLE
      //--------------------------------------------------

      rx = 1'b1;

      @(posedge PCLK);

      //--------------------------------------------------
      // START BIT
      //--------------------------------------------------

      rx = 1'b0;

      @(posedge PCLK);

      //--------------------------------------------------
      // DATA BITS
      //--------------------------------------------------

      for (i = 0; i < 8; i++) begin

        rx = data[i];

        @(posedge PCLK);

      end

      //--------------------------------------------------
      // STOP BIT
      //--------------------------------------------------

      rx = 1'b1;

      @(posedge PCLK);

      $display("[TB] UART BYTE SENT = 0x%02h", data);

    end
  endtask

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
    // APB WRITE TXDATA
    //--------------------------------------------------

    apb_write(32'h0000_0000, 32'h0000_00A5);

    //--------------------------------------------------
    // READ STATUS REGISTER
    //--------------------------------------------------

    apb_read(32'h0000_0008, read_data);

    if (read_data[0]) $display("[PASS] TX BUSY SET");
    else $display("[FAIL] TX BUSY NOT SET");

    //--------------------------------------------------
    // WAIT TX COMPLETE
    //--------------------------------------------------

    repeat (15) @(posedge PCLK);

    apb_read(32'h0000_0008, read_data);

    if (!read_data[0]) $display("[PASS] TX BUSY CLEARED");
    else $display("[FAIL] TX BUSY STILL SET");

    //--------------------------------------------------
    // SEND UART BYTE TO DUT
    //--------------------------------------------------

    uart_send_byte(8'h3C);

    //--------------------------------------------------
    // WAIT RECEIVE COMPLETE
    //--------------------------------------------------

    repeat (5) @(posedge PCLK);

    //--------------------------------------------------
    // READ STATUS REGISTER
    //--------------------------------------------------

    apb_read(32'h0000_0008, read_data);

    if (read_data[1]) $display("[PASS] RX VALID SET");
    else $display("[FAIL] RX VALID NOT SET");

    //--------------------------------------------------
    // READ RXDATA REGISTER
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
