
module keypad_scanner(
    input clk,
    input reset,
    input scan_tick,
    input [3:0] col,
    output reg [3:0] row,
    output reg new_request,
    output reg [1:0] request_floor,
    output reg enter_pulse,
    output reg exit_pulse
);

    reg [1:0] row_index;
    reg cycle_seen;
    reg [3:0] cycle_key;
    reg key_latched;

    reg detected_valid;
    reg [3:0] detected_key;

    wire end_seen = cycle_seen | detected_valid;
    wire [3:0] end_key =
        cycle_seen ? cycle_key : detected_key;

    // Active-low row selection
    always @(*) begin
        case (row_index)
            2'd0: row = 4'b1110;
            2'd1: row = 4'b1101;
            2'd2: row = 4'b1011;
            2'd3: row = 4'b0111;
            default: row = 4'b1111;
        endcase
    end

    // Decode the active row and pressed column
    always @(*) begin
        detected_valid = 1'b0;
        detected_key = 4'hF;

        if (col != 4'b1111) begin
            detected_valid = 1'b1;

            if      (col[0] == 1'b0)
                detected_key = {row_index, 2'd0};
            else if (col[1] == 1'b0)
                detected_key = {row_index, 2'd1};
            else if (col[2] == 1'b0)
                detected_key = {row_index, 2'd2};
            else
                detected_key = {row_index, 2'd3};
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            row_index    <= 2'd0;
            cycle_seen   <= 1'b0;
            cycle_key    <= 4'hF;
            key_latched  <= 1'b0;
            new_request  <= 1'b0;
            request_floor <= 2'd0;
            enter_pulse  <= 1'b0;
            exit_pulse   <= 1'b0;
        end
        else begin
            new_request <= 1'b0;
            enter_pulse <= 1'b0;
            exit_pulse  <= 1'b0;

            if (scan_tick) begin

                if (detected_valid && !cycle_seen)
                    cycle_key <= detected_key;

                if (row_index == 2'd3) begin

                    if (end_seen) begin
                        // Row 1, columns 1, 2, 3:
                        // request floors 1, 2, 3.
                        if (end_key == 4'b0000) begin
                            if (!key_latched) begin
                                request_floor <= 2'd0;
                                new_request <= 1'b1;
                            end
                            key_latched <= 1'b1;
                        end
                        else if (end_key == 4'b0001) begin
                            if (!key_latched) begin
                                request_floor <= 2'd1;
                                new_request <= 1'b1;
                            end
                            key_latched <= 1'b1;
                        end
                        else if (end_key == 4'b0010) begin
                            if (!key_latched) begin
                                request_floor <= 2'd2;
                                new_request <= 1'b1;
                            end
                            key_latched <= 1'b1;
                        end

                        // Row 1, column 4: request floor 4.
                        else if (end_key == 4'b0011) begin
                            if (!key_latched) begin
                                request_floor <= 2'd3;
                                new_request <= 1'b1;
                            end
                            key_latched <= 1'b1;
                        end

                        // Row 4, column 1: ENTER.
                        else if (end_key == 4'b1100) begin
                            if (!key_latched)
                                enter_pulse <= 1'b1;

                            key_latched <= 1'b1;
                        end

                        // Row 4, column 4: EXIT.
                        else if (end_key == 4'b1111) begin
                            if (!key_latched)
                                exit_pulse <= 1'b1;

                            key_latched <= 1'b1;
                        end
                    end
                    else begin
                        // Release detected: permit next press.
                        key_latched <= 1'b0;
                    end

                    cycle_seen <= 1'b0;
                    cycle_key <= 4'hF;
                end
                else begin
                    if (detected_valid) begin
                        cycle_seen <= 1'b1;

                        if (!cycle_seen)
                            cycle_key <= detected_key;
                    end
                end

                row_index <= row_index + 1'b1;
            end
        end
    end

endmodule
