
module person_counter #(
    parameter integer MAX_CAPACITY = 8
)(
    input wire clk,
    input wire reset,
    input wire enter_btn,
    input wire exit_btn,

    output reg [3:0] count,
    output wire is_empty,
    output wire is_full
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 4'd0;
        end
        else begin
            if (enter_btn && !exit_btn) begin
                if (count < MAX_CAPACITY)
                    count <= count + 1'b1;
            end
            else if (exit_btn && !enter_btn) begin
                if (count > 0)
                    count <= count - 1'b1;
            end
        end
    end

    assign is_empty = (count == 4'd0);
    assign is_full = (count >= MAX_CAPACITY);

endmodule
