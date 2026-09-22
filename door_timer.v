module door_timer #(parameter integer DOOR_TIME_TICKS=2000)(input clk,input reset,input door_open,input door_tick,output reg door_timer_done);
reg [31:0] count;
always @(posedge clk or posedge reset) begin
 if(reset) begin count<=0; door_timer_done<=0; end
 else if(!door_open) begin count<=0; door_timer_done<=0; end
 else if(door_tick) begin
  if(count>=DOOR_TIME_TICKS-1) begin count<=0; door_timer_done<=1; end
  else begin count<=count+1'b1; door_timer_done<=0; end
 end
end
endmodule
