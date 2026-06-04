module apb_master_fv (
    input logic        PCLK,
    input logic        PRESETn,

    // Control Interface
    input logic        start,
    input logic        rw,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic [31:0] rdata,
    input logic        done,
    input logic        err,

    // APB Bus Outputs (To be Asserted)
    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,
    input logic        PWRITE,
    input logic        PENABLE,
    input logic        PSEL,

    // APB Bus Inputs (To be Assumed)
    input logic [31:0] PRDATA,
    input logic        PREADY,
    input logic        PSLVERR,

    // Internal FSM State monitored via Bind
    input logic [1:0]  state
);

    // APB State Decodes matching RTL
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    // =========================================================================
    // 1. CONSTRAINTS (Modeling Reactive Slave Behavior via Assumptions)
    // =========================================================================

    // Slave must keep PREADY low if the master isn't in an active phase
    assume_pready_low_in_idle : assume property (@(posedge PCLK)
        (state == IDLE) |-> (PREADY == 1'b0)
    );

    // Protocol stability: Slave response wires must be stable until PREADY goes high
    assume_slave_response_stable : assume property (@(posedge PCLK)
        (state == ACCESS && !PREADY) |=> ($stable(PSLVERR) && $stable(PRDATA))
    );

    // =========================================================================
    // 2. ASSERTIONS: AMBA APB Protocol Compliancy
    // =========================================================================

    // Check 1: Reset Initialization Verification
    assert_master_reset_state : assert property (@(posedge PCLK)
        !PRESETn |-> (PSEL == 1'b0 && PENABLE == 1'b0 && done == 1'b0 && err == 1'b0 && state == IDLE)
    );

    // Check 2: Setup Phase Properties
    // In SETUP state, PSEL must be high, PENABLE must be low.
    assert_setup_phase_signals : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == SETUP) |-> (PSEL == 1'b1 && PENABLE == 1'b0)
    );

    // Check 3: Access Phase Transition
    // From SETUP, the master must immediately jump to ACCESS on the next cycle and assert PENABLE.
    assert_setup_to_access_transition : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == SETUP) |=> (state == ACCESS && PENABLE == 1'b1 && PSEL == 1'b1)
    );

    // Check 4: Access Phase Hold Stalls
    // If the slave drops PREADY, the master must hold its state and keep address/control bus constant.
    assert_access_stall_behavior : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == ACCESS && !PREADY) |=> (state == ACCESS && $stable(PADDR) && $stable(PWDATA) && $stable(PWRITE))
    );

    // Check 5: Transaction Termination Matrix
    // When PREADY is high in ACCESS state, the master must return to IDLE next cycle.
    assert_access_to_idle_on_ready : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == ACCESS && PREADY) |=> (state == IDLE && PSEL == 1'b0 && PENABLE == 1'b0)
    );

    // =========================================================================
    // 3. ASSERTIONS: User Control Interface Checkers
    // =========================================================================

    // Check 6: Protocol Command Latching
    assert_command_loading : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == IDLE && start) |=> (PADDR == $past(addr) && PWDATA == $past(wdata) && PWRITE == $past(rw))
    );

    // Check 7: Done Flag Synchronization
    // 'done' handshaking flag must spike exactly when a valid transaction completes
    assert_done_flag_generation : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == ACCESS && PREADY) |=> (done == 1'b1)
    );

    // Check 8: Error Capture Synchronization
    assert_error_handling : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == ACCESS && PREADY && PSLVERR) |=> (err == 1'b1)
    );

    // Check 9: Read Data Register Sample Verification
    assert_rdata_sample : assert property (@(posedge PCLK) disable iff (!PRESETn)
        (state == ACCESS && PREADY && !PWRITE) |=> (rdata == $past(PRDATA))
    );

    // =========================================================================
    // 4. COVERAGE UNREACHABILITY ASSURANCES
    // =========================================================================
    assert_unreachable_fsm_bits : assert property (@(posedge PCLK)
        disable iff (!PRESETn)
        (state != 2'b11) // Clears implicit default coverage hole
    );

endmodule


bind apb_master apb_master_fv u_apb_master_fv_bind (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    
    // Control Interface
    .start   (start),
    .rw      (rw),
    .addr    (addr),
    .wdata   (wdata),
    .rdata   (rdata),
    .done    (done),
    .err     (err),

    // APB Interface
    .PADDR   (PADDR),
    .PWDATA  (PWDATA),
    .PWRITE  (PWRITE),
    .PENABLE (PENABLE),
    .PSEL    (PSEL),
    .PRDATA  (PRDATA),
    .PREADY  (PREADY),
    .PSLVERR (PSLVERR),
    
    // Internal FSM monitor hookup
    .state   (state)
);
