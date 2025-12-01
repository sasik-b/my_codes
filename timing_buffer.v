// timing buffer or a pipe 
////////////|---------------|////////////////////////
//v_up----->|               |v_down----->
//          |               |
//d_up----->|               |d_down----->
//          |               |
//          |               |
//e_up<-----|               |e_down<-----
//          |               |
//          |---------------|

// holds one packet, breaks valid and data path(timing). 
// doesn't break enable path(timing)

module timing_buffer (
input clk, rst_n;
input logic v_up;             //valid from up stream
input logic [31:0] d_up;      //data from up stream

output logic v_down;          //valid to down stream
output logic [31:0] d_down;   //data to downstream

input logic e_down;           //enable from down stream
output logic e_up;            //enable to downstream
);

logic e_l;
logic v_l;
logic [31:0] d_l;



//Truth table for enable to upstream
//------------------------------------
//   e_down | v_up | v_down ||| e_up |
//-----------------------------------|
//     0    |  0   |   0    ||| 1    |  //backpressure from down stream. flop is empty as v_down =0. so the enable_up get's HI to allow packet.
//     0    |  0   |   1    ||| 0    |  //backpressure from down stream.flop is already filled. v_up =0 as well, so e_up = 0
//     0    |  1   |   0    ||| 1    |  //backpressure from down stream. flop is empty,but v_up =1. so the flop to allow the input so e_up =1;
//     0    |  1   |   1    ||| 0    |  //backpressure from down stream. flop is full, even the v_up =1, the flop can't allow it. so e_up =0;
//     1    |  0   |   0    ||| 1    |  //NO backpressure.so flop to allow the up stream control signals.
//     1    |  0   |   1    ||| 1    |  //NO backpressure.so flop to allow the up stream control signals.
//     1    |  1   |   0    ||| 1    |  //NO backpressure.so flop to allow the up stream control signals.
//     1    |  1   |   1    ||| 1    |  //NO backpressure.so flop to allow the up stream control signals.
//------------------------------------
assign e_l = e_down | (~v_l);
//Truth table for valid to down stream
//---------------------------------------------------
//   e_down(t) | v_up(t) | v_down(t) ||| v_down(t+1)|
//--------------------------------------------------|
//     0       |  0      |   0       ||| v_up(t)    |  //backpressure from down stream. flop is empty as v_down =0. flop allows upstream
//     0       |  0      |   1       ||| v_down(t)  |  //backpressure from down stream.flop is already filled. so flop to retain it's previous value.
//     0       |  1      |   0       ||| v_up(t)    |  //backpressure from down stream. flop is empty,but v_up =1. so the flop to allow the input 
//     0       |  1      |   1       ||| v_down(t)  |  //backpressure from down stream. flop is full, even the v_up =1, so the flop to retain it's previous value.
//     1       |  0      |   0       ||| v_up(t)    |  //NO backpressure.so flop to allow the up stream control signals.
//     1       |  0      |   1       ||| v_up(t)    |  //NO backpressure.so flop to allow the up stream control signals.
//     1       |  1      |   0       ||| v_up(t)    |  //NO backpressure.so flop to allow the up stream control signals.
//     1       |  1      |   1       ||| v_up(t)    |  //NO backpressure.so flop to allow the up stream control signals.
//---------------------------------------------------
always_ff @(posedge clk) begin
   if(!rst_n) begin
      v_l <= 1'b0;                                     //initially before any trnasactions start, to make enable downstream HI = e_down | (~v_l);
	end else begin
	  if(e_l) begin // or if(e_down | ~v_down)
	     v_l <= v_up;
      end
    end
end

// similar to valid transfer, data also follows.but  
//when valid from up stream is LO, then no point in loading the invalid data into the register. so, when both valid from 'upstream is set' and 'enable to up stream' is set,  then data is registered otherwise to retain.
always_ff @(posedge clk) begin
    if(v_up & e_l) begin
       d_l <= d_up;
    end
end

assign v_down = v_l;
assign d_down = d_l;
assign e_up = e_l;

endmodule
