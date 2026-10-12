
module elevator_top(
    input        clk,
    input        reset,

    input        sw_emergency,
    input        sw_fire,
    input        sw_maintenance,

    input  [3:0] keypad_col,
    output [3:0] keypad_row,

    // Seven-segment outputs, ordered {a,b,c,d,e,f,g,dp}
    output reg [7:0] seg1,
	 output reg [7:0] seg2,
    output reg [7:0] seg3,
    output reg [7:0] seg4,

    output [7:0] leds,
	 output buzzer,
	 output relay
);
	
	 wire enter_key_pulse;
	 wire exit_key_pulse;
	 
    wire floor_tick;
    wire door_tick;

    wire sw_emergency_db;
    wire sw_fire_db;
    wire sw_maintenance_db;

    wire emergency_active;
    wire fire_active;
    wire maintenance_active;
    wire sleep_active;

    wire recall_request;
    wire clear_all_requests;
    wire inactivity_timeout;
    wire system_idle;

    wire new_request;
    wire [1:0] request_floor;
    wire [3:0] pending_requests;

    wire request_valid;
    wire [1:0] target_floor;
    wire [1:0] current_floor;

    wire move_up;
    wire move_down;
    wire destination_reached;

    wire moving_up;
    wire moving_down;
    wire door_open;
    wire door_timer_done;

    wire clear_request;
    wire [1:0] clear_floor;

    wire [3:0] person_count;
    wire person_empty;
    wire person_full;

    // Clock divider: 20 MHz input clock
    clock_divider #(
        .FLOOR_TICK_DIV(35000000),
        .DOOR_TICK_DIV(25000)
    ) u_clock (
        .clk(clk),
        .reset(reset),
        .floor_tick(floor_tick),
        .door_tick(door_tick)
    );

    // Keypad
    keypad_scanner u_keypad (
    .clk(clk),
    .reset(reset),
    .scan_tick(door_tick),
    .col(keypad_col),
    .row(keypad_row),
    .new_request(new_request),
    .request_floor(request_floor),
    .enter_pulse(enter_key_pulse),
    .exit_pulse(exit_key_pulse)
	 );

    // Request register
    request_register u_req (
        .clk(clk),
        .reset(reset),
        .new_request(new_request),
        .request_floor(request_floor),
        .clear_request(clear_request),
        .clear_floor(clear_floor),
        .clear_all_requests(clear_all_requests),
        .pending_requests(pending_requests)
    );

    // Elevator scheduler
    elevator_scheduler u_sched (
        .current_floor(current_floor),
        .pending_requests(pending_requests),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .request_valid(request_valid),
        .target_floor(target_floor)
    );

    // Movement logic
    movement_logic u_move (
        .current_floor(current_floor),
        .target_floor(target_floor),
        .request_valid(request_valid),
        .move_up(move_up),
        .move_down(move_down),
        .destination_reached(destination_reached)
    );

    // Floor counter
    floor_counter u_floor (
        .clk(clk),
        .reset(reset),
        .floor_tick(floor_tick),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .current_floor(current_floor)
    );

    // Door timer
    door_timer #(
        .DOOR_TIME_TICKS(2000)
    ) u_door_timer (
        .clk(clk),
        .reset(reset),
        .door_open(door_open),
        .door_tick(door_tick),
        .door_timer_done(door_timer_done)
    );

    // Main elevator FSM
    elevator_fsm u_fsm (
		 .clk(clk),
		 .reset(reset),
		 .request_valid(request_valid),
		 .move_up(move_up),
		 .move_down(move_down),
		 .destination_reached(destination_reached),
		 .door_timer_done(door_timer_done),
		 .current_floor(current_floor),
		 .floor_tick(floor_tick),
		 .recall_request(recall_request),
		 .fire_active(fire_active),
		 .maintenance_active(maintenance_active),
		 .system_idle(system_idle),
		 .moving_up(moving_up),
		 .moving_down(moving_down),
		 .door_open(door_open)
	 );

    // Special-mode switch conditioning
    switch_conditioner #(
        .DEBOUNCE_TICKS(20)
    ) u_emergency_conditioner (
        .clk(clk),
        .reset(reset),
        .tick_1khz(door_tick),
        .switch_in(sw_emergency),
        .switch_out(sw_emergency_db)
    );

    switch_conditioner #(
        .DEBOUNCE_TICKS(20)
    ) u_fire_conditioner (
        .clk(clk),
        .reset(reset),
        .tick_1khz(door_tick),
        .switch_in(sw_fire),
        .switch_out(sw_fire_db)
    );

    switch_conditioner #(
        .DEBOUNCE_TICKS(20)
    ) u_maintenance_conditioner (
        .clk(clk),
        .reset(reset),
        .tick_1khz(door_tick),
        .switch_in(sw_maintenance),
        .switch_out(sw_maintenance_db)
    );

    // Inactivity timer
    inactivity_timer #(
        .TIMEOUT_TICKS(5)
    ) u_inactivity_timer (
        .clk(clk),
        .reset(reset),
        .floor_tick(floor_tick),
        .system_idle(system_idle),
        .inactivity_timeout(inactivity_timeout)
    );

    // Special modes controller
    special_modes_fsm u_special_modes (
        .clk(clk),
        .reset(reset),
        .emergency_switch(sw_emergency_db),
        .fire_switch(sw_fire_db),
        .maintenance_switch(sw_maintenance_db),
        .inactivity_timeout(inactivity_timeout),
        .system_idle(system_idle),
        .wake_request(new_request),
        .emergency_active(emergency_active),
        .fire_active(fire_active),
        .maintenance_active(maintenance_active),
        .sleep_active(sleep_active),
        .recall_request(recall_request),
        .clear_all_requests(clear_all_requests)
    );

    // Person counter
    person_counter #(
    .MAX_CAPACITY(8)
	 ) u_person_counter (
    .clk(clk),
    .reset(reset),
    .enter_btn(enter_key_pulse),
    .exit_btn(exit_key_pulse),
    .count(person_count),
    .is_empty(person_empty),
    .is_full(person_full)
	 );

    // Clear serviced floor request
    assign clear_request = door_timer_done;
    assign clear_floor   = target_floor;
	 

    // =====================================================
    // SEVEN-SEGMENT DISPLAY DECODERS
    //
    // Bit order: {a,b,c,d,e,f,g,dp}
    // Based on the working common-cathode test.
    //
    // Display 1: current floor (assumes encoded 0..3
    //            represents physical floors 1..4)
    // Display 3: 0 = door open, C = door closed
    // Display 4: person count 0..8
    // =====================================================

    reg [7:0] floor_pattern;
    reg [7:0] door_pattern;
    reg [7:0] people_pattern;

    // Display 1: Current floor
