module elevator_scheduler(input [1:0] current_floor,input [3:0] pending_requests,input moving_up,input moving_down,output reg request_valid,output reg [1:0] target_floor);
integer i; reg found;
always @(*) begin
 request_valid=0; target_floor=current_floor; found=0;
 if(moving_up) begin
  for(i=0;i<4;i=i+1) if(!found && (i>=current_floor) && pending_requests[i]) begin target_floor=i[1:0]; request_valid=1; found=1; end
  if(!found) for(i=3;i>=0;i=i-1) if(!found && pending_requests[i]) begin target_floor=i[1:0]; request_valid=1; found=1; end
 end else if(moving_down) begin
  for(i=3;i>=0;i=i-1) if(!found && (i<=current_floor) && pending_requests[i]) begin target_floor=i[1:0]; request_valid=1; found=1; end
  if(!found) for(i=0;i<4;i=i+1) if(!found && pending_requests[i]) begin target_floor=i[1:0]; request_valid=1; found=1; end
 end else begin
  for(i=0;i<4;i=i+1) if(!found && pending_requests[i]) begin target_floor=i[1:0]; request_valid=1; found=1; end
 end
end
endmodule
