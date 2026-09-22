module sevenseg_floor(input [1:0] floor,output reg [7:0] seg);
always @(*) begin
 case(floor)
 2'd0: seg=8'b01100000;
 2'd1: seg=8'b11011010;
 2'd2: seg=8'b11110010;
 2'd3: seg=8'b01100110;
 default: seg=8'b00000000;
 endcase
end
endmodule
