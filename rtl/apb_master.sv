`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
// 
// Create Date: 19.05.2026 12:25:36
// Design Name: 
// Module Name: apb_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module apb_master
(
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
    output logic        err,

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

    typedef enum logic [1:0]
    {
        IDLE,
        SETUP,
        ACCESS
    } state_t;

    state_t state;

    always_ff @(posedge PCLK or negedge PRESETn)
    begin

        if (!PRESETn)
        begin

            //------------------------------------------
            // RESET OUTPUTS
            //------------------------------------------

            PADDR   <= 32'h0;
            PWDATA  <= 32'h0;

            PWRITE  <= 1'b0;
            PENABLE <= 1'b0;
            PSEL    <= 1'b0;

            rdata   <= 32'h0;

            done    <= 1'b0;
            err     <= 1'b0;

            state   <= IDLE;

        end
        else
        begin

            //------------------------------------------
            // DEFAULTS
            //------------------------------------------

            done <= 1'b0;
            err  <= 1'b0;

            case(state)

                //--------------------------------------
                // IDLE
                //--------------------------------------

                IDLE:
                begin

                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;

                    if(start)
                    begin

                        //----------------------------------
                        // LOAD APB SIGNALS
                        //----------------------------------

                        PADDR  <= addr;
                        PWDATA <= wdata;

                        PWRITE <= rw;

                        //----------------------------------
                        // START SETUP PHASE
                        //----------------------------------

                        PSEL <= 1'b1;

                        state <= SETUP;

                    end

                end

                //--------------------------------------
                // SETUP
                //--------------------------------------

                SETUP:
                begin

                    //----------------------------------
                    // ACCESS PHASE
                    //----------------------------------

                    PENABLE <= 1'b1;

                    state <= ACCESS;

                end

                //--------------------------------------
                // ACCESS
                //--------------------------------------

                ACCESS:
                begin

                    //----------------------------------
                    // WAIT FOR SLAVE READY
                    //----------------------------------

                    if(PREADY)
                    begin

                        //----------------------------------
                        // CAPTURE ERROR
                        //----------------------------------

                        if(PSLVERR)
                        begin

                            err <= 1'b1;
                        end

                        //----------------------------------
                        // READ OPERATION
                        //----------------------------------

                        if(!PWRITE)
                        begin

                            rdata <= PRDATA;

                        end

                        //----------------------------------
                        // TRANSACTION COMPLETE
                        //----------------------------------

                        done <= 1'b1;

                        //----------------------------------
                        // DEASSERT BUS
                        //----------------------------------

                        PSEL    <= 1'b0;
                        PENABLE <= 1'b0;

                        //----------------------------------
                        // RETURN TO IDLE
                        //----------------------------------

                        state <= IDLE;

                    end

                end

            endcase

        end

    end

endmodule


