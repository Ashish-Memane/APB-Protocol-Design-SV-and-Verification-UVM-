// class spi base seq

class spi_base_seq extends uvm_sequence #(spi_xtn);

        // factory registration
        `uvm_object_utils(spi_base_seq)

        // constructor
        function new(string name = "spi_base_seq");
                super.new(name);
        endfunction : new

endclass : spi_base_seq

//=====================================================================================

class spi_slave_resp_seq extends spi_base_seq;

        // factory registration
        `uvm_object_utils(spi_slave_resp_seq)

        // constructor
        function new(string name = "spi_slave_resp_seq");
                super.new(name);
        endfunction : new

        // task body
        task body();

                repeat(no_of_transactions) begin

                        req = spi_xtn::type_id::create("req");

                        // start item
                        start_item(req);

                        // randomize
                        assert(req.randomize());

                        // finish item
                        finish_item(req);

                        `uvm_info("SPI_SEQ",$sformatf("SPI RESPONSE DATA = %0h",
                                                    req.rx_data), UVM_LOW)
                end

        endtask : body

endclass : spi_slave_resp_seq
