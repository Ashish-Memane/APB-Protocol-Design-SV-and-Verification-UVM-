//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ashish Memane
// 
// Create Date: 18.05.2026 17:39:56
// Design Name: spi interface
// Module Name: spi_interface
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
// spi interface
interface spi_interface(input logic PCLK, input logic PRESETn);

    //--------------------------------------------------
    // SPI SIGNALS
    //--------------------------------------------------

    logic miso;

    logic mosi;
    logic sclk;
    logic cs;

    //--------------------------------------------------
    // SPI DRIVER CLOCKING BLOCK
    //--------------------------------------------------

    clocking spi_drv_cb @(posedge sclk);

        default input #1 output #1;

        //----------------------------------------------
        // SPI SLAVE RESPONSE
        //----------------------------------------------

        output miso;

        //----------------------------------------------
        // DUT GENERATED SIGNALS
        //----------------------------------------------

        input mosi;
        input sclk;
        input cs;

        //----------------------------------------------
        // APB SIDE
        //----------------------------------------------
    endclocking : spi_drv_cb

    //--------------------------------------------------
    // SPI MONITOR CLOCKING BLOCK
    //--------------------------------------------------

    clocking spi_mon_cb @(posedge sclk);

        default input #1 output #1;

        //----------------------------------------------
        // SPI SIGNALS
        //----------------------------------------------

        input miso;
        input mosi;
        input sclk;
        input cs;

        //----------------------------------------------
        // APB SIGNALS
        //----------------------------------------------

    endclocking : spi_mon_cb

    //--------------------------------------------------
    // MODPORTS
    //--------------------------------------------------

    modport SPI_DRV_MP (clocking spi_drv_cb);

    modport SPI_MON_MP (clocking spi_mon_cb);

endinterface : spi_interface
