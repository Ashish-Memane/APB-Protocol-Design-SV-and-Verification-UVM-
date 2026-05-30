`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
// 
// Create Date: 18.05.2026 21:43:46
// Design Name: 
// Module Name: apb_uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: TESTBENCH FOR ABP_TOP
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module apb_uart
(
    //--------------------------------------------------
    // APB INTERFACE
    //--------------------------------------------------
    input  logic        PCLK,
    input  logic        PRESETn,

    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,

    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    //--------------------------------------------------
    // UART SERIAL PHYSICAL LINES
    //--------------------------------------------------
    output logic        tx,
    input  logic        rx
);

    //--------------------------------------------------
    // ADDRESS MAP
    //--------------------------------------------------
    localparam TXDATA_ADDR = 32'h0000_0000;
    localparam RXDATA_ADDR = 32'h0000_0004;
    localparam STATUS_ADDR = 32'h0000_0008;

    //--------------------------------------------------
    // REGISTERS
    //--------------------------------------------------
    logic [31:0] tx_reg;
    logic [31:0] rx_reg;
    logic [31:0] status_reg;

    //--------------------------------------------------
    // UART STATES
    //--------------------------------------------------
    typedef enum logic [1:0]
    {
        IDLE,
        START,
        DATA,
        STOP
    } uart_state_t;

    uart_state_t tx_state;
    uart_state_t rx_state;

    //--------------------------------------------------
    // TX / RX LOGIC AND STORAGE LANES
    //--------------------------------------------------
    logic [31:0] tx_shift_32;
    logic [7:0]  tx_shift_8;
    logic [2:0]  bit_count;
    logic [1:0]  byte_count;
    logic        tx_start;

    logic [31:0] rx_shift_32;
    logic [7:0]  rx_shift_8;
    logic [2:0]  rx_bit_count;
    logic [1:0]  rx_byte_count;

    logic        tx_busy_d;

    //--------------------------------------------------
    // DELAYED BUSY REGISTER
    //--------------------------------------------------
    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
            tx_busy_d <= 1'b0;
        else
            tx_busy_d <= status_reg[0];
    end

    //--------------------------------------------------
    // APB WRITE PHASE LATCHING
    //--------------------------------------------------
    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
        begin
            tx_reg   <= 32'h0;
            tx_start <= 1'b0;
        end
        else
        begin
            tx_start <= 1'b0;

            if(PSEL && PENABLE && PWRITE && PREADY)
            begin
                case(PADDR)
                    TXDATA_ADDR:
                    begin
                        tx_reg   <= PWDATA;
                        tx_start <= 1'b1;
                    end
                    default: ; // Do nothing for read-only spaces
                endcase
            end
        end
    end

    //--------------------------------------------------
    // UART TRANSMIT (TX) STATE MACHINE
    //--------------------------------------------------
    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
        begin
            tx            <= 1'b1;
            tx_state      <= IDLE;
            tx_shift_32   <= 32'h0;
            tx_shift_8    <= 8'h00;
            bit_count     <= 3'd0;
            byte_count    <= 2'd0;
            status_reg[0] <= 1'b0;
        end
        else
        begin
            case(tx_state)
                IDLE:
                begin
                    tx <= 1'b1;
                    if(tx_start)
                    begin
                        tx_shift_32   <= tx_reg;
                        tx_shift_8    <= tx_reg[7:0];
                        bit_count     <= 3'd0;
                        byte_count    <= 2'd0;
                        status_reg[0] <= 1'b1;
                        tx_state      <= START;
                    end
                end

                START:
                begin
                    tx       <= 1'b0; // Start bit driven low
                    tx_state <= DATA;
                end

                DATA:
                begin
                    tx         <= tx_shift_8[0];
                    tx_shift_8 <= {1'b0, tx_shift_8[7:1]};

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;
                        tx_state  <= STOP;
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end

                STOP:
                begin
                    tx <= 1'b1; // Stop bit driven high
                    if(byte_count == 2'd3)
                    begin
                        status_reg[0] <= 1'b0; // Clear TX busy flag
                        tx_state      <= IDLE;
                    end
                    else
                    begin
                        byte_count  <= byte_count + 1'b1;
                        tx_shift_32 <= {8'h00, tx_shift_32[31:8]};
                        tx_shift_8  <= tx_shift_32[15:8];
                        tx_state    <= START;
                    end
                end
                
                default: tx_state <= IDLE;
            endcase
        end
    end

    //--------------------------------------------------
    // UART RECEIVE (RX) STATE MACHINE WITH READ CLEANUP
    //--------------------------------------------------
    always_ff @(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
        begin
            rx_state      <= IDLE;
            rx_shift_32   <= 32'h0;
            rx_shift_8    <= 8'h00;
            rx_bit_count  <= 3'd0;
            rx_byte_count <= 2'd0;
            rx_reg        <= 32'h0;
            status_reg[1] <= 1'b0;
            status_reg[31:2] <= 30'h0; // Initialize remainder of the status array
        end
        else
        begin
            // Handshake logic to reset the data valid bit upon an active APB read
            if (PSEL && PENABLE && !PWRITE && (PADDR == RXDATA_ADDR) && PREADY)
            begin
                status_reg[1] <= 1'b0;
            end

            case(rx_state)
                IDLE:
                begin
                    if(rx == 1'b0) // Frame start bit edge detected
                    begin
                        rx_bit_count <= 3'd0;
                        rx_shift_8   <= 8'h00;
                        rx_state     <= DATA;
                    end
                end

                DATA:
                begin
                    rx_shift_8 <= {rx, rx_shift_8[7:1]};

                    if(rx_bit_count == 3'd7)
                    begin
                        rx_bit_count <= 3'd0;
                        rx_state     <= STOP;
                    end
                    else
                        rx_bit_count <= rx_bit_count + 1'b1;
                end

                STOP:
                begin
                    rx_shift_32 <= {rx_shift_8, rx_shift_32[31:8]};

                    if(rx_byte_count == 2'd3)
                    begin
                        rx_reg        <= {rx_shift_8, rx_shift_32[31:8]};
                        status_reg[1] <= 1'b1; // Latch valid flag high until APB read empties it
                        rx_byte_count <= 2'd0;
                    end
                    else
                    begin
                        rx_byte_count <= rx_byte_count + 1'b1;
                    end

                    rx_state <= IDLE;
                end
                
                default: rx_state <= IDLE;
            endcase
        end
    end

    //--------------------------------------------------
    // APB READ COMBINATIONAL MULTIPLEXER
    //--------------------------------------------------
    always_comb
    begin
        PRDATA = 32'h0;

        if(PSEL && !PWRITE)
        begin
            case(PADDR)
                TXDATA_ADDR: PRDATA = tx_reg;
                RXDATA_ADDR: PRDATA = rx_reg;
                STATUS_ADDR: PRDATA = status_reg;
                default:     PRDATA = 32'hDEADBEEF;
            endcase
        end
    end

    //--------------------------------------------------
    // APB READY HANDSHAKE GENERATION
    //--------------------------------------------------
    always_comb
    begin
        PREADY = 1'b1;

        if(PSEL && PENABLE && PWRITE && (PADDR == TXDATA_ADDR) && tx_busy_d)
        begin
            PREADY = 1'b0;
        end
    end

    //--------------------------------------------------
    // APB ERROR EVALUATION
    //--------------------------------------------------
    always_comb
    begin
        PSLVERR = 1'b0;

        if(PSEL && PENABLE)
        begin
            case(PADDR)
                TXDATA_ADDR,
                RXDATA_ADDR,
                STATUS_ADDR: PSLVERR = 1'b0;
                default:     PSLVERR = 1'b1;
            endcase
        end
    end

endmodule
