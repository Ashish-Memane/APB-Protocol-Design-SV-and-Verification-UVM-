// uart driver
class uart_driver extends uvm_driver #(uart_xtn);

        // factory registration
        `uvm_component_utils(uart_driver)

        // virtual interface
        virtual uart_interface vif;

        //constructor
        function new(string name = "uart_driver", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // get virtual interface
                if(!uvm_config_db#(virtual uart_interface)::get(this,"","uart_interface",vif))
                        `uvm_fatal(get_type_name(),"Cannot get the uart interface")

        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);

                forever begin

                        seq_item_port.get_next_item(req);

                        drive_uart_pkt(req);

                        seq_item_port.item_done();
                end

        endtask : run_phase

        // drive 32-bit full packet
        task drive_uart_pkt(uart_xtn xtn);

                bit[7:0] byte0;
                bit[7:0] byte1;
                bit[7:0] byte2;
                bit[7:0] byte3;


                // split into bytes
                byte0 = xtn.data[7:0];
                byte1 = xtn.data[15:8];
                byte2 = xtn.data[23:16];
                byte3 = xtn.data[31:24];

                // send byte
                send_byte(byte0);
                send_byte(byte1);
                send_byte(byte2);
                send_byte(byte3);

                 `uvm_info("UART_DRV",
                          $sformatf("UART RX DRIVEN DATA = %0h",xtn.data),
                          UVM_LOW)

        endtask : drive_uart_pkt

        // send single byte
        task send_byte(bit [7:0] data);

                int i;

                //start bit
                vif.uart_drv_cb.rx <= 1'b0;

                @(vif.uart_drv_cb);

                //data bits
                for (i = 0; i < 8; i++) begin

                        vif.uart_drv_cb.rx <= data[i];

                        @(vif.uart_drv_cb);

                end

                // stop bit
                vif.uart_drv_cb.rx <= 1'b1;

                @(vif.uart_drv_cb);


        endtask : send_byte


endclass : uart_driver
