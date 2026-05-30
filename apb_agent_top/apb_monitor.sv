// apb monitor
class apb_monitor extends uvm_monitor;

        // factory registration
        `uvm_component_utils(apb_monitor)

        // interface declaration
        virtual apb_interface apb_vif;

        // analysis port
        uvm_analysis_port #(apb_xtn) monitor_port;

        // transaction object handle
        apb_xtn xtn_h;

        // constructor
        function new(string name = "apb_monitor", uvm_component parent);
                super.new(name, parent);
                monitor_port = new("monitor_port",this);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(virtual apb_interface)::get(this,"","apb_interface",apb_vif))
                        `uvm_fatal(get_type_name(),"Cannot get the interface")

        endfunction : build_phase

        // task run phase
        task run_phase(uvm_phase phase);

                forever begin
                        collect_data();
                end

        endtask : run_phase

        // task collect data
        task collect_data();

                xtn_h = apb_xtn::type_id::create("xtn_h");

                // wait for the start
                wait(apb_vif.apb_mon_cb.start);

                xtn_h = apb_xtn::type_id::create("xtn_h");

                // sample inputs
                xtn_h.rw = apb_vif.apb_mon_cb.rw;
                xtn_h.addr = apb_vif.apb_mon_cb.addr;
                xtn_h.wdata = apb_vif.apb_mon_cb.wdata;

                // wait for completion
                wait(apb_vif.apb_mon_cb.done);

                // sample outputs
                xtn_h.rdata = apb_vif.apb_mon_cb.rdata;
                xtn_h.err = apb_vif.apb_mon_cb.err;

                // send the transaction
                monitor_port.write(xtn_h);

                `uvm_info("APB_MONITOR",
                          $sformatf("ADDR=%0h WDATA=%0h RDATA=%0h RW=%0b ERR=%0b",
                          xtn_h.addr,
                          xtn_h.wdata,
                          xtn_h.rdata,
                          xtn_h.rw,
                          xtn_h.err),
                          UVM_LOW)

        endtask : collect_data


endclass : apb_monitor
