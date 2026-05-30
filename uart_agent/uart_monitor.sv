// class uart monitor
class uart_monitor extends uvm_monitor;

        // factory registration
        `uvm_component_utils(uart_monitor)

        // virtual interface
        virtual uart_interface vif;

        // analysis port
        uvm_analysis_port #(uart_xtn) uart_ap;

        // transaction object
        uart_xtn xtn_h;

        // constructor
        function new(string name = "uart_monitor", uvm_component parent);
                super.new(name, parent);

                uart_ap = new("uart_ap", this);

        endfunction : new

        // build_phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                if(!uvm_config_db#(virtual uart_interface)::get(this,"","uart_interface",vif))
                        `uvm_fatal(get_type_name(),"Cannot get the uart interface")

        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);

                forever begin
                        collect_uart_pkt();
                end

        endtask : run_phase

        // task collect uart pkt
        task collect_uart_pkt();

                bit [7:0] byte0;
                bit [7:0] byte1;
                bit [7:0] byte2;
                bit [7:0] byte3;

                xtn_h = uart_xtn::type_id::create("xtn_h");

                // collect 4 uart frames
                collect_byte(byte0);
                collect_byte(byte1);
                collect_byte(byte2);
                collect_byte(byte3);

                // reconstruct the pkt
                xtn_h.data = {byte3, byte2, byte1, byte0};

                xtn_h.tx_done = 1'b1;

                // send to scoreboard
                uart_ap.write(xtn_h);

                `uvm_info("UART_MON",
                          $sformatf("UART TX MONITORED DATA = %0h",xtn_h.data),
                          UVM_LOW)

        endtask : collect_uart_pkt

        // collecting the single uart byte
        task collect_byte( output bit [7:0] data);

                int i;

                // wait for start bit
                wait(vif.uart_mon_cb.tx == 1'b0);

                for(i = 0; i < 8; i++) begin

                        @(vif.uart_mon_cb);

                        data[i] = vif.uart_mon_cb.tx;
                end

                // stop bit
                @(vif.uart_mon_cb);

                if(vif.uart_mon_cb.tx != 1'b1)
                        `uvm_error(get_type_name(),"STOP BIT ERROR")

        endtask : collect_byte

endclass : uart_monitor
