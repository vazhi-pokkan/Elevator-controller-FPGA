module movement_logic(input [1:0] current_floor,input [1:0] target_floor,input request_valid,output reg move_up,output reg move_down,output reg destination_reached);
always @(*) begin
 move_up=0; move_down=0; destination_reached=0;
 if(request_valid) begin
  if(current_floor<target_floor) move_up=1;
  else if(current_floor>target_floor) move_down=1;
  else destination_reached=1;
 end
end
endmodule
