// gpio driver class
class gpio_driver extends uvm_driver #(gpio_xtn);

        // factory registration
        `uvm_component_utils(gpio_driver)

        // virtual interface
        virtual gpio_interface vif;

        // constructor
        function new(string name = "gpio_driver", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(virtual gpio_interface)::get(this,"","gpio_interface",vif))
                        `uvm_fatal(get_type_name(),"Cannot get the gpio interface")

        endfunction : build_phase


        // task run phase
        task run_phase(uvm_phase phase);
                super.run_phase(phase);

                forever begin

                        // get the item
                        seq_item_port.get_next_item(req);

                        // drive to dut
                        gpio_to_dut(req);

                        // item done
                        seq_item_port.item_done();
                end

        endtask : run_phase

        // gpio drive task
        task gpio_to_dut(gpio_xtn xtn_h);

                @(vif.gpio_drv_cb);

                        vif.gpio_drv_cb.gpio_in <= xtn_h.gpio_in;

                `uvm_info("GPIO_DRV",
                          $sformatf("GPIO INPUT DRIVEN = %0h",
                                    xtn_h.gpio_in),
                          UVM_LOW)

        endtask : gpio_to_dut

endclass : gpio_driver
