
module apb_gpio_tb ();

  // interface signals
  logic PCLK;
  logic PRESETn;
  logic PSEL;
  logic PENABLE;
  logic PWRITE;

  logic [31:0] PADDR;
  logic [31:0] PWDATA;


  logic [31:0] PRDATA;
  logic PREADY;
  logic PSLVERR;


  // GPIO INTERFACE SIGNALS
  logic [7:0] gpio_in;
  logic [7:0] gpio_out;
  logic [7:0] gpio_dir;



  // module instantiation
  apb_gpio dut (
      .PCLK(PCLK),
      .PRESETn(PRESETn),
      .PSEL(PSEL),
      .PENABLE(PENABLE),
      .PWRITE(PWRITE),
      .PADDR(PADDR),
      .PWDATA(PWDATA),
      .PRDATA(PRDATA),
      .PREADY(PREADY),
      .PSLVERR(PSLVERR),
      .gpio_in(gpio_in),
      .gpio_out(gpio_out),
      .gpio_dir(gpio_dir)
  );

  // clock generation
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;  // 100MHz clock
  end


  // task reset dut
  task reset_dut();

    begin
      PRESETn = 0;

      PSEL    = 0;
      PENABLE = 0;
      PWRITE  = 0;
      PADDR   = 0;
      PWDATA  = 0;

      gpio_in = 0;

      repeat (5) @(posedge PCLK);

      PRESETn = 1;

      $display("[TB] Reset completed");
    end
  endtask

  task apb_write(input [31:0] addr, input [31:0] data);

    begin

      //--------------------------------------------------
      // SETUP PHASE
      //--------------------------------------------------
      @(posedge PCLK);

      PSEL    <= 1;
      PENABLE <= 0;
      PWRITE  <= 1;

      PADDR   <= addr;
      PWDATA  <= data;

      //--------------------------------------------------
      // ACCESS PHASE
      //--------------------------------------------------
      @(posedge PCLK);

      PENABLE <= 1;
      //--------------------------------------------------
      // WAIT FOR READY
      //--------------------------------------------------

      wait (PREADY == 1);
      data = PRDATA;
      @(posedge PCLK);

      //--------------------------------------------------
      // RETURN TO IDLE
      //--------------------------------------------------
      PSEL    <= 0;
      PENABLE <= 0;

      $display("[TB] APB READ ADDR=0x%08h DATA=0x%08h", addr, data);

    end
  endtask

  task apb_read(input [31:0] addr, output [31:0] data);

    begin

      //--------------------------------------------------
      // SETUP PHASE
      //--------------------------------------------------

      @(posedge PCLK);

      PSEL    <= 1;
      PENABLE <= 0;
      PWRITE  <= 0;

      PADDR   <= addr;

      //--------------------------------------------------
      // ACCESS PHASE
      //--------------------------------------------------

      @(posedge PCLK);

      PENABLE <= 1;
      //--------------------------------------------------
      // WAIT FOR READY
      //--------------------------------------------------

      wait (PREADY == 1);

      data = PRDATA;

      @(posedge PCLK);

      //--------------------------------------------------
      // RETURN TO IDLE
      //--------------------------------------------------

      PSEL    <= 0;
      PENABLE <= 0;

      $display("[TB] APB READ ADDR=0x%08h DATA=0x%08h", addr, data);

    end
  endtask

  //==================================================
  // TEST VARIABLES
  //==================================================

  logic [31:0] read_data;

  //==================================================
  // MAIN TEST SEQUENCE
  //==================================================
  initial begin

    //--------------------------------------------------
    // RESET DUT
    //--------------------------------------------------

    reset_dut();

    apb_write(32'h0000_0008, 32'h0000_000F);

    //--------------------------------------------------
    // WRITE GPIO OUTPUT REGISTER
    //--------------------------------------------------

    apb_write(32'h0000_0000, 32'h0000_0005);

    //--------------------------------------------------
    // CHECK GPIO OUTPUTS
    //--------------------------------------------------

    #1;
    if (gpio_out == 8'h05) $display("[PASS] GPIO OUT correct");
    else $display("[FAIL] GPIO OUT incorrect");

    //--------------------------------------------------
    // CHECK GPIO DIRECTION
    //--------------------------------------------------

    if (gpio_oe == 8'h0F) $display("[PASS] GPIO DIR correct");
    else $display("[FAIL] GPIO DIR incorrect");

    //--------------------------------------------------
    // DRIVE GPIO INPUTS
    //--------------------------------------------------

    gpio_in = 8'hA5;

    //--------------------------------------------------
    // READ GPIO INPUT REGISTER
    //--------------------------------------------------

    apb_read(32'h0000_0004, read_data);
    //--------------------------------------------------
    // CHECK INPUT READ
    //--------------------------------------------------

    if (read_data[7:0] == 8'hA5) $display("[PASS] GPIO INPUT READ correct");
    else $display("[FAIL] GPIO INPUT READ incorrect");

    //--------------------------------------------------
    // INVALID ADDRESS TEST
    //--------------------------------------------------

    @(posedge PCLK);

    PSEL    <= 1;
    PENABLE <= 0;
    PWRITE  <= 0;
    PADDR   <= 32'h0000_1000;

    @(posedge PCLK);

    PENABLE <= 1;

    #1;
    if (PSLVERR) $display("[PASS] PSLVERR asserted");
    else $display("[FAIL] PSLVERR not asserted");

    //--------------------------------------------------
    // FINISH SIMULATION
    //--------------------------------------------------

    #20;

    $display("[TB] TEST COMPLETED");

    $finish;

  end

endmodule
