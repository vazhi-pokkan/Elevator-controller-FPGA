module request_register(input clk,input reset,input new_request,input [1:0] request_floor,input clear_request,input [1:0] clear_floor,output reg [3:0] pending_requests);
always @(posedge clk or posedge reset) begin
 if(reset) pending_requests<=4'b0000;
 else begin
  if(new_request) pending_requests[request_floor]<=1'b1;
  if(clear_request) pending_requests[clear_floor]<=1'b0;
 end
end
endmodule
