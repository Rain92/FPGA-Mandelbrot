

module ps2_keyboard_to_ascii
  #(
     parameter integer clk_freq = 50000000,              // system clock frequency in Hz
     parameter integer ps2_debounce_counter_size = 8         // set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
   )
   (
     input wire clk,                             // system clock
     input wire ps2_clk,                         // clock signal from PS/2 keyboard
     input wire ps2_data,                        // data signal from PS/2 keyboard
     output reg ascii_new,                       // flag that new PS/2 code is available on ps2_code bus
     output reg key_pressed,                     // flag shows if the key was pressed or released
     output reg [7:0] ascii_code                 // code received from PS/2
   );

  enum {ready, new_code, translate, output_s} state;

  wire ps2_code_new;                             // new PS2 code flag from ps2_keyboard component
  wire [7:0] ps2_code;                           // PS2 code input form ps2_keyboard component
  reg prev_ps2_code_new = 1;                      // value of ps2_code_new flag on previous clock
  reg do_break          = 0;                      // '1' for break code, '0' for make code
  reg e0_code           = 0;                      // '1' for multi-code commands, '0' for single code commands
  reg caps_lock         = 0;                      // '1' if caps lock is active, '0' if caps lock is inactive
  reg control_r         = 0;                      // '1' if right control key is held down, else '0'
  reg control_l         = 0;                      // '1' if left control key is held down, else '0'
  reg shift_r           = 0;                      // '1' if right shift is held down, else '0'
  reg shift_l           = 0;                      // '1' if left shift is held down, else '0'
  reg [7:0] ascii       = 8'hff;                  // internal value of ASCII translation


  ps2_keyboard
    #(
      .clk_freq(clk_freq),
      .debounce_counter_size(ps2_debounce_counter_size)

    ) ps2_keyboard_0
    (
      .clk(clk),
      .ps2_clk(ps2_clk),
      .ps2_data(ps2_data),
      .ps2_code_new(ps2_code_new),
      .ps2_code(ps2_code)
    );

  always @ (posedge clk)
  begin

    prev_ps2_code_new <= ps2_code_new; // keep track of previous ps2_code_new values to determine low-to-high transitions

    /* verilator lint_off CASEINCOMPLETE */
    case (state)

      ready:   // ready state: wait for a new PS2 code to be received
      begin
        if (prev_ps2_code_new == 0 && ps2_code_new == 1)
        begin // new PS2 code received
          ascii_new <= 0;                                       // reset new ASCII code indicator
          state <= new_code;                                      // proceed to new_code state
        end
        else
        begin                                                    // no new PS2 code received yet
          ascii_new <= 0;                                       // reset new ASCII code indicator
          state <= ready;                                         // remain in ready state
        end
      end

      new_code:   // new_code state: determine what to do with the new PS2 code
      begin
        if (ps2_code == 8'hF0)
        begin    // code indicates that next command is break
          do_break <= 1;                // set break flag
          state <= ready;              // return to ready state to await next PS2 code
        end
        else if (ps2_code == 8'hE0)
        begin // code indicates multi-key command
          e0_code <= 1;              // set multi-code command flag
          state <= ready;              // return to ready state to await next PS2 code
        end
        else
        begin                         // code is the last PS2 code in the make/break code
          ascii[7] <= 1;             // set internal ascii value to unsupported code (for verification)
          state <= translate;          // proceed to translate state
        end
      end

      translate:   // translate state: translate PS2 code to ASCII value
      begin
        case (ps2_code)  // handle codes for control, shift, and caps lock
          8'h58 :                   // caps lock code
            if (do_break == 0)            // if make command
              caps_lock <= !caps_lock;     // toggle caps lock

          8'h14 :                   // code for the control keys
            if (e0_code == 1)           // code for right control
              control_r <= !do_break;         // update right control flag
            else                            // code for left control
              control_l <= !do_break;         // update left control flag

          8'h12 :                   // left shift code
            shift_l <= !do_break;           // update left shift flag

          8'h59 :                   // right shift code
            shift_r <= !do_break;           // update right shift flag

        endcase

        // translate control codes (these do not depend on shift or caps lock)
        if (control_l == 1 || control_r == 1)
        begin
          case (ps2_code)
            8'h1E :
              ascii <= 8'h00; // ^@  NUL
            8'h1C :
              ascii <= 8'h01; // ^A  SOH
            8'h32 :
              ascii <= 8'h02; // ^B  STX
            8'h21 :
              ascii <= 8'h03; // ^C  ETX
            8'h23 :
              ascii <= 8'h04; // ^D  EOT
            8'h24 :
              ascii <= 8'h05; // ^E  ENQ
            8'h2B :
              ascii <= 8'h06; // ^F  ACK
            8'h34 :
              ascii <= 8'h07; // ^G  BEL
            8'h33 :
              ascii <= 8'h08; // ^H  BS
            8'h43 :
              ascii <= 8'h09; // ^I  HT
            8'h3B :
              ascii <= 8'h0A; // ^J  LF
            8'h42 :
              ascii <= 8'h0B; // ^K  VT
            8'h4B :
              ascii <= 8'h0C; // ^L  FF
            8'h3A :
              ascii <= 8'h0D; // ^M  CR
            8'h31 :
              ascii <= 8'h0E; // ^N  SO
            8'h44 :
              ascii <= 8'h0F; // ^O  SI
            8'h4D :
              ascii <= 8'h10; // ^P  DLE
            8'h15 :
              ascii <= 8'h11; // ^Q  DC1
            8'h2D :
              ascii <= 8'h12; // ^R  DC2
            8'h1B :
              ascii <= 8'h13; // ^S  DC3
            8'h2C :
              ascii <= 8'h14; // ^T  DC4
            8'h3C :
              ascii <= 8'h15; // ^U  NAK
            8'h2A :
              ascii <= 8'h16; // ^V  SYN
            8'h1D :
              ascii <= 8'h17; // ^W  ETB
            8'h22 :
              ascii <= 8'h18; // ^X  CAN
            8'h35 :
              ascii <= 8'h19; // ^Y  EM
            8'h1A :
              ascii <= 8'h1A; // ^Z  SUB
            8'h54 :
              ascii <= 8'h1B; // ^[  ESC
            8'h5D :
              ascii <= 8'h1C; // ^\  FS
            8'h5B :
              ascii <= 8'h1D; // ^]  GS
            8'h36 :
              ascii <= 8'h1E; // ^^  RS
            8'h4E :
              ascii <= 8'h1F; // ^_  US
            8'h4A :
              ascii <= 8'h7F; // ^?  DEL
          endcase
        end
        else
        begin // if control keys are not pressed

          // translate characters that do not depend on shift, or caps lock
          case (ps2_code)
            8'h29 :
              ascii <= 8'h20; // space
            8'h66 :
              ascii <= 8'h08; // backspace (BS control code)
            8'h0D :
              ascii <= 8'h09; // tab (HT control code)
            8'h5A :
              ascii <= 8'h0D; // enter (CR control code)
            8'h76 :
              ascii <= 8'h1B; // escape (ESC control code)
            8'h71 :
              if (e0_code == 1)       // ps2 code for delete is a multi-key code
                ascii <= 8'h7F;             // delete
          endcase

          // translate letters (these depend on both shift and caps lock)
          if ((shift_r == 0 && shift_l == 0 && caps_lock == 0) ||
              ((shift_r == 1 || shift_l == 1) && caps_lock == 1))
          begin  // letter is lowercase
            case (ps2_code)
              8'h1C :
                ascii <= 8'h61; // a
              8'h32 :
                ascii <= 8'h62; // b
              8'h21 :
                ascii <= 8'h63; // c
              8'h23 :
                ascii <= 8'h64; // d
              8'h24 :
                ascii <= 8'h65; // e
              8'h2B :
                ascii <= 8'h66; // f
              8'h34 :
                ascii <= 8'h67; // g
              8'h33 :
                ascii <= 8'h68; // h
              8'h43 :
                ascii <= 8'h69; // i
              8'h3B :
                ascii <= 8'h6A; // j
              8'h42 :
                ascii <= 8'h6B; // k
              8'h4B :
                ascii <= 8'h6C; // l
              8'h3A :
                ascii <= 8'h6D; // m
              8'h31 :
                ascii <= 8'h6E; // n
              8'h44 :
                ascii <= 8'h6F; // o
              8'h4D :
                ascii <= 8'h70; // p
              8'h15 :
                ascii <= 8'h71; // q
              8'h2D :
                ascii <= 8'h72; // r
              8'h1B :
                ascii <= 8'h73; // s
              8'h2C :
                ascii <= 8'h74; // t
              8'h3C :
                ascii <= 8'h75; // u
              8'h2A :
                ascii <= 8'h76; // v
              8'h1D :
                ascii <= 8'h77; // w
              8'h22 :
                ascii <= 8'h78; // x
              8'h35 :
                ascii <= 8'h79; // y
              8'h1A :
                ascii <= 8'h7A; // z
            endcase
          end
          else
          begin                                     // letter is uppercase
            case (ps2_code)
              8'h1C :
                ascii <= 8'h41; // A
              8'h32 :
                ascii <= 8'h42; // B
              8'h21 :
                ascii <= 8'h43; // C
              8'h23 :
                ascii <= 8'h44; // D
              8'h24 :
                ascii <= 8'h45; // E
              8'h2B :
                ascii <= 8'h46; // F
              8'h34 :
                ascii <= 8'h47; // G
              8'h33 :
                ascii <= 8'h48; // H
              8'h43 :
                ascii <= 8'h49; // I
              8'h3B :
                ascii <= 8'h4A; // J
              8'h42 :
                ascii <= 8'h4B; // K
              8'h4B :
                ascii <= 8'h4C; // L
              8'h3A :
                ascii <= 8'h4D; // M
              8'h31 :
                ascii <= 8'h4E; // N
              8'h44 :
                ascii <= 8'h4F; // O
              8'h4D :
                ascii <= 8'h50; // P
              8'h15 :
                ascii <= 8'h51; // Q
              8'h2D :
                ascii <= 8'h52; // R
              8'h1B :
                ascii <= 8'h53; // S
              8'h2C :
                ascii <= 8'h54; // T
              8'h3C :
                ascii <= 8'h55; // U
              8'h2A :
                ascii <= 8'h56; // V
              8'h1D :
                ascii <= 8'h57; // W
              8'h22 :
                ascii <= 8'h58; // X
              8'h35 :
                ascii <= 8'h59; // Y
              8'h1A :
                ascii <= 8'h5A; // Z
            endcase
          end

          // translate numbers and symbols (these depend on shift but not caps lock)
          if (shift_l == 1 || shift_r == 1)
          begin  // key's secondary character is desired
            case (ps2_code)
              8'h16 :
                ascii <= 8'h21; // !
              8'h52 :
                ascii <= 8'h22; // "
              8'h26 :
                ascii <= 8'h23; // #
              8'h25 :
                ascii <= 8'h24; // $
              8'h2E :
                ascii <= 8'h25; // %
              8'h3D :
                ascii <= 8'h26; // &
              8'h46 :
                ascii <= 8'h28; // (
              8'h45 :
                ascii <= 8'h29; // )
              8'h3E :
                ascii <= 8'h2A; // *
              8'h55 :
                ascii <= 8'h2B; // +
              8'h4C :
                ascii <= 8'h3A; // :
              8'h41 :
                ascii <= 8'h3C; // <
              8'h49 :
                ascii <= 8'h3E; // >
              8'h4A :
                ascii <= 8'h3F; // ?
              8'h1E :
                ascii <= 8'h40; // @
              8'h36 :
                ascii <= 8'h5E; // ^
              8'h4E :
                ascii <= 8'h5F; // _
              8'h54 :
                ascii <= 8'h7B; // {
              8'h5D :
                ascii <= 8'h7C; // |
              8'h5B :
                ascii <= 8'h7D; // }
              8'h0E :
                ascii <= 8'h7E; // ~
            endcase
          end
          else
          begin                                     // key's primary character is desired
            case (ps2_code)
              8'h45 :
                ascii <= 8'h30; // 0
              8'h16 :
                ascii <= 8'h31; // 1
              8'h1E :
                ascii <= 8'h32; // 2
              8'h26 :
                ascii <= 8'h33; // 3
              8'h25 :
                ascii <= 8'h34; // 4
              8'h2E :
                ascii <= 8'h35; // 5
              8'h36 :
                ascii <= 8'h36; // 6
              8'h3D :
                ascii <= 8'h37; // 7
              8'h3E :
                ascii <= 8'h38; // 8
              8'h46 :
                ascii <= 8'h39; // 9
              8'h52 :
                ascii <= 8'h27; // '
              8'h41 :
                ascii <= 8'h2C; // ,
              8'h4E :
                ascii <= 8'h2D; // -
              8'h49 :
                ascii <= 8'h2E; // .
              8'h4A :
                ascii <= 8'h2F; // /
              8'h4C :
                ascii <= 8'h3B; // ;
              8'h55 :
                ascii <= 8'h3D; // =
              8'h54 :
                ascii <= 8'h5B; // [
              8'h5D :
                ascii <= 8'h5C; // \
              8'h5B :
                ascii <= 8'h5D; // ]
              8'h0E :
                ascii <= 8'h60; // `
            endcase
          end

        end

        //  if (do_break == 0)  // the code is a make
        state <= output_s;      // proceed to output state
        //  else                  // code is a break
        //    state <= ready;       // return to ready state to await next PS2 code

      end // state translate


      output_s:   // output state: verify the code is valid and output the ASCII value
      begin
        if (ascii[7] == 0)
        begin            // the PS2 code has an ASCII output
          ascii_new <= 1;                  // set flag indicating new ASCII output
          ascii_code <= ascii[7:0];   // output the ASCII value
        end
        state <= ready;                    // return to ready state to await next PS2 code

        key_pressed <= !do_break;

        do_break <= 0;    // reset break flag
        e0_code <= 0;  // reset multi-code command flag
      end

    endcase
  end

endmodule
