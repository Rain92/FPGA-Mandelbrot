
module debounce
#(
    parameter COUNTER_SIZE = 19 //counter size (19 bits gives 10.5ms with 50MHz clock)
)
(
    input wire clk,    //input clock
    input wire button, //input signal to be debounced
    output reg result  //debounced signal
);




    reg [1:0] flipflops;                   //input flip flops
    wire counter_set;                      //sync reset to zero
    reg [COUNTER_SIZE-1:0] counter_out = 0;  //counter output
    
    assign counter_set = flipflops[0] ^ flipflops[1];         //determine when to start/reset counter
    
    
    always @(posedge clk) begin
        flipflops[0] <= button;
        flipflops[1] <= flipflops[0];
        
        if((counter_set == 1'b 1)) begin                          //reset counter because input is changing
            counter_out <= {COUNTER_SIZE{1'b0}};
        end
        else if(counter_out[COUNTER_SIZE-1] == 1'b0) begin          //stable input time is not yet met
            counter_out <= counter_out + 1;
        end
        else begin                                                //stable input time is met
            result <= flipflops[1]; 
        end
    end


endmodule
