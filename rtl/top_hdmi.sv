`timescale 1ns / 1ns

module top_hdmi (
    input CLOCK_50,

    output [2:0] HDMI_TX,
    output [2:0] HDMI_TX_N,
    output HDMI_CLK,
    output HDMI_CLK_N,

    input PS2_CLOCK,
    input PS2_DATA
  );

  localparam USE_XILINX_BLOCKRAM = 1;

  localparam key_up = "w";
  localparam key_down = "s";
  localparam key_left = "a";
  localparam key_right = "d";
  localparam key_zoom_in = "q";
  localparam key_zoom_out = "e";
  localparam key_iter_up = "r";
  localparam key_iter_down = "f";

  localparam screen_div = 1;
  localparam num_engines = 4;

  localparam calc_clock_mult = 30;
  localparam calc_clock_div = 12;

  localparam width = 1280/screen_div;
  localparam height = 720/screen_div;

  localparam dimension_bits = $clog2(width - 1);
  localparam data_bits = 4;

  localparam fp_top = 6;
  localparam fp_bot = 68;


  // 1:  640x480     25.2  MHz
  // 4:  1280x720    74.25 MHz
  // 16: 1920x1080  148.5  MHz
  localparam vidio_id_code = 4;
  localparam w_bit_max = vidio_id_code == 1? 9 : 10;
  localparam h_bit_max = vidio_id_code <= 4? 9 : 10;


  wire clk_calc;
  wire clk_pixel;
  wire clk_pixel_x5;

  pll_xilinx #(.MULT(calc_clock_mult), .DIV(calc_clock_div), .CLKIN_PERIOD(30.0)) pll1
             (
               .clk_in(CLOCK_50),
               .clk_out(clk_calc)
             );

  hdmi_clock #(.VIDEO_ID_CODE(vidio_id_code)) hdmi_clock (.clk_50(CLOCK_50), .clk_pixel(clk_pixel), .clk_pixel_x5(clk_pixel_x5));


  logic [23:0] rgb;
  logic [w_bit_max:0] cx;
  logic [h_bit_max:0] cy;
  logic [w_bit_max:0] screen_width;
  logic [h_bit_max:0] screen_height;

  logic [w_bit_max:0] frame_width;
  logic [h_bit_max:0] frame_height;
  logic [2:0] tmds;
  logic tmds_clock;


  genvar i;
  generate
    for (i = 0; i < 3; i++)
    begin: obufds_gen
      OBUFDS #(.IOSTANDARD("TMDS_33")) obufds (.I(tmds[i]), .O(HDMI_TX[i]), .OB(HDMI_TX_N[i]));
    end
    OBUFDS #(.IOSTANDARD("TMDS_33")) obufds_clock(.I(tmds_clock), .O(HDMI_CLK), .OB(HDMI_CLK_N));
  endgenerate

  hdmi  #(.VIDEO_ID_CODE(vidio_id_code), .VIDEO_REFRESH_RATE(60), .DVI_OUTPUT(1)) hdmi(
          .clk_pixel_x5(clk_pixel_x5),
          .clk_pixel(clk_pixel),
          .clk_audio(),
          .reset(),
          .rgb(rgb),
          .audio_sample_word(),
          .tmds(tmds),
          .tmds_clock(tmds_clock),
          .cx(cx),
          .cy(cy),
          .frame_width(frame_width),
          .frame_height(frame_height),
          .screen_width(screen_width),
          .screen_height(screen_height)
        );


  reg [dimension_bits*2 - 1:0] read_addr;
  wire [data_bits-1:0] read_data;
  reg  read_en;

  top_common #
    (
      .USE_XILINX_BLOCKRAM(USE_XILINX_BLOCKRAM),
      .clk_sys_freq(50000000),
      .key_up(key_up),
      .key_down(key_down),
      .key_left(key_left),
      .key_right(key_right),
      .key_zoom_in(key_zoom_in),
      .key_zoom_out(key_zoom_out),
      .key_iter_up(key_iter_up),
      .key_iter_down(key_iter_down),
      .num_engines(num_engines),
      .width(width),
      .height(height),
      .fp_top(fp_top),
      .fp_bot(fp_bot)
    ) top_common (
      .clk_sys(CLOCK_50),
      .clk_calc(clk_calc),
      .clk_pixel(clk_pixel),

      .read_en(read_en),
      .read_addr(read_addr),
      .read_data(read_data),

      .PS2_CLOCK(PS2_CLOCK),
      .PS2_DATA(PS2_DATA)
    );


  logic [23:0] palette[0:15] = '{24'h421e0f,
                                 24'h19071a,
                                 24'h09012f,
                                 24'h040449,
                                 24'h000764,
                                 24'h0c2c8a,
                                 24'h1852b1,
                                 24'h397dd1,
                                 24'h86b5e5,
                                 24'hd3ecf8,
                                 24'hf1e9bf,
                                 24'hf8c95f,
                                 24'hffaa00,
                                 24'hcc8000,
                                 24'h995700,
                                 24'h6a3403};

  // compensate for 2 cycle read delay
  localparam int read_delay = 2;

  // rgb buffer
  always @(posedge clk_pixel)
  begin
    if (cx >= frame_width - read_delay && cy == frame_height - 1)
    begin
      read_addr <= frame_width - cx;
      read_en <= 1'b1;
    end
    else if (cx < width && cy < height)
    begin
      read_addr <= cy*width + cx + read_delay;
      read_en <= 1'b1;
    end

    if (cx < width && cy < height)
    begin
      rgb <= palette[read_data];
    end
    else
    begin
      rgb <= 24'b0;
    end
  end

endmodule
