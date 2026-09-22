module elevator_fsm(input clk,input reset,input request_valid,input move_up,input move_down,input destination_reached,input door_timer_done,output reg moving_up,output reg moving_down,output reg door_open);
localparam IDLE=3'd0,MOVING_UP=3'd1,MOVING_DOWN=3'd2,DOOR_OPEN=3'd3,DOOR_CLOSE=3'd4;
reg [2:0] state,next_state;
always @(posedge clk or posedge reset) begin if(reset) state<=IDLE; else state<=next_state; end
always @(*) begin
 next_state=state;
 case(state)
  IDLE: if(request_valid) begin if(move_up) next_state=MOVING_UP; else if(move_down) next_state=MOVING_DOWN; else if(destination_reached) next_state=DOOR_OPEN; end
  MOVING_UP: if(destination_reached) next_state=DOOR_OPEN;
  MOVING_DOWN: if(destination_reached) next_state=DOOR_OPEN;
  DOOR_OPEN: if(door_timer_done) next_state=DOOR_CLOSE;
  DOOR_CLOSE: next_state=IDLE;
  default: next_state=IDLE;
 endcase
end
always @(*) begin moving_up=0; moving_down=0; door_open=0; case(state) MOVING_UP:moving_up=1; MOVING_DOWN:moving_down=1; DOOR_OPEN:door_open=1; endcase end
endmodule
