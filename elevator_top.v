module elevator_top(
 input clk,
 input reset,
 input [3:0] keypad_col,
 output [3:0] keypad_row,
 output [7:0] display1,
 output [7:0] leds
);
wire floor_tick, door_tick;
wire new_request;
wire [1:0] request_floor;
wire [3:0] pending_requests;
wire request_valid;
wire [1:0] target_floor;
wire [1:0] current_floor;
wire move_up, move_down, destination_reached;
wire moving_up, moving_down, door_open;
wire door_timer_done;
wire [7:0] seg;
wire clear_request;
wire [1:0] clear_floor;

clock_divider #(.FLOOR_TICK_DIV(10000000), .DOOR_TICK_DIV(20000)) u_clock(
 .clk(clk), .reset(reset), .floor_tick(floor_tick), .door_tick(door_tick));

keypad_scanner u_keypad(
 .clk(clk), .reset(reset), .scan_tick(door_tick), .col(keypad_col),
 .row(keypad_row), .new_request(new_request), .request_floor(request_floor));

request_register u_req(
 .clk(clk), .reset(reset), .new_request(new_request), .request_floor(request_floor),
 .clear_request(clear_request), .clear_floor(clear_floor), .pending_requests(pending_requests));

elevator_scheduler u_sched(
 .current_floor(current_floor), .pending_requests(pending_requests),
 .moving_up(moving_up), .moving_down(moving_down),
 .request_valid(request_valid), .target_floor(target_floor));

movement_logic u_move(
 .current_floor(current_floor), .target_floor(target_floor), .request_valid(request_valid),
 .move_up(move_up), .move_down(move_down), .destination_reached(destination_reached));

floor_counter u_floor(
 .clk(clk), .reset(reset), .floor_tick(floor_tick),
 .moving_up(moving_up), .moving_down(moving_down), .current_floor(current_floor));

door_timer #(.DOOR_TIME_TICKS(2000)) u_door_timer(
 .clk(clk), .reset(reset), .door_open(door_open), .door_tick(door_tick),
 .door_timer_done(door_timer_done));

elevator_fsm u_fsm(
 .clk(clk), .reset(reset), .request_valid(request_valid),
 .move_up(move_up), .move_down(move_down),
 .destination_reached(destination_reached), .door_timer_done(door_timer_done),
 .moving_up(moving_up), .moving_down(moving_down), .door_open(door_open));

assign clear_request = door_timer_done;
assign clear_floor = target_floor;

sevenseg_floor u_display(.floor(current_floor), .seg(seg));
assign display1 = seg;
assign leds[0] = moving_up;
assign leds[1] = moving_down;
assign leds[2] = door_open;
assign leds[3] = request_valid;
assign leds[5:4] = current_floor;
assign leds[7:6] = pending_requests[1:0];
endmodule
