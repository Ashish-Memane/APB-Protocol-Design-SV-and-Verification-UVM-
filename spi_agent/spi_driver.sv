// spi driver class
class spi_driver extends uvm_driver #(spi_xtn);

        // factory registration
        `uvm_component_utils(spi_driver)

        // virtual interface
        virtual spi_interface vif;

        // constructor
        function new(string name = "spi_driver", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(virtual spi_interface)::get(this,"","spi_interface", vif))
                        `uvm_fatal(get_type_name(),"Cannot get the spi interface")

        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);

                forever begin

                        seq_item_port.get_next_item(req);

                        spi_to_dut(req);

                        seq_item_port.item_done();

                end

        endtask : run_phase

        // spi to dut task
        task spi_to_dut(spi_xtn xtn_h);

                int i;

                // wait for cs to go low
                wait(vif.spi_drv_cb.cs == 1'b0);

                // drive 32-bits miso
                for(i = 31; i >= 0; i--) begin

                        @(vif.spi_drv_cb);

                        vif.spi_drv_cb.miso <= xtn_h.rx_data[i];

                end

        // deassert miso
        @(vif.spi_drv_cb);
        vif.spi_drv_cb.miso <= 1'b0;

        `uvm_info("SPI_DRV",
                          $sformatf("SPI MISO DATA DRIVEN = %0h",
                                    xtn_h.rx_data),
                          UVM_LOW)


        endtask : spi_to_dut

endclass : spi_driver
