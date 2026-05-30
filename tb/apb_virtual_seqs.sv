// class apb virtual seqs
class apb_virtual_seqs extends uvm_sequence #(uvm_sequence_item);

        // factory registration
        `uvm_object_utils(apb_virtual_seqs)

        // declaration of the virtual sequenecr
        apb_virtual_seqr apb_v_seqr;

        // declaration of the component seqr
        apb_seqr apb_seqr_h;
        uart_seqr uart_seqr_h;
        spi_seqr spi_seqr_h;
        gpio_seqr gpio_seqr_h;

        // constructor
        function new(string name = "apb_virtual_seqs");
                super.new(name);
        endfunction : new

        // task body
        task body();
                //super.body();

                // assigning the virtual seqr to m_sequencer handle
                if(!$cast(apb_v_seqr, m_sequencer)) begin
                        `uvm_error(get_type_name(),"Cannot cast the object");
                end

                // connecting the local seqr to virtual seqrs
                apb_seqr_h = apb_v_seqr.apb_seqr_h;
                uart_seqr_h = apb_v_seqr.uart_seqr_h;
                spi_seqr_h = apb_v_seqr.spi_seqr_h;
                gpio_seqr_h = apb_v_seqr.gpio_seqr_h;

        endtask : body

endclass : apb_virtual_seqs

//==========================================================================================

class apb_write_uart_vseq extends apb_virtual_seqs;

        // factory registration
        `uvm_object_utils(apb_write_uart_vseq)

        // seq handle declaration
        apb_write_uart_seq seq_h;

        // constructor
        function new(string name = "apb_write_uart_vseq");
                super.new(name);
        endfunction : new


        // task body
        task body();

                super.body();

                seq_h = apb_write_uart_seq::type_id::create("seq_h");

                fork
                        seq_h.start(apb_seqr_h);
                join

        endtask : body

endclass : apb_write_uart_vseq

//============================================================================================

class apb_write_spi_vseq extends  apb_virtual_seqs;

        // factory registration
        `uvm_object_utils(apb_write_spi_vseq)

        // seq handle declaration
        apb_write_spi_seq seq_h;
        spi_slave_resp_seq s_seq_h;

        // constructor
        function new(string name = "apb_write_spi_vseq");
                super.new(name);
        endfunction : new

        // task body
        task body();

                super.body();
                seq_h = apb_write_spi_seq::type_id::create("seq_h");
                s_seq_h = spi_slave_resp_seq::type_id::create("s_seq_h");

                fork
                        seq_h.start(apb_seqr_h);
                        s_seq_h.start(spi_seqr_h);
                join

        endtask : body

endclass : apb_write_spi_vseq

//=============================================================================================

class apb_write_gpio_vseq extends apb_virtual_seqs;

        // factory registration
        `uvm_object_utils(apb_write_gpio_vseq)

        // seq handle declaration
        apb_write_gpio_seq seq_h;

        // constructor
        function new(string name = "apb_write_gpio_vseq");
                super.new(name);
        endfunction : new

        // task body
        task body();

                super.body();

                seq_h = apb_write_gpio_seq::type_id::create("seq_h");

                fork
                        seq_h.start(apb_seqr_h);
                join

        endtask : body

endclass : apb_write_gpio_vseq
