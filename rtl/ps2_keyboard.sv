
module ps2_keyboard
  #(
     parameter integer clk_freq = 50000000,              //system clock frequency in Hz
     parameter integer debounce_counter_size = 8         //set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
   )
   (
     input wire clk,                             //system clock
     input wire ps2_clk,                         //clock signal from PS/2 keyboard
     input wire ps2_data,                        //data signal from PS/2 keyboard
     output reg ps2_code_new,                    //flag that new PS/2 code is available on ps2_code bus
     output reg [7:0] ps2_code                 //code received from PS/2
   );
  localparam count_idle_max = clk_freq/18_000;

  reg [1:0] sync_ffs;               //synchronizer flip-flops for PS/2 signals
  reg ps2_clk_int;                  //debounced clock signal from PS/2 keyboard
  reg ps2_data_int;                 //debounced data signal from PS/2 keyboard
  reg [10:0] ps2_word;              //stores the ps2 data word
  wire error;                        //validate parity, start, and stop bits
  reg [$clog2(count_idle_max)-1:0]  count_idle; //counter to determine PS/2 is idle


  //synchronizer flip-flops
  always @(posedge clk)
  begin         //rising edge of system clock
    sync_ffs[0] <= ps2_clk;           //synchronize PS/2 clock signal
    sync_ffs[1] <= ps2_data;          //synchronize PS/2 data signal
  end

  //debounce PS2 input signals
  debounce
    #(
      .COUNTER_SIZE(debounce_counter_size)   //debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
    ) debounce1
    (
      .clk(clk),
      .button(sync_ffs[0]),
      .result(ps2_clk_int)
    );

  debounce
    #(
      .COUNTER_SIZE(debounce_counter_size)   //debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
    ) debounce2
    (
      .clk(clk),
      .button(sync_ffs[1]),
      .result(ps2_data_int)
    );


  //input PS2 data
  always @ (negedge ps2_clk_int)
  begin //falling edge of PS2 clock
    ps2_word <= {ps2_data_int, ps2_word[10 : 1]};   //shift in PS2 data bit
  end



  //verify that parity, start, and stop bits are all correct
  assign error = ! ((!ps2_word[0]) && ps2_word[10] && (ps2_word[9] ^ ps2_word[8] ^
                    ps2_word[7] ^ ps2_word[6] ^ ps2_word[5] ^ ps2_word[4] ^ ps2_word[3] ^
                    ps2_word[2] ^ ps2_word[1]));

  //determine if PS2 port is idle (i.e. last transaction is finished) and output result
  always @ (posedge clk)
  begin         //rising edge of system clock

    if (ps2_clk_int == 0)                         //low PS2 clock, PS/2 is active
      count_idle <= 0;                           //reset idle counter
    /* verilator lint_off WIDTH */
    else if(count_idle != count_idle_max
            - 1)  //PS2 clock has been high less than a half clock period (<55us)
      count_idle <= count_idle + 1;            //continue counting

    if (count_idle == count_idle_max - 1 && error == 0)
    begin  //idle threshold reached and no errors detected
      ps2_code_new <= 1;                                   //set flag that new PS/2 code is available
      ps2_code <= ps2_word[8 : 1];                      //output new PS/2 code
    end
    else
    begin                                                  //PS/2 port active or error detected
      ps2_code_new <= 0;                                   //set flag that PS/2 transaction is in progress
    end

  end

endmodule
