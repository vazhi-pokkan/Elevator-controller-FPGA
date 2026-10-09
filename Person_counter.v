
`timescale 1ns / 1ps

//======================================================
// Module: debounce
// Purpose: Synchronize and debounce a physical button
// Clock:   20 MHz
// Debounce duration: approximately 50 ms
//======================================================

module debounce #(
    parameter integer DEBOUNCE_COUNT = 1000000
)(
    input  wire clk,
    input  wire reset,
    input  wire btn_in,
    output reg  btn_out
);

    // Two-stage synchronizer
    reg sync1;
    reg sync2;

    // 20-bit counter for the debounce interval
    reg [19:0] counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync1   <= 1'b0;
            sync2   <= 1'b0;
            btn_out <= 1'b0;
            counter <= 20'd0;
        end
        else begin
            sync1 <= btn_in;
            sync2 <= sync1;

            // Reset the timer if the input matches
            // the currently accepted button state
            if (sync2 == btn_out) begin
                counter <= 20'd0;
            end
            else if (counter >= DEBOUNCE_COUNT - 1) begin
                btn_out <= sync2;
                counter <= 20'd0;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule


//======================================================
// Module: person_counter
// Purpose: Count people entering and exiting elevator
// Maximum capacity: 8 people
//======================================================

module person_counter (
    input  wire       clk,
    input  wire       reset,
    input  wire       enter_btn,
    input  wire       exit_btn,

    output reg  [3:0] count,
    output wire       is_empty,
    output wire       is_full
);

    parameter integer MAX_CAPACITY = 4;

    // Debounced button signals
    wire enter_clean;
    wire exit_clean;

    // Debounce ENTER button
    debounce enter_debounce (
        .clk(clk),
        .reset(reset),
        .btn_in(enter_btn),
        .btn_out(enter_clean)
    );

    // Debounce EXIT button
    debounce exit_debounce (
        .clk(clk),
        .reset(reset),
        .btn_in(exit_btn),
        .btn_out(exit_clean)
    );

    // Rising-edge detection registers
    reg enter_d;
    reg exit_d;

    wire enter_pulse = enter_clean & ~enter_d;
    wire exit_pulse  = exit_clean  & ~exit_d;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            enter_d <= 1'b0;
            exit_d  <= 1'b0;
        end
        else begin
            enter_d <= enter_clean;
            exit_d  <= exit_clean;
        end
    end

    // Person counting logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 4'd0;
        end
        else begin
            // One person enters
            if (enter_pulse && !exit_pulse) begin
                if (count < MAX_CAPACITY)
                    count <= count + 1'b1;
            end

            // One person exits
            else if (exit_pulse && !enter_pulse) begin
                if (count > 0)
                    count <= count - 1'b1;
            end

            // If both pulses occur together,
            // the count remains unchanged.
        end
    end

    // Status indicators
    assign is_empty = (count == 4'd0);
    assign is_full  = (count >= MAX_CAPACITY);

endmodule
