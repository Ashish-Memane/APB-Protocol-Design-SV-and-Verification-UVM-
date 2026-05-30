class apb_xtn extends uvm_sequence_item;


    // factory declaration
//    `uvm_object_utils(apb_xtn)

    //------------------------------------------
    // APB FIELDS
    //------------------------------------------

    rand bit [31:0] addr;
    rand bit [31:0] wdata;

    bit [31:0] rdata;

    rand bit rw;

    bit err;


    //------------------------------------------
    // ADDRESS CONSTRAINTS
    //------------------------------------------
    constraint addr_c
        {
            addr inside
            {
        //----------------------------------
        // GPIO
        //----------------------------------

                32'h0000_0000,
                32'h0000_0004,
                32'h0000_0008,

        //----------------------------------
        // UART
        //----------------------------------

                32'h0001_0000,
                32'h0001_0004,
                32'h0001_0008,

        //----------------------------------
        // SPI
        //----------------------------------

                32'h0002_0000,
                32'h0002_0004,
                32'h0002_0008,
                32'h0002_000C
            };
        }
    //------------------------------------------
    // UVM MACROS
    //------------------------------------------

    `uvm_object_utils_begin(apb_xtn)

        `uvm_field_int(addr , UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(rw, UVM_ALL_ON)
        `uvm_field_int(err  , UVM_ALL_ON)

    `uvm_object_utils_end

    //------------------------------------------
    // CONSTRUCTOR
    //------------------------------------------

    function new(string name = "apb_xtn");

        super.new(name);

    endfunction

endclass : apb_xtn
