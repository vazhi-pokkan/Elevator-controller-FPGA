module special_modes_fsm (
    input clk,
    input reset,
    input emergency_switch,
    input fire_switch,
    input maintenance_switch,
    input inactivity_timeout,
    input system_idle,
    input wake_request,
    output reg emergency_active,
    output reg fire_active,
    output reg maintenance_active,
    output reg sleep_active,
    output wire recall_request,
    output wire clear_all_requests
);
assign recall_request = emergency_active | fire_active;
assign clear_all_requests = recall_request | maintenance_active;

always @(*) begin
    // Mutually exclusive mode flags; emergency has highest priority.
    emergency_active = emergency_switch;
    fire_active = fire_switch & ~emergency_switch;
    maintenance_active = maintenance_switch & ~emergency_switch & ~fire_switch;
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        sleep_active <= 1'b0;
    end else begin
        if (emergency_active || fire_active || maintenance_active || wake_request || !system_idle)
            sleep_active <= 1'b0;
        else if (inactivity_timeout && system_idle)
            sleep_active <= 1'b1;
    end
end
endmodule
