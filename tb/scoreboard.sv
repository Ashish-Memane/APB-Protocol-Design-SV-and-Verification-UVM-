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

        covergroup peripheral_cg;
                option.per_instance = 1;
                option.comment      = "Subsystem Register Access and Data Coverage Map";

                // 1. APB Bus Attributes
                CP_APB_RW: coverpoint cov_apb.rw {
                        bins READ  = {1'b0};
                        bins WRITE = {1'b1};
                }

                CP_APB_ADDR: coverpoint cov_apb.addr {
                        bins GPIO_OUT = {32'h0000_0000};
                        bins GPIO_IN  = {32'h0000_0004};
                        bins GPIO_DIR = {32'h0000_0008};
                        bins UART_TX  = {32'h0001_0000};
                        bins UART_RX  = {32'h0001_0004};
                        bins SPI_REG  = {32'h0002_0000};
                        bins SPI_RX   = {32'h0002_0004};
                }

                // Cross coverage to ensure every register was both read and written
                CR_ADDR_X_RW: cross CP_APB_ADDR, CP_APB_RW {
                        // Ignore invalid hardware accesses to avoid low coverage holes
                        ignore_bins read_gpios_out = binsof(CP_APB_ADDR) intersect {32'h0000_0000} && binsof(CP_APB_RW) intersect {1'b0};
                        ignore_bins write_gpios_in = binsof(CP_APB_ADDR) intersect {32'h0000_0004} && binsof(CP_APB_RW) intersect {1'b1};
                }

                // 2. UART Data Sampling
                CP_UART_DATA: coverpoint cov_uart.data {
                        bins ZERO          = {8'h00};
                        bins ALL_ONES      = {8'hFF};
                        bins WALKING_ONES  = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
                        bins DATA_RANGE[4] = {[8'h01:8'hFE]};
                }

                // 3. SPI Data Sampling
                CP_SPI_TX_DATA: coverpoint cov_spi.tx_data {
                        bins LOWER_HALF = {[32'h0000_0000 : 32'h7FFF_FFFF]};
                        bins UPPER_HALF = {[32'h8000_0000 : 32'hFFFF_FFFF]};
                }
                
                CP_SPI_RX_DATA: coverpoint cov_spi.rx_data {
                        bins LOWER_HALF = {[32'h0000_0000 : 32'h7FFF_FFFF]};
                        bins UPPER_HALF = {[32'h8000_0000 : 32'hFFFF_FFFF]};
                }

                // 4. GPIO Pin Walking Bit Densities
                CP_GPIO_IN: coverpoint cov_gpio.gpio_in {
                        bins ALL_LOW   = {32'h0000_0000};
                        bins ALL_HIGH  = {32'hFFFF_FFFF];
                        bins EXT_INPUT = {[32'h0000_0001 : 32'hFFFF_FFFE]};
                }
        endgroup : peripheral_cg

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
                `uvm_info(get_type_name(),$sformatf("[WRITE] UART PKT COUNT : %0d || SPI PKT COUNT : %0d || GPIO PKT COUNT : %0d",uart_write_pkt_count, spi_write_pkt_count, gpio_write_pkt_count),UVM_LOW)
                `uvm_info(get_type_name(),$sformatf("[READ] UART PKT COUNT : %0d || SPI PKT COUNT : %0d || GPIO PKT COUNT : %0d",uart_read_pkt_count, gpio_read_pkt_count, spi_read_pkt_count), UVM_LOW)

        endfunction : report_phase

endclass : scoreboard
