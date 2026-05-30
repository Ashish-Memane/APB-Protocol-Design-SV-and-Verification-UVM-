// class seqr (uart)

class uart_seqr extends uvm_sequencer #(uart_xtn);

        // factory registration
        `uvm_component_utils(uart_seqr)

        // constructor
        function new(string name = "uart_seqr", uvm_component parent);
                super.new(name, parent);
        endfunction : new

endclass : uart_seqr
