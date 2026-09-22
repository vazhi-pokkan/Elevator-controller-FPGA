module floor_counter(input clk,input reset,input floor_tick,input moving_up,input moving_down,output reg [1:0] current_floor);
always @(posedge clk or posedge reset) begin
 if(reset) current_floor<=2'd0;
 else if(floor_tick) begin
  if(moving_up && current_floor<2'd3) current_floor<=current_floor+1'b1;
  else if(moving_down && current_floor>2'd0) current_floor<=current_floor-1'b1;
 end
end
endmodule
