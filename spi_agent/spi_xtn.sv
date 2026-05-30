// spi transaction
class spi_xtn extends uvm_sequence_item;

        // factory registration
        `uvm_object_utils(spi_xtn)

        // expected mosi data
        logic [31:0] tx_data;

        // miso response data
        rand logic [31:0] rx_data;

        // status
        bit transfer_done;

        // constructor
        function new(string name = "spi_xtn");
                super.new(name);
        endfunction : new

        // function do print
        function void do_print(uvm_printer printer);

                super.do_print(printer);

                printer.print_field("tx_data",tx_data,32,UVM_HEX);
                printer.print_field("rx_data",rx_data,32,UVM_HEX);
                printer.print_field("transfer_done",
                                     transfer_done,
                                     1,
                                     UVM_BIN);

        endfunction : do_print

endclass : spi_xtn
