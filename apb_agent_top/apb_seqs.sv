// apb seq base class
class apb_base_seq extends uvm_sequence #(apb_xtn);

        // factory registration
        `uvm_object_utils(apb_base_seq)

        // constructor
        function new(string name = "apb_base_seq");
                super.new(name);
        endfunction : new

endclass : apb_base_seq

//===============================================================================================

class apb_write_uart_seq extends apb_base_seq;

        // factory registration
        `uvm_object_utils(apb_write_uart_seq)

        // constructor
        function new(string name = "apb_write_uart_seq");
                super.new(name);
        endfunction : new

        // body task
        task body();

                repeat(10) begin

                        req = apb_xtn::type_id::create("req");

                        start_item(req);

                        assert(req.randomize() with
                        {
                                rw == 1;
                                addr == 32'h0001_0000;
                        });

                        finish_item(req);

                end

        endtask : body

endclass : apb_write_uart_seq
//===========================================================================================

class apb_write_gpio_seq extends apb_base_seq;

        // factory registration
        `uvm_object_utils(apb_write_gpio_seq)

        // constructor
        function new(string name = "apb_write_gpio_seq");
                super.new(name);
        endfunction : new

        // body task
        task body();

                repeat(no_of_transactions) begin

                        req = apb_xtn::type_id::create("req");

                        start_item(req);

                        assert(req.randomize() with
                        {
                                rw == 1;
                                addr == 32'h0000_0000;
                        });

                        finish_item(req);

                end

        endtask : body

endclass : apb_write_gpio_seq

//=========================================================================================

class apb_write_spi_seq extends apb_base_seq;

        // factory registration
        `uvm_object_utils(apb_write_spi_seq)

        // constructor
        function new(string name = "apb_write_spi_seq");
                super.new(name);
        endfunction : new

        // body task
        task body();

                repeat(no_of_transactions) begin

                        req = apb_xtn::type_id::create("req");

                        start_item(req);

                        assert(req.randomize() with
                        {
                                rw == 1;
                                addr == 32'h0002_0000;
                        });

                        finish_item(req);

                end

        endtask : body

endclass : apb_write_spi_seq

//=========================================================================================

//=========================================================================================
// apb write seqs
class apb_write_seq extends apb_base_seq;

        // factory registration
        `uvm_object_utils(apb_write_seq)

        // constructor
        function new(string name = "apb_write_seq");
                super.new(name);
        endfunction : new

        // body task
        task body();

                repeat(no_of_transactions) begin

                        req = apb_xtn::type_id::create("req");

                        start_item(req);

                        assert(req.randomize() with {rw == 1;});

                        finish_item(req);

                end

        endtask : body

endclass : apb_write_seq

//===============================================================================================
// apb read seqs
class apb_read_seq extends apb_base_seq;

        // factory registration
        `uvm_object_utils(apb_read_seq)

        // constructor
        function new(string name = "apb_read_seq");
                super.new(name);
        endfunction : new

        // task body
        task body();

                repeat(no_of_transactions) begin

                        req = apb_xtn::type_id::create("req");

                        start_item(req);

                        assert(req.randomize() with
                        {
                                rw == 0;
                                addr == 32'h0001_0000;
                        });

                        finish_item(req);

                end

        endtask : body

endclass : apb_read_seq

//===============================================================================================
