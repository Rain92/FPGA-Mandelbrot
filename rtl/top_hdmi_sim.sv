`timescale 1ns / 1ns

module top_hdmi_sim (
    input CLOCK_50,

    output [2:0] HDMI_TX,
    output [2:0] HDMI_TX_N,
    output HDMI_CLK,
    output HDMI_CLK_N,

    input PS2_CLOCK,
    input PS2_DATA,

    output logic [23:0] rgb,
    output logic [w_bit_max:0] cx,
    output logic [h_bit_max:0] cy,
    output logic [w_bit_max:0] screen_width,
    output logic [h_bit_max:0] screen_height
  );

  assign HDMI_TX = 0;
  assign HDMI_TX_N = 0;
  assign HDMI_CLK = 0;
  assign HDMI_CLK_N = 0;

  logic [w_bit_max:0] frame_width;
  logic [h_bit_max:0] frame_height;

  localparam USE_XILINX_BLOCKRAM = 0;

  localparam key_up = "v";
  localparam key_down = "i";
  localparam key_left = "u";
  localparam key_right = "a";
  localparam key_zoom_in = "x";
  localparam key_zoom_out = "l";
  localparam key_iter_up = "c";
  localparam key_iter_down = "e";

  localparam num_engines = 8;

  localparam calc_clock_mult = 30;
  localparam calc_clock_div = 10;

  localparam width = 1280;
  localparam height = 720;

  localparam dimension_bits = $clog2(width - 1);
  localparam data_bits = 4;

  localparam fp_top = 6;
  localparam fp_bot = 26;


  // 1:  640x480     25.2  MHz
  // 4:  1280x720    74.25 MHz
  // 16: 1920x1080  148.5  MHz
  localparam vidio_id_code = 4;
  localparam w_bit_max = vidio_id_code == 1? 9 : 10;
  localparam h_bit_max = vidio_id_code <= 4? 9 : 10;


  wire clk_calc = CLOCK_50;
  wire clk_pixel = CLOCK_50;
  wire clk_pixel_x5 = CLOCK_50;

  logic [2:0] tmds;
  logic tmds_clock;

  /* verilator lint_off PINCONNECTEMPTY */
  hdmi_sim_dummy #(.VIDEO_ID_CODE(vidio_id_code), .VIDEO_REFRESH_RATE(60), .DVI_OUTPUT(1)) hdmi(
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


  /* verilator lint_off WIDTH */
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
