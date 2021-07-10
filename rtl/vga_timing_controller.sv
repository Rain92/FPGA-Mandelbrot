`timescale 1ns / 1ns

module vga_timing_controller
  #(parameter BITWIDTH = 0, H_RES = 0, H_FRONT_PORCH = 0, H_SYNC_WIDTH = 0, H_BACK_PORCH = 0, V_RES = 0, V_FRONT_PORCH = 0, V_SYNC_WIDTH = 0, V_BACK_PORCH = 0, HS_PULSE_POLARITY = 0, VS_PULSE_POLARITY = 0)
   (
     input clk,
     output logic vga_hsync,
     output logic vga_vsync,
     output logic [BITWIDTH - 1:0] vga_x,
     output logic [BITWIDTH - 1:0] vga_y,
     output logic video_active
   );

  localparam H_SYNC_START = H_RES + H_FRONT_PORCH;
  localparam H_SYNC_STOP = H_SYNC_START + H_SYNC_WIDTH;
  localparam H_MAX = H_SYNC_STOP + H_BACK_PORCH;

  localparam V_SYNC_START = V_RES + V_FRONT_PORCH;
  localparam V_SYNC_STOP = V_SYNC_START + V_SYNC_WIDTH;
  localparam V_MAX = V_SYNC_STOP + V_BACK_PORCH;

  initial
  begin
    vga_x = 0;
    vga_y = 0;
  end

  always @ (posedge clk)
  begin
    if (vga_x == (H_MAX - 1))
    begin
      vga_x <= 0;
      if (vga_y == (V_MAX - 1))
        vga_y <= 0;
      else
        vga_y <= vga_y + 1;
    end
    else
      vga_x <= vga_x + 1;
  end

  assign vga_hsync = HS_PULSE_POLARITY ^ ((vga_x >= H_SYNC_START) && (vga_x < H_SYNC_STOP)) ? 1'b0 : 1'b1;

  assign vga_vsync = VS_PULSE_POLARITY ^ ((vga_y >= V_SYNC_START) && (vga_y < V_SYNC_STOP)) ? 1'b0 : 1'b1;

  assign video_active = (vga_x < H_RES) && (vga_y < V_RES);

endmodule
