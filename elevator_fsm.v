module elevator_fsm(
    input clk,
    input reset,
    input request_valid,
    input move_up,
    input move_down,
    input destination_reached,
    input door_timer_done,
    input [1:0] current_floor,
    input floor_tick,
    input recall_request,
    input maintenance_active,
    output reg system_idle,
    output reg moving_up,
    output reg moving_down,
    output reg door_open
);
localparam IDLE        = 4'd0,
           MOVING_UP   = 4'd1,
           MOVING_DOWN = 4'd2,
           DOOR_OPEN   = 4'd3,
           DOOR_CLOSE  = 4'd4,
           RECALL_STOP = 4'd5,
           RECALL_DOWN = 4'd6,
           RECALL_HOLD = 4'd7,
           MAINT_STOP  = 4'd8;

reg [3:0] state, next_state;

always @(posedge clk or posedge reset) begin
    if (reset)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    next_state = state;

    // Emergency/fire recall always has highest priority.
    if (recall_request) begin
        if (current_floor == 2'd0)
            next_state = RECALL_HOLD;
        else if (state == MOVING_UP || state == MOVING_DOWN)
            next_state = RECALL_STOP;
        else if (state == RECALL_STOP)
            next_state = RECALL_DOWN;
        else
            next_state = RECALL_DOWN;
    end
    // Maintenance stops passenger service and holds the elevator.
    else if (maintenance_active) begin
        next_state = MAINT_STOP;
    end
    else begin
        case (state)
            IDLE: begin
                if (request_valid) begin
                    if (move_up) next_state = MOVING_UP;
                    else if (move_down) next_state = MOVING_DOWN;
                    else if (destination_reached) next_state = DOOR_OPEN;
                end
            end
            MOVING_UP:   if (destination_reached) next_state = DOOR_OPEN;
            MOVING_DOWN: if (destination_reached) next_state = DOOR_OPEN;
            DOOR_OPEN:   if (door_timer_done) next_state = DOOR_CLOSE;
            DOOR_CLOSE: next_state = IDLE;
            RECALL_STOP: next_state = IDLE;
            RECALL_DOWN: begin
                if (!recall_request) next_state = IDLE;
                else if (current_floor == 2'd0) next_state = RECALL_HOLD;
                else if (floor_tick) next_state = RECALL_DOWN;
            end
            RECALL_HOLD: begin
                if (!recall_request) next_state = DOOR_CLOSE;
            end
            MAINT_STOP: if (!maintenance_active) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
end

always @(*) begin
    moving_up = 1'b0;
    moving_down = 1'b0;
    door_open = 1'b0;
    system_idle = 1'b0;

    case (state)
        IDLE: begin
            system_idle = !request_valid;
        end
        MOVING_UP: moving_up = 1'b1;
        MOVING_DOWN: moving_down = 1'b1;
        DOOR_OPEN: door_open = 1'b1;
        RECALL_DOWN: begin
            if (recall_request && current_floor != 2'd0)
                moving_down = 1'b1;
        end
        RECALL_HOLD: door_open = 1'b1;
        default: begin end
    endcase
end
endmodule
