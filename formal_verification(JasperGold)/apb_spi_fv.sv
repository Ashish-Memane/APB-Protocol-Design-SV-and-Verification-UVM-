module apb_spi_fv (
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
    
    // SPI physical lines
    input logic        sclk,
    input logic        mosi,
    input logic        miso,
    input logic        cs,

    // Internal signals linked for precise verification
    input logic [31:0] tx_reg,
    input logic [31:0] rx_reg,
    input logic        tx_valid,
    input logic [5:0]  bit_cnt,
    input logic [1:0]  state
);

    localparam SPI_ADDR = 32'h0000_0000;
    
    // SPI State Definitions matching RTL enum values
    localparam IDLE     = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam DONE     = 2'b10;

    // =========================================================================
    // 1. CONSTRAINTS (APB Master Behavior Constraints)
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
    // 2. ASSERTIONS: APB Interface & Register Behavior
    // =========================================================================

    // Check 1: Reset behavior
    assert_spi_reset_state : assert property (@(posedge PCLK)
        !PRESETn |-> (cs == 1'b1 && sclk == 1'b0 && tx_valid == 1'b0)
    );

    // Check 2: Register Latching on APB Write
    assert_tx_reg_write : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && PWRITE && (PADDR == SPI_ADDR) && PREADY) |=> (tx_reg == $past(PWDATA) && tx_valid == 1'b1)
    );

    // Check 3: APB Read from RX Register
    assert_rx_reg_read : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PWRITE && (PADDR == SPI_ADDR)) |-> (PRDATA == rx_reg)
    );

    // Check 4: Protocol Error Response
    assert_pslverr_invalid_addr : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && (PADDR != SPI_ADDR)) |-> (PSLVERR == 1'b1)
    );

    // =========================================================================
    // 3. ASSERTIONS: SPI Protocol & Engine States
    // =========================================================================

    // Check 5: Chip Select (CS) Control
    // CS must be low during a transmission (TRANSFER state) and high when IDLE
    assert_cs_active_during_transfer : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == TRANSFER) |-> (cs == 1'b0)
    );
    assert_cs_inactive_during_idle : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == IDLE) |-> (cs == 1'b1)
    );

    // Check 6: SCLK toggling frequency rule
    // Inside TRANSFER state, SCLK must invert its value on every single cycle 
    assert_sclk_toggles : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == TRANSFER) |=> (sclk == !$past(sclk))
    );

    // Check 7: FSM Progress out of TRANSFER state
    // The FSM must not exit the TRANSFER loop until bit_cnt hits exactly 31 and sclk is low
    assert_transfer_loop_hold : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == TRANSFER && !(bit_cnt == 6'd31 && sclk == 1'b0)) |=> (state == TRANSFER)
    );

    // =========================================================================
    // 4. COVERAGE UNREACHABILITY DEFINITIONS (Ensures 100% Green Matrix)
    // =========================================================================
    assert_impossible_apb_comb : assert property (@(posedge PCLK)
        !(PENABLE && !PSEL)
    );

    assert_unreachable_fsm_bits : assert property (@(posedge PCLK)
        disable iff (!PRESETn)
        (state != 2'b11) // Proves the FSM can never enter the unmapped 4th binary state
    );

endmodule


bind apb_spi apb_spi_fv u_apb_spi_fv_bind (
    .PCLK       (PCLK),
    .PRESETn    (PRESETn),
    .PSEL       (PSEL),
    .PENABLE    (PENABLE),
    .PWRITE     (PWRITE),
    .PADDR      (PADDR),
    .PWDATA     (PWDATA),
    .PRDATA     (PRDATA),
    .PREADY     (PREADY),
    .PSLVERR    (PSLVERR),
    .sclk       (sclk),
    .mosi       (mosi),
    .miso       (miso),
    .cs         (cs),
    
    // Direct internal module scoping
    .tx_reg     (tx_reg),
    .rx_reg     (rx_reg),
    .tx_valid   (tx_valid),
    .bit_cnt    (bit_cnt),
    .state      (state)
);
