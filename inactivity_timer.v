module inactivity_timer #(parameter integer TIMEOUT_TICKS = 60) (
    input clk,
    input reset,
    input floor_tick,
    input system_idle,
    output reg inactivity_timeout
);
reg [31:0] count;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        count <= 32'd0;
        inactivity_timeout <= 1'b0;
    end else begin
        inactivity_timeout <= 1'b0;
        if (!system_idle) begin
            count <= 32'd0;
        end else if (floor_tick) begin
            if (count >= TIMEOUT_TICKS - 1) begin
                count <= 32'd0;
                inactivity_timeout <= 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
end
endmodule
