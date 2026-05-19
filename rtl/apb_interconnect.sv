module apb_interconnect
(
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,

    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,

    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    output logic        PSEL_GPIO,
    input  logic [31:0] PRDATA_GPIO,
    input  logic        PREADY_GPIO,
    input  logic        PSLVERR_GPIO,

    output logic        PSEL_UART,
    input  logic [31:0] PRDATA_UART,
    input  logic        PREADY_UART,
    input  logic        PSLVERR_UART,

    output logic        PSEL_SPI,
    input  logic [31:0] PRDATA_SPI,
    input  logic        PREADY_SPI,
    input  logic        PSLVERR_SPI
);

    //--------------------------------------------------
    // ADDRESS DECODE
    //--------------------------------------------------

    always_comb
    begin

        PSEL_GPIO = 0;
        PSEL_UART = 0;
        PSEL_SPI  = 0;

        if (PSEL)
        begin

            //----------------------------------------------
            // GPIO
            //----------------------------------------------

            if (PADDR[31:16] == 16'h0000)
                PSEL_GPIO = 1'b1;

            //----------------------------------------------
            // UART
            //----------------------------------------------

            else if (PADDR[31:16] == 16'h0001)
                PSEL_UART = 1'b1;

            //----------------------------------------------
            // SPI
            //----------------------------------------------

            else if (PADDR[31:16] == 16'h0002)
                PSEL_SPI = 1'b1;

        end

    end

    //--------------------------------------------------
    // READ DATA MUX
    //--------------------------------------------------

    always_comb
    begin

        PRDATA  = 32'h0;
        PREADY  = 1'b0;
        PSLVERR = 1'b0;

        //----------------------------------------------
        // GPIO RESPONSE
        //----------------------------------------------

        if (PSEL_GPIO)
        begin

            PRDATA  = PRDATA_GPIO;
            PREADY  = PREADY_GPIO;
            PSLVERR = PSLVERR_GPIO;

        end

        //----------------------------------------------
        // UART RESPONSE
        //----------------------------------------------

        else if (PSEL_UART)
        begin

            PRDATA  = PRDATA_UART;
            PREADY  = PREADY_UART;
            PSLVERR = PSLVERR_UART;

        end

        //----------------------------------------------
        // SPI RESPONSE
        //----------------------------------------------

        else if (PSEL_SPI)
        begin

            PRDATA  = PRDATA_SPI;
            PREADY  = PREADY_SPI;
            PSLVERR = PSLVERR_SPI;

        end

        //----------------------------------------------
        // INVALID ADDRESS
        //----------------------------------------------

        else if (PSEL)
        begin

            PSLVERR = 1'b1;
            PREADY  = 1'b1;

        end

    end

endmodule