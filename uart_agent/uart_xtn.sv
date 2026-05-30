// uart transaction class
class uart_xtn extends uvm_sequence_item;

        // factory registration
        `uvm_object_utils(uart_xtn)

        // uart data
        rand logic [31:0] data;

        bit tx_done;
        bit rx_done;

        // constraint
        constraint data_c
        {
                soft data inside {[32'h0000_0000 : 32'hFFFF_FFFF]};
        };

        // constructor
        function new(string name = "uart_xtn");
                super.new(name);
        endfunction : new

        // print
        function void do_print(uvm_printer printer);
                super.do_print(printer);

                printer.print_field("data",data,32,UVM_HEX);
                printer.print_field("tx_done",tx_done,1,UVM_BIN);
                printer.print_field("rx_done",rx_done,1,UVM_BIN);

        endfunction : do_print

endclass : uart_xtn
