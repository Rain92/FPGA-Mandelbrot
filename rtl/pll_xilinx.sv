`timescale 1ns / 1ns

module pll_xilinx
  #(parameter MULT = 39, DIV = 20, CLKIN_PERIOD = 30.0)

   (
     input         clk_in,
     output        clk_out
   );

  wire clkfbout_buf;
  wire clkfbout;
  wire clk_out_;

  /* verilator lint_off PINCONNECTEMPTY */

  PLLE2_ADV
    #(.BANDWIDTH            ("OPTIMIZED"),
      .COMPENSATION         ("ZHOLD"),
      .STARTUP_WAIT         ("FALSE"),
      .DIVCLK_DIVIDE        (1),
      .CLKFBOUT_MULT        (MULT),
      .CLKFBOUT_PHASE       (0.000),
      .CLKOUT0_DIVIDE       (DIV),
      .CLKOUT0_PHASE        (0.000),
      .CLKOUT0_DUTY_CYCLE   (0.500),
      .CLKIN1_PERIOD        (CLKIN_PERIOD))
    plle2_adv_inst
    // Output clocks
    (
      .CLKFBOUT            (clkfbout),
      .CLKOUT0             (clk_out_),
      .CLKOUT1             (clkout1_unused),
      .CLKOUT2             (clkout2_unused),
      .CLKOUT3             (clkout3_unused),
      .CLKOUT4             (clkout4_unused),
      .CLKOUT5             (clkout5_unused),
      // Input clock control
      .CLKFBIN             (clkfbout_buf),
      .CLKIN1              (clk_in),
      .CLKIN2              (1'b0),
      // Tied to always select the primary input clock
      .CLKINSEL            (1'b1),
      // Ports for dynamic reconfiguration
      .DADDR               (7'h0),
      .DCLK                (1'b0),
      .DEN                 (1'b0),
      .DI                  (16'h0),
      .DO                  (),
      .DRDY                (),
      .DWE                 (1'b0),
      // Other control and status signals
      .LOCKED              (),
      .PWRDWN              (1'b0),
      .RST                 (1'b0));

  // Clock Monitor clock assigning
  //--------------------------------------
  // Output buffering
  //-----------------------------------

  BUFG clkf_buf
       (.O (clkfbout_buf),
        .I (clkfbout));






  BUFG clkout1_buf
       (.O   (clk_out),
        .I   (clk_out_));


endmodule
