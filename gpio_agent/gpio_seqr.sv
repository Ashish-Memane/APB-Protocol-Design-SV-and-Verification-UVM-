// seqr class gpio
class gpio_seqr extends uvm_sequencer #(gpio_xtn);

        // factory registration
        `uvm_component_utils(gpio_seqr)

        // constructor
        function new(string name = "gpio_seqr", uvm_component parent);
                super.new(name, parent);
        endfunction : new

endclass : gpio_seqr
