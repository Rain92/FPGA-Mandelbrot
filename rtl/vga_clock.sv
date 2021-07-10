`timescale 1ns / 1ns

module vga_clock
  #(
     parameter int VIDEO_ID_CODE = 1
   )
   (
     input logic clk_33,
     output logic clk_pixel
   );
  wire unused;
  generate
    case (VIDEO_ID_CODE)
      1:
        mmcm_xilinx  #(.MULT_F(21.625), .DIVCLK_DIVIDE(1), .DIV1_F(28.625), .CLKIN_PERIOD(30)) clk_cnv(.clk_in(clk_33), .clk_out1(clk_pixel), .clk_out2(unused));
      2:
        mmcm_xilinx  #(.MULT_F(30.000), .DIVCLK_DIVIDE(1), .DIV1_F(25.000), .CLKIN_PERIOD(30)) clk_cnv(.clk_in(clk_33), .clk_out1(clk_pixel), .clk_out2(unused));
      3:
        mmcm_xilinx  #(.MULT_F(29.250), .DIVCLK_DIVIDE(1), .DIV1_F(15.000), .CLKIN_PERIOD(30)) clk_cnv(.clk_in(clk_33), .clk_out1(clk_pixel), .clk_out2(unused));
      4:
        mmcm_xilinx  #(.MULT_F(62.375), .DIVCLK_DIVIDE(1), .DIV1_F(7.000),  .CLKIN_PERIOD(30)) clk_cnv(.clk_in(clk_33), .clk_out1(clk_pixel), .clk_out2(unused));
    endcase
  endgenerate
endmodule
