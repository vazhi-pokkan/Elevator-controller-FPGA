module elevator_top(
    input        clk,
    input        reset,

    // Special-mode switches (active HIGH; pin LOCs must match board manual)
    input        sw_emergency,
    input        sw_fire,
    input        sw_maintenance,

    // Person counter switches
    input        enter_btn,
    input        exit_btn,

    // 4x4 matrix keypad
    input  [3:0] keypad_col,
    output [3:0] keypad_row,

    // 16x2 LCD
    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_cs,

    // On-board LEDs
    output [7:0] leds
);

    // =========================================================
    // Internal signals
    // =========================================================

    wire floor_tick;
    wire door_tick;
    wire sw_emergency_db, sw_fire_db, sw_maintenance_db;
    wire emergency_active, fire_active, maintenance_active, sleep_active;
    wire recall_request, clear_all_requests, inactivity_timeout;
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

    // Person counter signals
    wire [3:0] person_count;
    wire person_empty;
    wire person_full;


    // =========================================================
    // Clock divider
    // 20 MHz clock
    // =========================================================

    clock_divider #(
        .FLOOR_TICK_DIV(10000000),
        .DOOR_TICK_DIV(20000)
    ) u_clock (
        .clk(clk),
        .reset(reset),
        .floor_tick(floor_tick),
        .door_tick(door_tick)
    );


    // =========================================================
    // 4x4 keypad scanner
    // =========================================================

    keypad_scanner u_keypad (
        .clk(clk),
        .reset(reset),
        .scan_tick(door_tick),
        .col(keypad_col),
        .row(keypad_row),
        .new_request(new_request),
        .request_floor(request_floor)
    );


    // =========================================================
    // Request register
    // =========================================================

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


    // =========================================================
    // Elevator scheduler
    // =========================================================

    elevator_scheduler u_sched (
        .current_floor(current_floor),
        .pending_requests(pending_requests),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .request_valid(request_valid),
        .target_floor(target_floor)
    );


    // =========================================================
    // Movement logic
    // =========================================================

    movement_logic u_move (
        .current_floor(current_floor),
        .target_floor(target_floor),
        .request_valid(request_valid),
        .move_up(move_up),
        .move_down(move_down),
        .destination_reached(destination_reached)
    );


    // =========================================================
    // Floor counter
    // =========================================================

    floor_counter u_floor (
        .clk(clk),
        .reset(reset),
        .floor_tick(floor_tick),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .current_floor(current_floor)
    );


    // =========================================================
    // Door timer
    // =========================================================

    door_timer #(
        .DOOR_TIME_TICKS(2000)
    ) u_door_timer (
        .clk(clk),
        .reset(reset),
        .door_open(door_open),
        .door_tick(door_tick),
        .door_timer_done(door_timer_done)
    );


    // =========================================================
    // Main elevator FSM
    // =========================================================

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
        .maintenance_active(maintenance_active),
        .system_idle(system_idle),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .door_open(door_open)
    );


    // =========================================================
    // Special-mode switch conditioning
    // 2-flop synchronizer + 20 ms debounce at 1 kHz
    // =========================================================

    switch_conditioner #(.DEBOUNCE_TICKS(20)) u_emergency_conditioner (
        .clk(clk), .reset(reset), .tick_1khz(door_tick),
        .switch_in(sw_emergency), .switch_out(sw_emergency_db)
    );

    switch_conditioner #(.DEBOUNCE_TICKS(20)) u_fire_conditioner (
        .clk(clk), .reset(reset), .tick_1khz(door_tick),
        .switch_in(sw_fire), .switch_out(sw_fire_db)
    );

    switch_conditioner #(.DEBOUNCE_TICKS(20)) u_maintenance_conditioner (
        .clk(clk), .reset(reset), .tick_1khz(door_tick),
        .switch_in(sw_maintenance), .switch_out(sw_maintenance_db)
    );

    // =========================================================
    // Inactivity timer: 30 seconds at 2 floor ticks/second
    // =========================================================

    inactivity_timer #(.TIMEOUT_TICKS(60)) u_inactivity_timer (
        .clk(clk), .reset(reset), .floor_tick(floor_tick),
        .system_idle(system_idle), .inactivity_timeout(inactivity_timeout)
    );

    // =========================================================
    // Special modes controller
    // Priority: emergency > fire > maintenance > sleep
    // =========================================================

    special_modes_fsm u_special_modes (
        .clk(clk), .reset(reset),
        .emergency_switch(sw_emergency_db),
        .fire_switch(sw_fire_db),
        .maintenance_switch(sw_maintenance_db),
        .inactivity_timeout(inactivity_timeout),
        .system_idle(system_idle), .wake_request(new_request),
        .emergency_active(emergency_active), .fire_active(fire_active),
        .maintenance_active(maintenance_active), .sleep_active(sleep_active),
        .recall_request(recall_request), .clear_all_requests(clear_all_requests)
    );

    // =========================================================
    // Person counter
    // Maximum capacity = 8 people
    // =========================================================

    person_counter #(
        .MAX_CAPACITY(8)
    ) u_person_counter (
        .clk(clk),
        .reset(reset),
        .enter_btn(enter_btn),
        .exit_btn(exit_btn),
        .count(person_count),
        .is_empty(person_empty),
        .is_full(person_full)
    );


    // =========================================================
    // Clear request after door cycle
    // =========================================================

    assign clear_request = door_timer_done;
    assign clear_floor   = target_floor;


    // =========================================================
    // LCD DISPLAY
    // Existing interface preserved
    // =========================================================

    lcd_display u_display (
        .clk(clk),
        .reset(reset),
        .current_floor(current_floor),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .door_open(door_open),
        .lcd_data(lcd_data),
        .lcd_rs(lcd_rs),
        .lcd_cs(lcd_cs)
    );


    // =========================================================
    // ON-BOARD LEDs
    //
    // LED 0   = Moving UP
    // LED 1   = Moving DOWN
    // LED 2   = Door OPEN
    // LED 3   = Request active
    // LED 4-5 = Current floor (binary)
    // LED 6-7 = Pending requests 1-2
    // =========================================================

    assign leds[0] = moving_up;
    assign leds[1] = moving_down;
    assign leds[2] = door_open;
    assign leds[3] = request_valid;

    assign leds[5:4] = current_floor;
    assign leds[7:6] = pending_requests[1:0];

endmodule
