`timescale 1ns / 1ns

module vga_console
  #(
     parameter console_size_bits = 5,
     parameter console_width = 32,
     parameter console_height = 16,
     parameter font_size_mult = 4
   )
   (
     input clk_write,
     input [7:0] append_char,
     input clear,
     input [11:0] pixel_x,
     input [11:0] pixel_y,
     output font_set
   );


  localparam buffer_size = $clog2(console_width * console_height);


  logic [buffer_size -1:0] write_index;
  byte text_buffer [0:console_width * console_height -1];


  logic [buffer_size -1:0] buffer_index;
  logic [7:0] symbol_code;
  logic [7:0] symbol_x;
  logic [7:0] symbol_y;
  logic [2:0] glyph_x;
  logic [3:0] glyph_y;
  logic inrange;
  logic glyph_set;

  /* verilator lint_off WIDTH */
  //assign symbol_x = pixel_x[11 -: 12 - font_size_mult - 3];
  //assign symbol_y = pixel_y[11 -: 12 - font_size_mult - 4];
  assign symbol_x = (pixel_x / font_size_mult) / 8;
  assign symbol_y = (pixel_y / font_size_mult) / 16;
  //assign symbol_x = pixel_x >> (font_size_mult + 3);
  //assign symbol_y = pixel_y >> (font_size_mult + 4);

  assign inrange = (symbol_x < console_width) && (symbol_y < console_height);
  assign buffer_index = {symbol_y[console_size_bits-1:0], symbol_x[console_size_bits-1:0]};
  //assign buffer_index = symbol_y * console_width + symbol_x;

  assign glyph_x = (pixel_x / font_size_mult) % 8;
  assign glyph_y = (pixel_y / font_size_mult) % 16;


  assign symbol_code = text_buffer[buffer_index];
  assign font_set = inrange ? glyph_set : 0;

  font_mem font(
             .x(glyph_x),
             .y(glyph_y),
             .symbol_code(symbol_code),
             .glyph_set(glyph_set)
           );


  always @(posedge clk_write)
  begin
    if(clear)
    begin
      text_buffer <= '{default:8'b0};
      write_index <= 0;
    end
    else if (append_char != 0)
    begin
      text_buffer[write_index] <= append_char;
      write_index <= write_index + 1;
    end

  end


endmodule
