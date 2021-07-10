`timescale 1ns / 1ns

module mandelbrot_engine (
    input logic clk,
    input logic reset,
    input logic [31:0] iterations_max,
    input logic signed [fp_bits - 1:0] x0,
    input logic signed [fp_bits - 1:0] y0,

    output logic finished,
    output logic [31:0] iterations
  );

  parameter fp_top = 8;
  parameter fp_bot = 24;

  localparam fp_bits = fp_top + fp_bot;

  localparam fp_d_c = fp_bits*2 - fp_top-1;


  enum {calc, finished_s} state;


  logic signed [fp_bits - 1:0] x;
  logic signed [fp_bits - 1:0] y;
  logic signed [fp_bits*2 - 1:0] y_tmp;
  logic signed [fp_bits*2 - 1:0] x2;
  logic signed [fp_bits*2 - 1:0] y2;

  initial
  begin
    state = calc;
  end

  always @ (posedge clk)
  begin
    if (reset == 1)
    begin
      state <= calc;
      finished <= 0;
      iterations <= 0;

      x <= 0;
      y <= 0;
      y_tmp <= 0;
      x2 <= 0;
      y2 <= 0;
    end
    else

    case (state)
      calc:
      begin
        // implicit pipeline
        // stage 1
        x <= x2[fp_d_c:fp_bot] - y2[fp_d_c:fp_bot] + x0;
        y <= y_tmp[fp_d_c:fp_bot] + y0;

        // stage 2
        y_tmp[fp_bits*2-1:1] <= x * y; // x * y * 2
        x2 <= x * x;
        y2 <= y * y;

        // stage 3
        if (iterations >= iterations_max ||
            x2[fp_d_c:fp_bot] + y2[fp_d_c:fp_bot] >= (fp_bits'('d4) << (fp_bot))) // x^2 + y^2 >= 4 ?
        begin
          state <= finished_s;
        end
        else
        begin
          iterations <= iterations + 1;
          state <= calc;
        end
      end
      finished_s:
      begin
        finished <= 1;
      end
    endcase
  end

endmodule
