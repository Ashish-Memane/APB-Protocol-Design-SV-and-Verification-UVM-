//////////////////////////////////////////////////////////////////////////////////
// Company: NA
// Engineer: Ashish Memane
// 
// Create Date: 19.05.2026 12:26:29
// Design Name: 
// Module Name: apb_uart
// Project Name: ABP_PROTOCOL_DESIGN
// Target Devices: 
// Tool Versions: VIVADO
// Description: APB_UART
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module apb_uart (
    //==================================================
    // APB INTERFACE
    //==================================================

    input logic PCLK,
    input logic PRESETn,

    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,

    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    //==================================================
    // UART INTERFACE
    //==================================================

    output logic tx,
    input  logic rx
);

  //==================================================
  // REGISTER MAP
  //==================================================

  localparam TXDATA_ADDR = 32'h0000_0000;
  localparam RXDATA_ADDR = 32'h0000_0004;
  localparam STATUS_ADDR = 32'h0000_0008;

  //==================================================
  // INTERNAL REGISTERS
  //==================================================

  logic [31:0] tx_reg;
  logic [31:0] rx_reg;
  logic [31:0] status_reg;

  //--------------------------------------------------
  // STATUS REGISTER BITS
  //--------------------------------------------------
  //
  // status_reg[0] = tx_busy
  // status_reg[1] = rx_valid
  //
  //--------------------------------------------------

  //==================================================
  // UART RX LOGIC
  //==================================================

  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } uart_state_t;

  uart_state_t rx_state;

  logic [7:0] rx_shift_reg;
  logic [2:0] rx_bit_count;

  //==================================================
  // UART TX LOGIC
  //==================================================

  logic [7:0] tx_shift_reg;
  logic [2:0] tx_bit_count;

  uart_state_t tx_state;

  //==================================================
  // APB WRITE LOGIC
  //==================================================

  always_ff @(posedge PCLK or negedge PRESETn) begin

    if (!PRESETn) begin

      tx_reg       <= 32'h0;
      status_reg   <= 32'h0;

      tx_state     <= IDLE;
      tx_shift_reg <= 8'h00;
      tx_bit_count <= 3'd0;

    end else begin

      //--------------------------------------------------
      // APB WRITE
      //--------------------------------------------------

      if (PSEL && PENABLE && PWRITE) begin

        case (PADDR)

          //------------------------------------------
          // TXDATA REGISTER
          //------------------------------------------

          TXDATA_ADDR: begin

            tx_reg <= PWDATA;

            //--------------------------------------
            // LOAD TX SHIFT REGISTER
            //--------------------------------------

            tx_shift_reg <= PWDATA[7:0];

            //--------------------------------------
            // START TX
            //--------------------------------------

            tx_state <= START;

            //--------------------------------------
            // TX BUSY
            //--------------------------------------

            status_reg[0] <= 1'b1;

          end

          default: begin
            // Do nothing
          end

        endcase
      end

      //--------------------------------------------------
      // UART TX FSM
      //--------------------------------------------------

      case (tx_state)

        //----------------------------------------------
        // IDLE
        //----------------------------------------------

        IDLE: begin
          tx <= 1'b1;
        end

        //----------------------------------------------
        // START BIT
        //----------------------------------------------

        START: begin

          tx <= 1'b0;

          tx_bit_count <= 3'd0;

          tx_state <= DATA;

        end

        //----------------------------------------------
        // DATA BITS
        //----------------------------------------------

        DATA: begin

          tx <= tx_shift_reg[0];

          tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};

          if (tx_bit_count == 3'd7) begin
            tx_state <= STOP;
          end else begin
            tx_bit_count <= tx_bit_count + 1;
          end

        end

        //----------------------------------------------
        // STOP BIT
        //----------------------------------------------

        STOP: begin

          tx <= 1'b1;

          tx_state <= IDLE;

          //------------------------------------------
          // CLEAR TX BUSY
          //------------------------------------------

          status_reg[0] <= 1'b0;

        end

      endcase

    end
  end

  //==================================================
  // UART RX FSM
  //==================================================

  always_ff @(posedge PCLK or negedge PRESETn) begin

    if (!PRESETn) begin

      rx_state     <= IDLE;
      rx_shift_reg <= 8'h00;
      rx_bit_count <= 3'd0;

      rx_reg       <= 32'h0;

    end else begin

      case (rx_state)

        //----------------------------------------------
        // IDLE
        //----------------------------------------------

        IDLE: begin

          //------------------------------------------
          // DETECT START BIT
          //------------------------------------------

          if (rx == 1'b0) begin
            rx_state <= START;
          end

        end

        //----------------------------------------------
        // START STATE
        //----------------------------------------------

        START: begin

          rx_bit_count <= 3'd0;

          rx_state <= DATA;

        end

        //----------------------------------------------
        // RECEIVE DATA
        //----------------------------------------------

        DATA: begin

          //------------------------------------------
          // SHIFT IN RX BIT
          //------------------------------------------

          rx_shift_reg <= {rx, rx_shift_reg[7:1]};

          //------------------------------------------
          // BIT COUNTER
          //------------------------------------------

          if (rx_bit_count == 3'd7) begin
            rx_state <= STOP;
          end else begin
            rx_bit_count <= rx_bit_count + 1;
          end

        end

        //----------------------------------------------
        // STOP BIT
        //----------------------------------------------

        STOP: begin

          //------------------------------------------
          // STORE RECEIVED BYTE
          //------------------------------------------

          rx_reg[7:0] <= rx_shift_reg;

          //------------------------------------------
          // RX VALID
          //------------------------------------------

          status_reg[1] <= 1'b1;

          rx_state <= IDLE;

        end

      endcase

    end
  end

  //==================================================
  // APB READ LOGIC
  //==================================================

  always_comb begin

    PRDATA = 32'h00000000;

    if (PSEL && !PWRITE) begin

      case (PADDR)

        //----------------------------------------------
        // TXDATA
        //----------------------------------------------

        TXDATA_ADDR: begin
          PRDATA = tx_reg;
        end

        //----------------------------------------------
        // RXDATA
        //----------------------------------------------

        RXDATA_ADDR: begin
          PRDATA = rx_reg;
        end

        //----------------------------------------------
        // STATUS
        //----------------------------------------------

        STATUS_ADDR: begin
          PRDATA = status_reg;
        end

        //----------------------------------------------
        // INVALID
        //----------------------------------------------

        default: begin
          PRDATA = 32'hDEADBEEF;
        end

      endcase
    end
  end

  //==================================================
  // APB READY
  //==================================================

  assign PREADY = 1'b1;

  //==================================================
  // APB ERROR
  //==================================================

  always_comb begin

    PSLVERR = 1'b0;

    if (PSEL && PENABLE) begin

      case (PADDR)

        TXDATA_ADDR, RXDATA_ADDR, STATUS_ADDR: begin
          PSLVERR = 1'b0;
        end

        default: begin
          PSLVERR = 1'b1;
        end

      endcase
    end
  end

endmodule
