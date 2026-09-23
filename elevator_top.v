module elevator_top(
    input        clk,
    input        reset,

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


    // =========================================================
    // Clock divider
    // 20 MHz clock
    //
    // floor_tick = 2 Hz
    // door_tick  = 1 kHz
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

        .moving_up(moving_up),
        .moving_down(moving_down),
        .door_open(door_open)
    );


    // =========================================================
    // Clear request after door cycle
    // =========================================================

    assign clear_request = door_timer_done;
    assign clear_floor   = target_floor;


    // =========================================================
    // LCD DISPLAY
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
    // LED 0 = Moving UP
    // LED 1 = Moving DOWN
    // LED 2 = Door OPEN
    // LED 3 = Request active
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