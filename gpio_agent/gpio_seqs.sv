// class gpio seqs
class gpio_base_seq extends uvm_sequence #(gpio_xtn);

        // factory registraion
        `uvm_object_utils(gpio_xtn)

        // constructor
        function new(string name = "gpio_xtn");
                super.new(name);
        endfunction : new

endclass : gpio_base_seq

//=====================================================================================

class gpio_pkt_seq extends gpio_base_seq;

        // factory registration
        `uvm_object_utils(gpio_pkt_seq)

        // constructor
        function new(string name = "gpio_pkt_seq");
                super.new(name);
        endfunction : new

        // task body
        task body();

                repeat(no_of_transactions) begin

                        req = gpio_xtn::type_id::create("req");

                        start_item(req);

                        assert(req.randomize());

                        finish_item(req);

                        `uvm_info("UART_SEQ",$sformatf("GPIO data in : %0h", req.gpio_in),UVM_LOW)

                end

        endtask : body

endclass : gpio_pkt_seq
