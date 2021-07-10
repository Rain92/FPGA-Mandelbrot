`timescale 1ns / 1ns

// VIDEO_ID_CODE = 1:
// VGA 640 x 480 x 60Hz
// clock 25.175MHz
//
// VIDEO_ID_CODE = 2:
// VGA 800 x 600 x 60Hz
// clock 40MHz
//
// VIDEO_ID_CODE = 3:
// VGA 1024 x 768 x 60Hz
// clock 65MHz
//
// VIDEO_ID_CODE = 4:
// VGA 1920 x 1080 x 60Hz
// clock 148.5 MHz

module vga_timing_controller_preset
  #(
     parameter int VIDEO_ID_CODE = 1
   )
   (
     input wire clk_pixel,
     output wire vga_hsync,
     output wire vga_vsync,
     output wire [11:0] vga_x,
     output wire [11:0] vga_y,
     output wire video_active,
     output wire [11:0] screen_width,
     output wire [11:0] screen_height,
     output wire [11:0] frame_width,
     output wire [11:0] frame_height
   );
  generate
    case (VIDEO_ID_CODE)
      1:
      begin
        vga_timing_controller #(12, 640, 16, 96, 48, 480, 10, 2, 33, 0, 0) vga (
          .clk(clk_pixel),
          .vga_x(vga_x),
          .vga_y(vga_y),
          .vga_hsync(vga_hsync),
          .vga_vsync(vga_vsync),
          .video_active(video_active)
        );
        assign screen_width = 640;
        assign screen_height = 480;
        assign frame_width = 640 + 16 + 96 + 48;
        assign frame_height = 480 + 10 + 2 + 33;
      end
      2:
      begin
        vga_timing_controller #(12, 800, 40, 128, 88, 600, 1, 4, 23, 1, 1) vga (
          .clk(clk_pixel),
          .vga_x(vga_x),
          .vga_y(vga_y),
          .vga_hsync(vga_hsync),
          .vga_vsync(vga_vsync),
          .video_active(video_active)
        );
        assign screen_width = 800;
        assign screen_height = 600;
        assign frame_width = 800 + 40 + 128 + 88;
        assign frame_height = 600 + 1 + 4 + 23;
      end
      3:
      begin
        vga_timing_controller #(12, 1024, 24, 136, 160, 768, 3, 6, 29, 0, 0) vga (
          .clk(clk_pixel),
          .vga_x(vga_x),
          .vga_y(vga_y),
          .vga_hsync(vga_hsync),
          .vga_vsync(vga_vsync),
          .video_active(video_active)
        );
        assign screen_width = 1024;
        assign screen_height = 768;
        assign frame_width = 1024 + 24 + 136 + 160;
        assign frame_height = 768 + 3 + 6 + 29;
      end
      4:
      begin
        vga_timing_controller #(12, 1920, 88, 44, 148, 1080, 4, 5, 36, 1, 1) vga (
          .clk(clk_pixel),
          .vga_x(vga_x),
          .vga_y(vga_y),
          .vga_hsync(vga_hsync),
          .vga_vsync(vga_vsync),
          .video_active(video_active)
        );
        assign screen_width = 1920;
        assign screen_height = 1080;
        assign frame_width = 1920 + 88 + 44 + 148;
        assign frame_height = 1080 + 4 + 5 + 36;
      end
    endcase
  endgenerate
endmodule

