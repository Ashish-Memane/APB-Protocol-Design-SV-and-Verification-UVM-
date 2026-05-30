// apb virtual sequencer
class apb_virtual_seqr extends uvm_sequencer #(uvm_sequence_item);

        // factory registration
        `uvm_component_utils(apb_virtual_seqr)

        // sequencer handles
        apb_seqr apb_seqr_h;

        uart_seqr uart_seqr_h;
        spi_seqr spi_seqr_h;
        gpio_seqr gpio_seqr_h;

        // constructor
        function new(string name = "apb_virtual_seqr", uvm_component parent);
                super.new(name,parent);
        endfunction : new

endclass : apb_virtual_seqr
