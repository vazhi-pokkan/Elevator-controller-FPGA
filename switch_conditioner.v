module switch_conditioner #(parameter integer DEBOUNCE_TICKS = 20) (
    input clk,
    input reset,
    input tick_1khz,
    input switch_in,
    output reg switch_out
);
reg sync1, sync2;
reg [15:0] count;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        sync1 <= 1'b0;
        sync2 <= 1'b0;
        switch_out <= 1'b0;
        count <= 16'd0;
    end else begin
        sync1 <= switch_in;
        sync2 <= sync1;

        if (sync2 == switch_out) begin
            count <= 16'd0;
        end else if (tick_1khz) begin
            if (count >= DEBOUNCE_TICKS - 1) begin
                switch_out <= sync2;
                count <= 16'd0;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
end
endmodule
