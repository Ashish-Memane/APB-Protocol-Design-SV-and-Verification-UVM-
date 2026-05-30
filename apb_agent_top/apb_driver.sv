// driver class
class apb_driver extends uvm_driver #(apb_xtn);

        // factory registration
        `uvm_component_utils(apb_driver)

        // virtual interface
        virtual apb_interface vif;

        // config object
        apb_agent_config m_cfg;

        // constructor
        function new(string name = "apb_driver", uvm_component parent);
                super.new(name, parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(apb_agent_config)::get(this,"","apb_agent_config",m_cfg))
                        `uvm_fatal(get_type_name(),"Cannot get the apb config object")

        endfunction : build_phase

        // connect phase
        function void connect_phase(uvm_phase phase);
                super.connect_phase(phase);

                vif = m_cfg.apb_vif;

        endfunction : connect_phase

        // run phase
        task run_phase(uvm_phase phase);

                wait(vif.PRESETn);

                forever begin

                        // get transaction
                        seq_item_port.get_next_item(req);

                        // send to dut
                        send_to_dut(req);

                        // item done
                        seq_item_port.item_done();

                end

        endtask : run_phase

        // task send to dut
        task send_to_dut(apb_xtn xtn_h);

                @(vif.apb_drv_cb);

                vif.apb_drv_cb.start <= 1'b1;
                vif.apb_drv_cb.rw <= xtn_h.rw;
                vif.apb_drv_cb.addr <= xtn_h.addr;
                vif.apb_drv_cb.wdata <= xtn_h.wdata;

                @(vif.apb_drv_cb);
                vif.apb_drv_cb.start <= 1'b0;


                wait(vif.apb_drv_cb.done);


                // capture the rdata
                xtn_h.rdata = vif.apb_drv_cb.rdata;

                // capture the error
                xtn_h.err = vif.apb_drv_cb.err;

                // display
                `uvm_info(get_type_name(),
                          $sformatf("ADDR=%0h WDATA=%0h RDATA=%0h RW=%0b",
                          xtn_h.addr,
                          xtn_h.wdata,
                          xtn_h.rdata,
                          xtn_h.rw),
                          UVM_LOW)

        endtask : send_to_dut


endclass : apb_driver
