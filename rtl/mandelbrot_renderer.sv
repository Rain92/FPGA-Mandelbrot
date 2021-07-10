`timescale 1ns / 1ns

`define max2(v1, v2) ((v1) > (v2) ? (v1) : (v2))

module mandelbrot_renderer (
    input logic clk_calc,
    input logic reset,
    input logic [6:0] zoom,
    input logic [31:0] iterations_max,
    input logic signed [fp_bits - 1:0] x0_offset,
    input logic signed [fp_bits - 1:0] y0_offset,
    output logic finished,

    input logic read_clk,
    input logic read_en,
    input logic [dimension_bits*2 - 1:0] read_addr,
    output logic [data_bits-1:0] read_data
  );
  parameter num_engines = 2;
  parameter num_engines_bits = $clog2(num_engines);

  parameter USE_XILINX_BLOCKRAM = 0;
  parameter width = 1024;
  parameter height = 768;

  localparam width_max = width - 1;
  localparam height_max = height - 1;

  localparam dimension_bits = $clog2(width -1);
  parameter data_bits = 4;

  parameter fp_top = 8;
  parameter fp_bot = 24;

  localparam fp_bits = fp_top + fp_bot;

  localparam fp_d_c = fp_bits*2 - fp_top-1;

  reg [dimension_bits*2 - 1:0] write_addr;
  reg [data_bits-1:0] write_data;
  reg write_en;


  reg [dimension_bits-1:0] cx;
  reg [dimension_bits-1:0] cy;
  reg [dimension_bits*2 - 1:0] ca;

  reg cycle_completed;


  memory #(
           .ADDR_WIDTH(dimension_bits*2),
           .WORD_SIZE(data_bits),
           .NUM_WORDS(width*height),
           .MEMORY_INIT_FILE("none"),
           .USE_XILINX_BLOCKRAM(USE_XILINX_BLOCKRAM)
         )
         memory_inst1 (
           .clk_write(clk_calc),
           .clk_read(read_clk),
           .write_en(write_en),
           .write_addr(write_addr),
           .write_data(write_data),

           .read_en(read_en),
           .read_addr(read_addr),
           .read_data(read_data)
         );

  /* verilator lint_off UNOPTFLAT */
  logic engine_reset[0:num_engines-1];
  logic signed [fp_bits - 1:0] engine_x0[0:num_engines-1];
  logic signed [fp_bits - 1:0] engine_y0[0:num_engines-1];
  logic engine_finished[0:num_engines-1];
  logic [31:0] engine_iterations[0:num_engines-1];

  logic [dimension_bits*2-1:0] engine_wr_adress[0:num_engines-1];
  // logic engine_busy[0:num_engines-1];
  logic [num_engines-1:0]engine_busy;


  wire [num_engines_bits: 0] engine_free_first[0:num_engines-1];
  wire [num_engines_bits: 0] engine_finished_first[0:num_engines-1];

  logic [`max2(num_engines_bits-1, 0): 0] engine_write_back;
  logic [`max2(num_engines_bits-1, 0): 0] engine_deploy;

  genvar i,j;
  generate
    for (i=0; i<num_engines; i=i+1)
    begin
      mandelbrot_engine#(
                         .fp_top(fp_top),
                         .fp_bot(fp_bot)
                       ) mandelbrot_engine (
                         .clk(clk_calc),
                         .reset(engine_reset[i]),
                         .iterations_max(iterations_max),
                         .x0(engine_x0[i]),
                         .y0(engine_y0[i]),

                         .finished(engine_finished[i]),
                         .iterations(engine_iterations[i])
                       );
    end

    if (num_engines == 1)
    begin
      assign engine_free_first[0] = engine_busy[0] == 0 ? 0 : 1;
      assign engine_finished_first[0] = engine_busy[0] == 1 && engine_finished[0] == 1 ? 0 : 1;

      assign engine_write_back = 0;
      assign engine_deploy = 0;
    end
    else
    begin
      for (i=0; i<num_engines-1; i=i+1)
      begin
        assign engine_free_first[i] = engine_busy[i] == 0 ? i : engine_free_first[i+1];
        assign engine_finished_first[i] = engine_busy[i] == 1 && engine_finished[i] == 1 ? i : engine_finished_first[i+1];
      end

      assign engine_free_first[num_engines-1] = engine_busy[num_engines-1] == 0 ? num_engines-1 : num_engines;
      assign engine_finished_first[num_engines-1] = engine_busy[num_engines-1] == 1 && engine_finished[num_engines-1] == 1 ? num_engines-1 : num_engines;

      assign engine_write_back = engine_finished_first[0][num_engines_bits-1: 0];
      assign engine_deploy = engine_free_first[0][num_engines_bits-1: 0];
    end
  endgenerate

  enum {reset_s, check, write, deploy, increment, finished_s} state;

  initial
  begin
    state = reset_s;
  end


  /* verilator lint_off BLKSEQ */
  always @ (posedge clk_calc)
  begin
    if (reset == 1)
    begin
      state <= reset_s;
    end
    else
    begin
      case (state)

        reset_s:
        begin
          cx <= 0;
          cy <= 0;
          ca <= 0;
          engine_busy <= '{default:1'b0};
          engine_reset <= '{default:1'b1};
          cycle_completed <= 0;
          finished <= 0;
          write_en <= 0;
          write_addr <= 0;
          write_data <= 0;
          write_en <= 0;

          state <= check;
        end

        check:
        begin
          engine_reset <= '{default:1'b0};
          write_en <= 0;

          if (engine_finished_first[0] != num_engines)
          begin
            write_addr <= engine_wr_adress[engine_write_back];
            if (engine_iterations[engine_write_back] >= iterations_max)
              write_data <= 1;
            else
              write_data <= {engine_iterations[engine_write_back][data_bits-1:1], 1'b1};
            write_en <= 1;
            engine_busy[engine_write_back] <= 0;
            state <= check;
          end
          else
          begin
            if (engine_free_first[0] != num_engines && !cycle_completed)
            begin
              engine_busy[engine_deploy]  <= 1;
              engine_reset[engine_deploy] <= 1;
              engine_wr_adress[engine_deploy] <= ca;

              // make sure the offset is at the image center
              if (cx >= dimension_bits'(width/2))
                engine_x0[engine_deploy] <= ({{fp_top-4{1'b0}}, cx - dimension_bits'(width/2), {fp_bot+4-dimension_bits{1'b0}}} >> zoom) + x0_offset;
              else
                engine_x0[engine_deploy] <= -({{fp_top-4{1'b0}}, dimension_bits'(width/2) - cx, {fp_bot+4-dimension_bits{1'b0}}} >> zoom) + x0_offset;

              if (cy >= dimension_bits'(height/2))
                engine_y0[engine_deploy] <= ({{fp_top-4{1'b0}}, cy - dimension_bits'(height/2), {fp_bot+4-dimension_bits{1'b0}}} >> zoom) + y0_offset;
              else
                engine_y0[engine_deploy] <= -({{fp_top-4{1'b0}}, dimension_bits'(height/2) - cy, {fp_bot+4-dimension_bits{1'b0}}} >> zoom) + y0_offset;

              state <= increment;
            end
          end

          if (cycle_completed && !(|engine_busy))
            state <= finished_s;

        end

        increment:
        begin
          engine_reset <= '{default:1'b0};

          cx <= (cx == dimension_bits'(width_max)) ? 0 : cx + 1;
          cy <= (cx == dimension_bits'(width_max)) ? ((cy == dimension_bits'(height_max)) ? 0 : cy + 1) : cy;
          ca <= ca + 1;

          if (cx == dimension_bits'(width_max) && cy == dimension_bits'(height_max))
            cycle_completed <= 1;

          state <= check;
        end

        finished_s:
        begin
          finished <= 1;
          // state <= reset_s;
        end

      endcase
    end
  end

endmodule
