// uart sequences
class uart_base_seq extends uvm_sequence #(uart_xtn);

        // factory registration
        `uvm_object_utils(uart_base_seq)

        // constructor
        function new(string name = "uart_base_seq");
                super.new(name);
        endfunction : new

endclass : uart_base_seq

//===============================================================================================

class uart_rx_seq extends uart_base_seq;

        // factory registration
        `uvm_object_utils(uart_rx_seq)

        // constructor
        function new(string name = "uart_rx_seq");
                super.new(name);
        endfunction : new

        // body task
        task body();

                repeat(no_of_transactions) begin

                        // create transaction
                        req = uart_xtn::type_id::create("req");

                        start_item(req);

                        assert(req.randomize());

                        finish_item(req);

                        `uvm_info("UART_SEQ",
                                  $sformatf("UART RX DATA = %0h",req.data),
                                  UVM_LOW)
                end

        endtask : body

endclass : uart_rx_seq
