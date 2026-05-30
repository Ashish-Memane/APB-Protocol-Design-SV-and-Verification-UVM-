// apb interface
interface apb_interface(input logic PCLK, input logic PRESETn);

    //--------------------------------------------------
    // CONTROL INTERFACE
    //--------------------------------------------------


    logic        start;
    logic        rw;

    logic [31:0] addr;
    logic [31:0] wdata;

    logic [31:0] rdata;

    logic done;
    logic err;


    //--------------------------------------------------

    clocking apb_drv_cb @(posedge PCLK);

        default input #1 output #1;

        //----------------------------------------------
        // DRIVER OUTPUTS
        //----------------------------------------------

        output start;
        output rw;
        output addr;
        output wdata;

        //----------------------------------------------
        // DRIVER INPUTS
        //----------------------------------------------

        input done;
        input err;
        input rdata;

    endclocking : apb_drv_cb

    //--------------------------------------------------
    // MONITOR CLOCKING BLOCK
    //--------------------------------------------------

    clocking apb_mon_cb @(posedge PCLK);

        default input #1 output #1;

        //----------------------------------------------
        // MONITOR INPUTS
        //----------------------------------------------

        input start;
        input rw;

        input addr;
        input wdata;

        input rdata;

        input done;
        input err;

        //----------------------------------------------
        // OPTIONAL APB SIGNALS
        //----------------------------------------------


    endclocking : apb_mon_cb

    //--------------------------------------------------
    // MODPORTS
    //--------------------------------------------------

    modport APB_DRV_MP (clocking apb_drv_cb);

    modport APB_MON_MP (clocking apb_mon_cb);

endinterface : apb_interface
