// spi sequencer
class spi_seqr extends uvm_sequencer #(spi_xtn);

        // factory registration
        `uvm_component_utils(spi_seqr)

        // constructor
        function new(string name = "spi_seqr", uvm_component parent);
                super.new(name, parent);
        endfunction : new

endclass : spi_seqr
