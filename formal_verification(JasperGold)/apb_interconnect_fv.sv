module apb_interconnect_fv
(
    // Global Control (Implicit tracking clock for properties)
    input  logic        PCLK,
    input  logic        PRESETn,

    // Incoming Master Bus Wires
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,

    // Muxed Outbound Master Response Wires
    input  logic [31:0] PRDATA,
    input  logic        PREADY,
    input  logic        PSLVERR,

    // Slave Control Interfaces
    input  logic        PSEL_GPIO,
    input  logic [31:0] PRDATA_GPIO,
    input  logic        PREADY_GPIO,
    input  logic        PSLVERR_GPIO,

    input  logic        PSEL_UART,
    input  logic [31:0] PRDATA_UART,
    input  logic        PREADY_UART,
    input  logic        PSLVERR_UART,

    input  logic        PSEL_SPI,
    input  logic [31:0] PRDATA_SPI,
    input  logic        PREADY_SPI,
    input  logic        PSLVERR_SPI
);

    // =========================================================================
    // 1. CONSTRAINTS (Modeling Legal Bus Scenarios)
    // =========================================================================
    assume_penable_require_psel : assume property (@(posedge PCLK)
        PENABLE |-> PSEL
    );

    // =========================================================================
    // 2. ASSERTIONS: Address Decoding (Mutual Exclusion and Target Validity)
    // =========================================================================

    // Check 1: One-Hot Select Safeguard
    // Ensure the decoder can never accidentally select more than one slave at a time.
    assert_mutual_exclusive_selects : assert property (@(posedge PCLK)
        $onehot0({PSEL_GPIO, PSEL_UART, PSEL_SPI})
    );

    // Check 2: Accurate GPIO Routing
    assert_gpio_select_decode : assert property (@(posedge PCLK)
        (PSEL && (PADDR[31:16] == 16'h0000)) |-> (PSEL_GPIO == 1'b1)
    );

    // Check 3: Accurate UART Routing
    assert_uart_select_decode : assert property (@(posedge PCLK)
        (PSEL && (PADDR[31:16] == 16'h0001)) |-> (PSEL_UART == 1'b1)
    );

    // Check 4: Accurate SPI Routing
    assert_spi_select_decode : assert property (@(posedge PCLK)
        (PSEL && (PADDR[31:16] == 16'h0002)) |-> (PSEL_SPI == 1'b1)
    );

    // Check 5: Unmapped Base Address Rejection
    // If PSEL is up but address space doesn't match any slave, no line should go high
    assert_unmapped_selects_stay_low : assert property (@(posedge PCLK)
        (PSEL && !(PADDR[31:16] inside {16'h0000, 16'h0001, 16'h0002})) |-> 
        (!PSEL_GPIO && !PSEL_UART && !PSEL_SPI)
    );

    // =========================================================================
    // 3. ASSERTIONS: Data Multiplexer Routing (Immediate Combinational Checking)
    // =========================================================================

    // Check 6: GPIO Combinational Response Passing
    assert_gpio_response_mux : assert property (@(posedge PCLK)
        PSEL_GPIO |-> (PRDATA  == PRDATA_GPIO  && 
                       PREADY  == PREADY_GPIO  && 
                       PSLVERR == PSLVERR_GPIO)
    );

    // Check 7: UART Combinational Response Passing
    assert_uart_response_mux : assert property (@(posedge PCLK)
        PSEL_UART |-> (PRDATA  == PRDATA_UART  && 
                       PREADY  == PREADY_UART  && 
                       PSLVERR == PSLVERR_UART)
    );

    // Check 8: SPI Combinational Response Passing
    assert_spi_response_mux : assert property (@(posedge PCLK)
        PSEL_SPI |-> (PRDATA  == PRDATA_SPI  && 
                      PREADY  == PREADY_SPI  && 
                      PSLVERR == PSLVERR_SPI)
    );

    // Check 9: Interconnect Error Trapping
    // If the master accesses an unmapped space, the interconnect must immediately 
    // respond with PSLVERR=1 and PREADY=1 to keep the system from hanging.
    assert_invalid_address_error_trap : assert property (@(posedge PCLK)
        (PSEL && !PSEL_GPIO && !PSEL_UART && !PSEL_SPI) |-> (PSLVERR == 1'b1 && PREADY == 1'b1)
    );

    // =========================================================================
    // 4. COVERAGE UNREACHABILITY ASSERTIONS
    // =========================================================================
    assert_impossible_apb_state : assert property (@(posedge PCLK)
        !(PENABLE && !PSEL)
    );

endmodule


bind apb_interconnect apb_interconnect_fv u_apb_interconnect_fv_bind (
    .PCLK         (PCLK), // Note: Using input bus clock for verification reference
    .PRESETn      (1'b1), // No structural reset used inside combinational block

    .PADDR        (PADDR),
    .PWDATA       (PWDATA),
    .PWRITE       (PWRITE),
    .PENABLE      (PENABLE),
    .PSEL         (PSEL),

    .PRDATA       (PRDATA),
    .PREADY       (PREADY),
    .PSLVERR      (PSLVERR),

    .PSEL_GPIO    (PSEL_GPIO),
    .PRDATA_GPIO  (PRDATA_GPIO),
    .PREADY_GPIO  (PREADY_GPIO),
    .PSLVERR_GPIO (PSLVERR_GPIO),

    .PSEL_UART    (PSEL_UART),
    .PRDATA_UART  (PRDATA_UART),
    .PREADY_UART  (PREADY_UART),
    .PSLVERR_UART (PSLVERR_UART),

    .PSEL_SPI     (PSEL_SPI),
    .PRDATA_SPI   (PRDATA_SPI),
    .PREADY_SPI   (PREADY_SPI),
    .PSLVERR_SPI  (PSLVERR_SPI)
);
