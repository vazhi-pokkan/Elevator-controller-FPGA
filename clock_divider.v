module clock_divider #(parameter integer FLOOR_TICK_DIV=10000000, parameter integer DOOR_TICK_DIV=20000)(input clk,input reset,output reg floor_tick,output reg door_tick);
reg [31:0] floor_count; reg [31:0] door_count;
always @(posedge clk or posedge reset) begin
 if(reset) begin floor_count<=0; door_count<=0; floor_tick<=0; door_tick<=0; end
 else begin
  floor_tick<=0; door_tick<=0;
  if(floor_count >= FLOOR_TICK_DIV-1) begin floor_count<=0; floor_tick<=1; end else floor_count<=floor_count+1'b1;
  if(door_count >= DOOR_TICK_DIV-1) begin door_count<=0; door_tick<=1; end else door_count<=door_count+1'b1;
 end
end
endmodule
