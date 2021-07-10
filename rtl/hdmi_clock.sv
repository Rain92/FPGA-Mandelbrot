`timescale 1ns / 1ns

module hdmi_clock
  #(
     parameter int VIDEO_ID_CODE = 1
   )
   (
     input logic clk_50,
     output logic clk_pixel,
     output logic clk_pixel_x5
   );
  generate
    case (VIDEO_ID_CODE)
      1:  // 640x480 25.2MHz
        mmcm_xilinx  #(.MULT_F(63.000), .DIVCLK_DIVIDE(5), .DIV1_F(25.0), .DIV2(5), .CLKIN_PERIOD(20.0))
        clk_cnv (.clk_in(clk_50), .clk_out1(clk_pixel), .clk_out2(clk_pixel_x5));
      4:  // 1280x720 74.25MHz
        mmcm_xilinx  #(.MULT_F(59.375), .DIVCLK_DIVIDE(4), .DIV1_F(10.0), .DIV2(2), .CLKIN_PERIOD(20.0))
        clk_cnv (.clk_in(clk_50), .clk_out1(clk_pixel), .clk_out2(clk_pixel_x5));
      16:  // 1920x1080  	148.5MHz
        mmcm_xilinx  #(.MULT_F(59.375), .DIVCLK_DIVIDE(4), .DIV1_F(5.0), .DIV2(1), .CLKIN_PERIOD(20.0))
        clk_cnv (.clk_in(clk_50), .clk_out1(clk_pixel), .clk_out2(clk_pixel_x5));
    endcase
  endgenerate
endmodule
