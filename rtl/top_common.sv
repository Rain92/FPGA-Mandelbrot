`timescale 1ns / 1ns

module top_common (
    input clk_sys,
    input clk_calc,
    input clk_pixel,

    input logic read_en,
    input logic [dimension_bits*2 - 1:0] read_addr,
    output logic [data_bits-1:0] read_data,

    input PS2_CLOCK,
    input PS2_DATA
  );

  parameter USE_XILINX_BLOCKRAM = 0;
  parameter clk_sys_freq = 33333333;


  parameter key_up = "w";
  parameter key_down = "s";
  parameter key_left = "a";
  parameter key_right = "d";
  parameter key_zoom_in = "q";
  parameter key_zoom_out = "e";
  parameter key_iter_up = "r";
  parameter key_iter_down = "f";

  parameter num_engines = 4;

  parameter width = 1024;
  parameter height = 768;

  parameter fp_top = 6;
  parameter fp_bot = 44;

  localparam fp_bits = fp_top + fp_bot;

  localparam width_max = width - 1;
  localparam height_max = height - 1;
  localparam dimension_bits = $clog2(width_max);
  localparam data_bits = 4;


  reg [dimension_bits*2 - 1:0] write_addr;
  reg [data_bits-1:0] write_data;
  reg write_en;


  wire ascii_new;
  logic key_pressed;
  wire [7:0] ascii_code;

  ps2_keyboard_to_ascii #(
                          .clk_freq(clk_sys_freq),
                          .ps2_debounce_counter_size(8)
                        )
                        keyboard (
                          .clk(clk_sys),
                          .ps2_clk(PS2_CLOCK),
                          .ps2_data(PS2_DATA),
                          .ascii_new(ascii_new),
                          .key_pressed(key_pressed),
                          .ascii_code(ascii_code)
                        );



  reg signed [fp_bits - 1:0] calc_x0_offset;
  reg signed [fp_bits - 1:0] calc_y0_offset;

  logic calc_reset;
  logic calc_finished;

  reg [31:0] iterations_max = 128;

  reg [6:0] calc_zoom = 2;

  initial
  begin
    calc_x0_offset = -(fp_bits'('b00_11) << (fp_bot-2));
    calc_y0_offset = -(fp_bits'('b00_10) << (fp_bot-2));
  end


  mandelbrot_renderer#(
                       .USE_XILINX_BLOCKRAM(USE_XILINX_BLOCKRAM),
                       .width(width),
                       .height(height),
                       .data_bits(data_bits),
                       .fp_top(fp_top),
                       .fp_bot(fp_bot),
                       .num_engines(num_engines)
                     ) mandelbrot_renderer1 (
                       .clk_calc(clk_calc),
                       .reset(calc_reset),
                       .zoom(calc_zoom),
                       .iterations_max(iterations_max),
                       .x0_offset(calc_x0_offset),
                       .y0_offset(calc_y0_offset),
                       .finished(calc_finished),

                       .read_clk(clk_pixel),
                       .read_en(read_en),
                       .read_addr(read_addr),
                       .read_data(read_data)
                     );


  wire [fp_bits-1:0] move_offset = (fp_bot-2 > calc_zoom) ? fp_bits'('b1) << (fp_bot-2-calc_zoom) : fp_bits'('b1);
  always @ (posedge clk_sys)
  begin
    if (ascii_new && key_pressed)
    begin
      if (ascii_code == key_up)
        calc_y0_offset <= calc_y0_offset - move_offset;
      else if (ascii_code == key_down)
        calc_y0_offset <= calc_y0_offset + move_offset;
      else if (ascii_code == key_left)
        calc_x0_offset <= calc_x0_offset - move_offset;
      else if (ascii_code == key_right)
        calc_x0_offset <= calc_x0_offset + move_offset;

      else if (ascii_code == key_zoom_in && calc_zoom != (2<<7) - 1)
      begin
        calc_zoom <= calc_zoom + 1;
      end
      else if (ascii_code == key_zoom_out && calc_zoom != 0)
      begin
        calc_zoom <= calc_zoom - 1;
      end

      else if (ascii_code == key_iter_up)
        iterations_max <= iterations_max << 1;
      else if (ascii_code == key_iter_down && iterations_max != 1)
        iterations_max <= iterations_max >> 1;

      else
        $display("%d", ascii_code);
      $display("zoom: %d iterations: %d", calc_zoom, iterations_max);

      calc_reset <= 1;
    end
    else
    begin
      calc_reset <= 0;
    end
  end

endmodule
