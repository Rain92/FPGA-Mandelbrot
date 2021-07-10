`timescale 1ns / 1ns

module memory #
  (
    parameter ADDR_WIDTH = 8,
    parameter WORD_SIZE = 8,
    parameter NUM_WORDS = 256,
    parameter MEMORY_INIT_FILE = "none",
    parameter USE_XILINX_BLOCKRAM = 1
  )
  (
    input wire clk_write,
    input wire clk_read,

    input wire write_en,
    input wire [ADDR_WIDTH - 1 : 0] write_addr,
    input wire [WORD_SIZE  - 1 : 0] write_data,

    input wire read_en,
    input wire [ADDR_WIDTH - 1 : 0] read_addr,
    output wire [WORD_SIZE - 1 : 0] read_data
  );
  generate
    if (!USE_XILINX_BLOCKRAM)
    begin

      /* verilator lint_off WIDTH */
      reg [WORD_SIZE - 1 : 0] read_data_;
      assign read_data = read_data_;

      (* ram_style = "distributed" *) reg [WORD_SIZE - 1 : 0] memory [NUM_WORDS - 1:0];

      integer i;
      initial
      begin
        if (MEMORY_INIT_FILE != "none")
          $readmemh(MEMORY_INIT_FILE, memory);
        else
        begin
          for (i=0; i<NUM_WORDS; i=i+1)
          begin
            memory[i] = 0;
          end
        end

        read_data_ = 0;
      end

      always @ (posedge clk_write)
      begin
        if (write_en)
          memory[write_addr] <= write_data;
      end

      always @ (posedge clk_read)
      begin
        if (read_en)
          read_data_ <= memory[read_addr];
      end

    end
    else
    begin
      /* verilator lint_off PINCONNECTEMPTY */
      xpm_memory_sdpram #(
                          .ADDR_WIDTH_A(ADDR_WIDTH),             // DECIMAL
                          .ADDR_WIDTH_B(ADDR_WIDTH),             // DECIMAL
                          .BYTE_WRITE_WIDTH_A(WORD_SIZE),        // DECIMAL
                          .CLOCKING_MODE("independent_clock"),
                          .MEMORY_INIT_FILE(MEMORY_INIT_FILE),   // String
                          .MEMORY_INIT_PARAM((MEMORY_INIT_FILE == "none") ? "0" : ""),        // String
                          .MEMORY_SIZE(NUM_WORDS*WORD_SIZE),     // DECIMAL
                          .READ_DATA_WIDTH_B(WORD_SIZE),         // DECIMAL
                          .READ_LATENCY_B(1),                    // DECIMAL
                          .READ_RESET_VALUE_B("0"),              // String
                          .WRITE_DATA_WIDTH_A(WORD_SIZE)         // DECIMAL
                        )
                        xpm_memory_sdpram_inst (
                          .clka(clk_write),                      // 1-bit input: Clock signal for port A. Also clocks port B when
                          .clkb(clk_read),                       // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                          .ena(write_en),                        // 1-bit input: Memory enable signal for port A.
                          .addra(write_addr),                    // ADDR_WIDTH_A-bit input: Address for port A write operations.
                          .wea(write_en),                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                          .dina(write_data),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.

                          .enb(read_en),                         // 1-bit input: Memory enable signal for port B.
                          .addrb(read_addr),                     // ADDR_WIDTH_B-bit input: Address for port B read operations.
                          .doutb(read_data),                     // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.

                          .dbiterrb(),                           // 1-bit output: Status signal to indicate double bit error occurrence
                          .sbiterrb(),                           // 1-bit output: Status signal to indicate single bit error occurrence

                          .injectdbiterra(1'b0),                 // 1-bit input: Controls double bit error injection on input data when
                          .injectsbiterra(1'b0),                 // 1-bit input: Controls single bit error injection on input data when
                          .regceb(1'b1),                         // 1-bit input: Clock Enable for the last register stage on the output data path.
                          .rstb(1'b0),                           // 1-bit input: Reset signal for the final port B output register stage.
                          .sleep(1'b0)                           // 1-bit input: sleep signal to enable the dynamic power saving feature.
                        );

    end
  endgenerate
endmodule
