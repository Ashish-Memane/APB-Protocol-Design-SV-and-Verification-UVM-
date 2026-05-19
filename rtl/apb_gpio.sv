
module apb_gpio (

    // APB INTERFACE SIGNALS
    input logic PCLK,
    input logic PRESETn,
    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,

    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,


    output logic [31:0] PRDATA,
    output logic PREADY,
    output logic PSLVERR,


    // GPIO INTERFACE SIGNALS
    input  logic [7:0] gpio_in,
    output logic [7:0] gpio_out,
    output logic [7:0] gpio_dir

);

  // registers declaration
  logic [7:0] gpio_out_reg;
  logic [7:0] gpio_dir_reg;

  //==================================================
  // ADDRESS MAP
  //==================================================
  // 0x00 : GPIO_OUT
  // 0x04 : GPIO_IN
  // 0x08 : GPIO_DIR
  //==================================================

  localparam GPIO_OUT_ADDR = 32'h0000_0000;
  localparam GPIO_IN_ADDR = 32'h0000_0004;
  localparam GPIO_DIR_ADDR = 32'h0000_0008;


  // APB write operation
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      gpio_out_reg <= 8'b0;
      gpio_dir_reg <= 8'b0;
    end else if (PSEL && PENABLE && PWRITE) begin
      case (PADDR)
        GPIO_OUT_ADDR: gpio_out_reg <= PWDATA[7:0];
        GPIO_DIR_ADDR: gpio_dir_reg <= PWDATA[7:0];
        default:
        // do nothing for invalid addresses
        ;
      endcase
    end
  end


  // APB read operation
  always_comb begin

    // default read data
    PRDATA = 32'h0000_0000;

    if (PSEL && !PWRITE) begin
      case (PADDR)
        GPIO_OUT_ADDR: PRDATA = {24'b0, gpio_out_reg};
        GPIO_IN_ADDR:  PRDATA = {24'b0, gpio_in};
        GPIO_DIR_ADDR: PRDATA = {24'b0, gpio_dir_reg};
        default:       PRDATA = 32'b0;  // return 0 for invalid addresses
      endcase
    end else begin
      PRDATA = 32'b0;  // default read data when not selected or during write
    end

  end


  // Assign outputs
  assign gpio_out = gpio_out_reg;
  assign gpio_dir = gpio_dir_reg;

  // APB ready and error signals
  always_comb begin
    PREADY = 1'b1;  // always ready for simplicity

    if (PSEL && PENABLE) begin
      case (PADDR)
        GPIO_OUT_ADDR, GPIO_IN_ADDR, GPIO_DIR_ADDR: PSLVERR = 1'b0;  // valid addresses
        default: PSLVERR = 1'b1;  // error for invalid addresses
      endcase
    end
  end
endmodule
