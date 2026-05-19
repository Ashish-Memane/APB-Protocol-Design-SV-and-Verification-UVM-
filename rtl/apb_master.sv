//////////////////////////////////////////////////////////////////////////////////
// Company: NA
// Engineer: Ashish Memane
// 
// Create Date: 19.05.2026 12:26:29
// Design Name: 
// Module Name: apb_master
// Project Name: ABP_PROTOCOL_DESIGN
// Target Devices: 
// Tool Versions: VIVADO
// Description: APB_MASTER
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module apb_master (
    input logic PCLK,
    input logic PRESETn,

    //--------------------------------------------------
    // CONTROL INTERFACE
    //--------------------------------------------------

    input logic start,
    input logic rw,

    input logic [31:0] addr,
    input logic [31:0] wdata,

    output logic [31:0] rdata,
    output logic        done,

    //--------------------------------------------------
    // APB BUS
    //--------------------------------------------------

    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,

    output logic PWRITE,
    output logic PENABLE,
    output logic PSEL,

    input logic [31:0] PRDATA,
    input logic        PREADY,
    input logic        PSLVERR
);

  typedef enum logic [1:0] {
    IDLE,
    SETUP,
    ACCESS
  } state_t;

  state_t state;

  always_ff @(posedge PCLK or negedge PRESETn) begin

    if (!PRESETn) begin

      PADDR   <= 0;
      PWDATA  <= 0;

      PWRITE  <= 0;
      PENABLE <= 0;
      PSEL    <= 0;

      rdata   <= 0;
      done    <= 0;

      state   <= IDLE;

    end else begin

      done <= 0;

      case (state)

        //------------------------------------------
        // IDLE
        //------------------------------------------

        IDLE: begin

          PSEL    <= 0;
          PENABLE <= 0;

          if (start) begin

            PADDR  <= addr;
            PWDATA <= wdata;

            PWRITE <= rw;

            PSEL   <= 1'b1;

            state  <= SETUP;

          end

        end

        //------------------------------------------
        // SETUP
        //------------------------------------------

        SETUP: begin

          PENABLE <= 1'b0;

          state   <= ACCESS;

        end

        //------------------------------------------
        // ACCESS
        //------------------------------------------

        ACCESS: begin

          PENABLE <= 1'b1;

          if (PREADY) begin

            if (!PWRITE) rdata <= PRDATA;

            done <= 1'b1;

            PSEL <= 1'b0;
            PENABLE <= 1'b0;

            state <= IDLE;

          end

        end

      endcase

    end

  end

endmodule
