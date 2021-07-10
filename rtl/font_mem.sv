`timescale 1ns / 1ns

module font_mem(
    input [7:0] symbol_code, // ASCII code
    input [2:0] x,          // pixel x position
    input [3:0] y,          // pixel y position
    output glyph_set        // pixel on or off
  );

  (* ram_style = "block" *) byte glyph_mem [4095:0];

  initial
  begin
    $readmemh("vgafont.mem", glyph_mem);
  end

  /* verilator lint_off WIDTH */
  assign glyph_set = glyph_mem[symbol_code * 16 + y][7 - x];

endmodule
