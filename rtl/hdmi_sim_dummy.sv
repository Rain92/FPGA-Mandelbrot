// Implementation of HDMI Spec v1.4a
// Based on https://github.com/sameer

module hdmi_sim_dummy
  #(
     // Defaults to 640x480 which should be supported by almost if not all HDMI sinks.
     // See README.md or CEA-861-D for enumeration of video id codes.
     // Pixel repetition, interlaced scans and other special output modes are not implemented (yet).
     parameter int VIDEO_ID_CODE = 1,

     // Defaults to minimum bit lengths required to represent positions.
     // Modify these parameters if you have alternate desired bit lengths.
     parameter int BIT_WIDTH = VIDEO_ID_CODE < 4 ? 10 : VIDEO_ID_CODE == 4 ? 11 : 12,
     parameter int BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 11: 10,

     // A true HDMI signal sends auxiliary data (i.e. audio, preambles) which prevents it from being parsed by DVI signal sinks.
     // HDMI signal sinks are fortunately backwards-compatible with DVI signals.
     // Enable this flag if the output should be a DVI signal. You might want to do this to reduce resource usage or if you're only outputting video.
     parameter bit DVI_OUTPUT = 1'b0,

     // **All parameters below matter ONLY IF you plan on sending auxiliary data (DVI_OUTPUT == 1'b0)**

     // Specify the refresh rate in Hz you are using for audio calculations
     parameter real VIDEO_REFRESH_RATE = 59.94,

     // As specified in Section 7.3, the minimal audio requirements are met: 16-bit or more L-PCM audio at 32 kHz, 44.1 kHz, or 48 kHz.
     // See Table 7-4 or README.md for an enumeration of sampling frequencies supported by HDMI.
     // Note that sinks may not support rates above 48 kHz.
     parameter int AUDIO_RATE = 44100,

     // Defaults to 16-bit audio, the minmimum supported by HDMI sinks. Can be anywhere from 16-bit to 24-bit.
     parameter int AUDIO_BIT_WIDTH = 16,

     // Some HDMI sinks will show the source product description below to users (i.e. in a list of inputs instead of HDMI 1, HDMI 2, etc.).
     // If you care about this, change it below.
     parameter bit [8*8-1:0] VENDOR_NAME = {"Unknown", 8'd0}, // Must be 8 bytes null-padded 7-bit ASCII
     parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = {"FPGA", 96'd0}, // Must be 16 bytes null-padded 7-bit ASCII
     parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 8'h00 // See README.md or CTA-861-G for the list of valid codes
   )
   (
     input logic clk_pixel_x5,
     input logic clk_pixel,
     input logic clk_audio,
     // synchronous reset back to 0,0
     input logic reset,
     input logic [23:0] rgb,
     input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],

     // These outputs go to your HDMI port
     output logic [2:0] tmds,
     output logic tmds_clock,

     // All outputs below this line stay inside the FPGA
     // They are used (by you) to pick the color each pixel should have
     // i.e. always_ff @(posedge pixel_clk) rgb <= {8'd0, 8'(cx), 8'(cy)};
     output logic [BIT_WIDTH-1:0] cx = BIT_WIDTH'(0),
     output logic [BIT_HEIGHT-1:0] cy = BIT_HEIGHT'(0),

     // The screen is at the upper left corner of the frame.
     // 0,0 = 0,0 in video
     // the frame includes extra space for sending auxiliary data
     output logic [BIT_WIDTH-1:0] frame_width,
     output logic [BIT_HEIGHT-1:0] frame_height,
     output logic [BIT_WIDTH-1:0] screen_width,
     output logic [BIT_HEIGHT-1:0] screen_height
   );

  localparam int NUM_CHANNELS = 3;
  logic hsync;
  logic vsync;

  logic [BIT_WIDTH-1:0] hsync_porch_start, hsync_porch_size;
  logic [BIT_HEIGHT-1:0] vsync_porch_start, vsync_porch_size;
  logic invert;

  // See CEA-861-D for more specifics formats described below.
  generate
    case (VIDEO_ID_CODE)
      1:
      begin
        assign frame_width = 800;
        assign frame_height = 525;
        assign screen_width = 640;
        assign screen_height = 480;
        assign hsync_porch_start = 16;
        assign hsync_porch_size = 96;
        assign vsync_porch_start = 10;
        assign vsync_porch_size = 2;
        assign invert = 1;
      end
      2, 3:
      begin
        assign frame_width = 858;
        assign frame_height = 525;
        assign screen_width = 720;
        assign screen_height = 480;
        assign hsync_porch_start = 16;
        assign hsync_porch_size = 62;
        assign vsync_porch_start = 9;
        assign vsync_porch_size = 6;
        assign invert = 1;
      end
      4:
      begin
        assign frame_width = 1650;
        assign frame_height = 750;
        assign screen_width = 1280;
        assign screen_height = 720;
        assign hsync_porch_start = 110;
        assign hsync_porch_size = 40;
        assign vsync_porch_start = 5;
        assign vsync_porch_size = 5;
        assign invert = 0;
      end
      16, 34:
      begin
        assign frame_width = 2200;
        assign frame_height = 1125;
        assign screen_width = 1920;
        assign screen_height = 1080;
        assign hsync_porch_start = 88;
        assign hsync_porch_size = 44;
        assign vsync_porch_start = 4;
        assign vsync_porch_size = 5;
        assign invert = 0;
      end
      17, 18:
      begin
        assign frame_width = 864;
        assign frame_height = 625;
        assign screen_width = 720;
        assign screen_height = 576;
        assign hsync_porch_start = 12;
        assign hsync_porch_size = 64;
        assign vsync_porch_start = 5;
        assign vsync_porch_size = 5;
        assign invert = 1;
      end
      19:
      begin
        assign frame_width = 1980;
        assign frame_height = 750;
        assign screen_width = 1280;
        assign screen_height = 720;
        assign hsync_porch_start = 440;
        assign hsync_porch_size = 40;
        assign vsync_porch_start = 5;
        assign vsync_porch_size = 5;
        assign invert = 0;
      end
      95, 105, 97, 107:
      begin
        assign frame_width = 4400;
        assign frame_height = 2250;
        assign screen_width = 3840;
        assign screen_height = 2160;
        assign hsync_porch_start = 176;
        assign hsync_porch_size = 88;
        assign vsync_porch_start = 8;
        assign vsync_porch_size = 10;
        assign invert = 0;
      end
    endcase
    assign hsync = invert ^ (cx >= screen_width + hsync_porch_start && cx < screen_width + hsync_porch_start + hsync_porch_size);
    assign vsync = invert ^ (cy >= screen_height + vsync_porch_start && cy < screen_height + vsync_porch_start + vsync_porch_size);
  endgenerate

  localparam real VIDEO_RATE = (VIDEO_ID_CODE == 1 ? 25.2E6
                                : VIDEO_ID_CODE == 2 || VIDEO_ID_CODE == 3 ? 27.027E6
                                : VIDEO_ID_CODE == 4 ? 74.25E6
                                : VIDEO_ID_CODE == 16 ? 148.5E6
                                : VIDEO_ID_CODE == 17 || VIDEO_ID_CODE == 18 ? 27E6
                                : VIDEO_ID_CODE == 19 ? 74.25E6
                                : VIDEO_ID_CODE == 34 ? 74.25E6
                                : VIDEO_ID_CODE == 95 || VIDEO_ID_CODE == 105 || VIDEO_ID_CODE == 97 || VIDEO_ID_CODE == 107 ? 594E6
                                : 0) * (VIDEO_REFRESH_RATE == 59.94 || VIDEO_REFRESH_RATE == 29.97 ? 1000.0/1001.0 : 1); // https://groups.google.com/forum/#!topic/sci.engr.advanced-tv/DQcGk5R_zsM

  // Wrap-around pixel position counters indicating the pixel to be generated by the user in THIS clock and sent out in the NEXT clock.
  always_ff @(posedge clk_pixel)
  begin
    if (reset)
    begin
      cx <= BIT_WIDTH'(0);
      cy <= BIT_HEIGHT'(0);
    end
    else
    begin
      cx <= cx == frame_width-1'b1 ? BIT_WIDTH'(0) : cx + 1'b1;
cy <= cx == frame_width-1'b1 ? cy == frame_height-1'b1 ? BIT_HEIGHT'(0) : cy + 1'b1 : cy;
    end
  end

  assign tmds = 0;
  assign tmds_clock = 0;

endmodule
