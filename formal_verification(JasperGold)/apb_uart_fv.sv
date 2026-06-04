module apb_uart_fv (
    input logic        PCLK,
    input logic        PRESETn,
    input logic        PSEL,
    input logic        PENABLE,
    input logic        PWRITE,
    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,
    input logic [31:0] PRDATA,
    input logic        PREADY,
    input logic        PSLVERR,
    
    // UART Physical Wires
    input logic        tx,
    input logic        rx,

    // Sniffed internal signals
    input logic [31:0] tx_reg,
    input logic [31:0] rx_reg,
    input logic [31:0] status_reg,
    input logic [1:0]  tx_state,
    input logic [1:0]  rx_state,
    input logic        tx_start,
    input logic [2:0]  bit_count,
    input logic [1:0]  byte_count,
    input logic [2:0]  rx_bit_count,
    input logic [1:0]  rx_byte_count
);

    // Address Layout Definitions
    localparam TXDATA_ADDR = 32'h0000_0000;
    localparam RXDATA_ADDR = 32'h0000_0004;
    localparam STATUS_ADDR = 32'h0000_0008;

    // FSM State Decodes matching your enum type logic
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // =========================================================================
    // 1. CONSTRAINTS (APB Master Protocol Environment Assumptions)
    // =========================================================================
    assume_penable_require_psel : assume property (@(posedge PCLK)
        PENABLE |-> PSEL
    );

    assume_apb_stable_during_stall : assume property (@(posedge PCLK)
        (PSEL && !PREADY) |=> ($stable(PADDR) && $stable(PWRITE) && $stable(PSEL))
    );

    assume_pwdata_stable_during_write : assume property (@(posedge PCLK)
        (PSEL && PWRITE && !PREADY) |=> $stable(PWDATA)
    );

    // =========================================================================
    // 2. ASSERTIONS: Core Registers & Bus Protocol
    // =========================================================================

    // Check 1: Strict Hardware Reset
    assert_uart_reset_state : assert property (@(posedge PCLK)
        !PRESETn |-> (tx == 1'b1 && tx_state == IDLE && rx_state == IDLE && status_reg == 32'h0)
    );

    // Check 2: Latching Transmitter Register on APB Write
    assert_tx_reg_write : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && PWRITE && PREADY && (PADDR == TXDATA_ADDR)) |=> (tx_reg == $past(PWDATA) && tx_start == 1'b1)
    );

    // Check 3: APB Read Channel Selection Mapping
    assert_status_reg_read : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PWRITE && (PADDR == STATUS_ADDR)) |-> (PRDATA == status_reg)
    );

    assert_rx_reg_read : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PWRITE && (PADDR == RXDATA_ADDR)) |-> (PRDATA == rx_reg)
    );

    // Check 4: Slave Error Routing
    assert_pslverr_generation : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && !(PADDR inside {TXDATA_ADDR, RXDATA_ADDR, STATUS_ADDR})) |-> (PSLVERR == 1'b1)
    );

    // =========================================================================
    // 3. ASSERTIONS: UART Transmission & Backpressure Engines
    // =========================================================================

    // Check 5: TX FSM Behavior (Start Bit Verification)
    // When tx_start kicks off from an idle state, the FSM must enter the START state 
    // and pull the physical tx line low (START bit).
    assert_tx_start_bit_low : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (tx_state == IDLE && tx_start) |=> (tx_state == START && tx == 1'b0)
    );

    // Check 6: TX FSM Progress Loop (Byte Counting)
    // Verify that the TX engine remains busy (status_reg[0] == 1) throughout all 4 bytes.
    assert_tx_busy_flag : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (tx_state inside {START, DATA, STOP}) |-> (status_reg[0] == 1'b1)
    );

    // Check 7: RX Buffer Flag Clear Mechanism
    // Reading the RXDATA register must drop the status data-ready flag (status_reg[1]) 
    // on the immediate next clock cycle.
    assert_rx_flag_clear_on_read : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && !PWRITE && PREADY && (PADDR == RXDATA_ADDR)) |=> (status_reg[1] == 1'b0)
    );

    // Check 8: Hardware Backpressure Stalling Protection
    // If a master tries to read RXDATA while it's empty, PREADY must clamp low to stall the bus.
    assert_pready_read_stall : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PWRITE && (PADDR == RXDATA_ADDR) && !status_reg[1]) |-> (PREADY == 1'b0)
    );

    // =========================================================================
    // 4. COVERAGE UNREACHABILITY ASSERTIONS (Clean Coverage Solutions)
    // =========================================================================
    assert_impossible_apb_state : assert property (@(posedge PCLK)
        !(PENABLE && !PSEL)
    );

    assert_unreachable_tx_case_default : assert property (@(posedge PCLK)
        disable iff (!PRESETn)
        (tx_state inside {IDLE, START, DATA, STOP})
    );

    assert_unreachable_rx_case_default : assert property (@(posedge PCLK)
        disable iff (!PRESETn)
        (rx_state inside {IDLE, DATA, STOP}) // Your RX FSM does not map START, it goes straight to DATA
    );

endmodule

// bind the module
bind apb_uart apb_uart_fv u_apb_uart_fv_bind (
    .PCLK          (PCLK),
    .PRESETn       (PRESETn),
    .PSEL          (PSEL),
    .PENABLE       (PENABLE),
    .PWRITE        (PWRITE),
    .PADDR         (PADDR),
    .PWDATA        (PWDATA),
    .PRDATA        (PRDATA),
    .PREADY        (PREADY),
    .PSLVERR       (PSLVERR),
    .tx            (tx),
    .rx            (rx),
    
    // Linking internal structural variables
    .tx_reg        (tx_reg),
    .rx_reg        (rx_reg),
    .status_reg    (status_reg),
    .tx_state      (tx_state),
    .rx_state      (rx_state),
    .tx_start      (tx_start),
    .bit_count     (bit_count),
    .byte_count    (byte_count),
    .rx_bit_count  (rx_bit_count),
    .rx_byte_count (rx_byte_count)
);
