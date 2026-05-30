// scoreboard class
class scoreboard extends uvm_scoreboard;

        // factory registration
        `uvm_component_utils(scoreboard)

        // tlm ports
        uvm_tlm_analysis_fifo #(apb_xtn) apb_fifo;

        uvm_tlm_analysis_fifo #(uart_xtn) uart_fifo;

        uvm_tlm_analysis_fifo #(spi_xtn) spi_fifo;

        uvm_tlm_analysis_fifo #(gpio_xtn) gpio_fifo;

        // int declaration
        int uart_write_pkt_count = 0;
        int uart_read_pkt_count = 0;

        int spi_write_pkt_count = 0;
        int spi_read_pkt_count = 0;

        int gpio_write_pkt_count = 0;
        int gpio_read_pkt_count = 0;

        // constructor
        function new(string name = "scoreboard", uvm_component parent);
                super.new(name,parent);
        endfunction : new

        // build phase
        function void build_phase(uvm_phase phase);
                super.build_phase(phase);

                // creating the analysis imports
                apb_fifo = new("apb_fifo", this);

                uart_fifo = new("uart_fifo", this);

                spi_fifo = new("spi_fifo", this);

                gpio_fifo = new("gpio_fifo", this);

        endfunction : build_phase

        // run phase
        task run_phase(uvm_phase phase);

                forever begin

                        // transaction object to store
                        apb_xtn apb_h;
                        uart_xtn uart_h;
                        spi_xtn spi_h;
                        gpio_xtn gpio_h;


                        // get the apb transaction
                        apb_fifo.get(apb_h);


                        // apb  write operations
                        if (apb_h.rw == 1'b1) begin

                                case(apb_h.addr)

                                        // uart
                                        32'h0001_0000 : begin
                                                // get the uart transaction
                                                uart_fifo.get(uart_h);

                                                // cheak the uart tx data
                                                check_uart(apb_h, uart_h);

                                                uart_write_pkt_count++;

                                        end

                                        // gpio_out
                                        32'h0000_0000 : begin
                                                // get the gpio xtn
                                                gpio_fifo.get(gpio_h);

                                                // check the gpio data
                                                check_gpio(apb_h, gpio_h);

                                                gpio_write_pkt_count++;
                                        end

                                        // gpio_dir
                                        32'h0000_0008 : begin
                                                // get the gpio xtn
                                                gpio_fifo.get(gpio_h);

                                                // check the gpio data
                                                check_gpio(apb_h, gpio_h);

                                                gpio_write_pkt_count++;
                                        end

                                        // spi
                                        32'h0002_0000 : begin
                                                // get the spi xtn
                                                spi_fifo.get(spi_h);

                                                // check the spi data
                                                check_spi(apb_h, spi_h);

                                                spi_write_pkt_count++;
                                        end

                                endcase

                        end

                        // apb read transactions
                        if (apb_h.rw == 1'b0) begin

                                case (apb_h.addr)

                                        // uart
                                        32'h0001_0004 : begin
                                                // get the uart pkt
                                                uart_fifo.get(uart_h);

                                                check_uart(apb_h, uart_h);

                                                uart_read_pkt_count++;
                                        end

                                        // gpio
                                        32'h0000_0004 : begin
                                                gpio_fifo.get(gpio_h);

                                                check_gpio(apb_h, gpio_h);

                                                gpio_read_pkt_count++;
                                        end

                                        // spi
                                        32'h0002_0000 : begin
                                                spi_fifo.get(spi_h);

                                                check_spi(apb_h,spi_h);

                                                spi_read_pkt_count++;
                                        end

                                endcase

                        end

                end

        endtask : run_phase

        // task check uart data
        task check_uart(apb_xtn apb_h, uart_xtn uart_h);

                // write check
                if(apb_h.rw == 1'b1) begin
                        if(apb_h.wdata == uart_h.data) begin
                                `uvm_info(get_type_name(),$sformatf("[SUCCESSFUL] : APB WRITE DATA = %0h ||| UART DATA = %0h", apb_h.wdata, uart_h.data), UVM_LOW)
                        end else begin
                                `uvm_info(get_type_name(),$sformatf("[FAILED] : APB WRITE DATA = %0h ||| UART DATA = %0h", apb_h.wdata, uart_h.data),UVM_LOW)
                        end
                end

                // read check
                if(apb_h.rw == 1'b0) begin
                        if(apb_h.rdata == uart_h.data) begin
                                `uvm_info(get_type_name(),$sformatf("[SUCCESSFUL] : APB READ DATA = %0h ||| UART DATA = %0h", apb_h.rdata, uart_h.data),UVM_LOW)
                        end else begin
                                `uvm_info(get_type_name(),$sformatf("[FAILED] : APB READ DATA = %0h ||| UART DATA = %0h", apb_h.rdata, uart_h.data),UVM_LOW)
                        end
                end


        endtask : check_uart


        // task check spi data
        task check_spi(apb_xtn apb_h, spi_xtn spi_h);

                // write check
                if(apb_h.rw == 1'b1) begin
                        if(apb_h.wdata == spi_h.tx_data) begin
                                `uvm_info(get_type_name(),$sformatf("[SUCCESSFUL] : APB WRITE DATA = %0h ||| SPI DATA = %0h", apb_h.wdata, spi_h.tx_data),UVM_LOW)
                        end else begin
                                `uvm_info(get_type_name(),$sformatf("[FAILED] : APB WRITE DATA = %0h ||| SPI DATA = %0h", apb_h.wdata, spi_h.tx_data),UVM_LOW)
                        end
                end

                // read check
                if(apb_h.rw == 1'b0) begin
                        if(apb_h.rdata == spi_h.rx_data) begin
                                `uvm_info(get_type_name(),$sformatf("[SUCCESSFUL] : APB READ DATA = %0h ||| SPI DATA = %0h", apb_h.rdata, spi_h.rx_data),UVM_LOW)
                        end else begin
                                `uvm_info(get_type_name(),$sformatf("[FAILED] : APB READ DATA = %0h ||| SPI DATA = %0h", apb_h.rdata, spi_h.rx_data),UVM_LOW)
                        end
                end

        endtask : check_spi


        // task check gpio data
        task check_gpio(apb_xtn apb_h, gpio_xtn gpio_h);

                // write check
                if(apb_h.rw == 1'b1) begin
                        if(apb_h.wdata == gpio_h.gpio_out || apb_h.wdata == gpio_h.gpio_dir) begin
                                `uvm_info(get_type_name(),$sformatf("[SUCCESSFUL] : APB WRITE DATA = %0h ||| GPIO_OUT = %0h ||| GPIO_DIR = %0h", apb_h.wdata, gpio_h.gpio_out, gpio_h.gpio_dir),UVM_LOW)
                        end else begin
                                `uvm_info(get_type_name(),$sformatf("[FAILED] : APB WRITE DATA = %0h ||| GPIO_OUT = %0h ||| GPIO_DIR = %0h", apb_h.wdata, gpio_h.gpio_out, gpio_h.gpio_dir), UVM_LOW)
                        end
                end
                // read check
                if(apb_h.rw == 1'b0) begin
                        if(apb_h.rdata == gpio_h.gpio_in) begin
                                `uvm_info(get_type_name(),$sformatf("[SUCCESSFUL] : APB READ DATA = %0h ||| GPIO_IN = %0h", apb_h.rdata, gpio_h.gpio_in), UVM_LOW)
                        end else begin
                                `uvm_info(get_type_name(),$sformatf("[FAILED] : APB READ DATA = %0h ||| GPIO_IN = %0h", apb_h.rdata, gpio_h.gpio_in), UVM_LOW)
                        end
                end

        endtask : check_gpio


        // report phase
        function void report_phase(uvm_phase phase);

                super.report_phase(phase);
                `uvm_info(get_type_name(),$sformatf("[WRITE] UART PKT COUNT : %0h || SPI PKT COUNT : %0h || GPIO PKT COUNT : %0h",uart_write_pkt_count, spi_write_pkt_count, gpio_write_pkt_count),UVM_LOW)
                `uvm_info(get_type_name(),$sformatf("[READ] UART PKT COUNT : %0h || SPI PKT COUNT : %0h || GPIO PKT COUNT : %0h",uart_read_pkt_count, gpio_read_pkt_count, spi_read_pkt_count), UVM_LOW)

        endfunction : report_phase

endclass : scoreboard