always @(*) begin
    case (current_floor)
        2'd0: seg1 = 8'b01100000; // Floor 1
        2'd1: seg1 = 8'b11011010; // Floor 2
        2'd2: seg1 = 8'b11110010; // Floor 3
        2'd3: seg1 = 8'b01100110; // Floor 4
        default: seg1 = 8'b11111100; // 0
    endcase
end
	 //Display 2: Always zero
always @(*) begin
    seg2 = 8'b00000000;  // Display 0
end

// Display 3: Door status
always @(*) begin
    if (door_open)
        seg3 = 8'b11111100; // 0 = Open
    else
        seg3 = 8'b10011100; // C = Closed
end

// Display 4: Person counter
always @(*) begin
    case (person_count)
        4'd0: seg4 = 8'b11111100;
        4'd1: seg4 = 8'b01100000;
        4'd2: seg4 = 8'b11011010;
        4'd3: seg4 = 8'b11110010;
        4'd4: seg4 = 8'b01100110;
        4'd5: seg4 = 8'b10110110;
        4'd6: seg4 = 8'b10111110;
        4'd7: seg4 = 8'b11100000;
        4'd8: seg4 = 8'b11111110;
        default: seg4 = 8'b11111100;
    endcase
end	
	
    // On-board LEDs
    assign leds[0]   = moving_up;
    assign leds[1]   = moving_down;
    //assign leds[2]   = door_open;
    assign leds[3]   = request_valid;
    assign leds[5:4] = current_floor;
    //assign leds[7:6] = pending_requests[1:0];
	 assign buzzer = emergency_active;
	 assign relay = destination_reached;
	 assign leds[2]   = system_idle;
	 assign leds[7]   = sleep_active;

endmodule
