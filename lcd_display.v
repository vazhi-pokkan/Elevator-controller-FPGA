// ============================================================
// lcd_display.v
// 16x2 Character LCD Controller for VPTB-20
//
// LCD used in 4-bit mode:
//
// D4 -> R9
// D5 -> T9
// D6 -> T8
// D7 -> P8
// RS -> T10
// CS -> M10   (used as LCD Enable)
//
// Display:
//   FLOOR: 1
//   IDLE
//
//   FLOOR: 2
//   MOVING UP
//
//   FLOOR: 3
//   MOVING DOWN
//
//   FLOOR: 4
//   DOOR OPEN
//
// Clock: 20 MHz
// ============================================================

module lcd_display(
    input        clk,
    input        reset,

    input  [1:0] current_floor,
    input        moving_up,
    input        moving_down,
    input        door_open,

    output reg [7:0] lcd_data,
    output reg       lcd_rs,
    output reg       lcd_cs
);

    // --------------------------------------------------------
    // Timing
    // 20 MHz clock = 50 ns per clock
    //
    // 2000 clocks = 100 us
    // --------------------------------------------------------

    reg [15:0] tick_count;
    wire tick_100us;

    assign tick_100us = (tick_count == 16'd1999);

    always @(posedge clk or posedge reset) begin
        if (reset)
            tick_count <= 16'd0;
        else if (tick_100us)
            tick_count <= 16'd0;
        else
            tick_count <= tick_count + 1'b1;
    end

    // --------------------------------------------------------
    // LCD states
    // --------------------------------------------------------

    localparam S_POWER_WAIT  = 5'd0;
    localparam S_INIT1       = 5'd1;
    localparam S_INIT2       = 5'd2;
    localparam S_INIT3       = 5'd3;
    localparam S_INIT4       = 5'd4;
    localparam S_INIT5       = 5'd5;

    localparam S_SET_LINE1   = 5'd6;
    localparam S_WRITE_LINE1 = 5'd7;
    localparam S_SET_LINE2   = 5'd8;
    localparam S_WRITE_LINE2 = 5'd9;

    localparam S_REFRESH_WAIT = 5'd10;

    reg [4:0] state;

    // --------------------------------------------------------
    // LCD command/data control
    // --------------------------------------------------------

    reg [7:0] current_byte;
    reg       current_is_data;

    reg       send_pending;
    reg       high_nibble;

    // --------------------------------------------------------
    // Character position
    // --------------------------------------------------------

    reg [5:0] char_index;

    // --------------------------------------------------------
    // Power-up wait counter
    // --------------------------------------------------------

    reg [7:0] init_count;

    // --------------------------------------------------------
    // Message storage
    // --------------------------------------------------------

    reg [7:0] line1 [0:15];
    reg [7:0] line2 [0:15];

    integer i;

    // --------------------------------------------------------
    // Generate display text
    // --------------------------------------------------------

    always @(*) begin

        // Default spaces
        for (i = 0; i < 16; i = i + 1) begin
            line1[i] = 8'h20;
            line2[i] = 8'h20;
        end

        // -------------------------
        // Line 1: "FLOOR: X"
        // -------------------------

        line1[0] = "F";
        line1[1] = "L";
        line1[2] = "O";
        line1[3] = "O";
        line1[4] = "R";
        line1[5] = ":";
        line1[6] = " ";

        case (current_floor)
            2'd0: line1[7] = "1";
            2'd1: line1[7] = "2";
            2'd2: line1[7] = "3";
            2'd3: line1[7] = "4";
            default: line1[7] = "?";
        endcase

        // -------------------------
        // Line 2
        // -------------------------

        if (door_open) begin

            line2[0] = "D";
            line2[1] = "O";
            line2[2] = "O";
            line2[3] = "R";
            line2[4] = " ";
            line2[5] = "O";
            line2[6] = "P";
            line2[7] = "E";
            line2[8] = "N";

        end
        else if (moving_up) begin

            line2[0] = "M";
            line2[1] = "O";
            line2[2] = "V";
            line2[3] = "I";
            line2[4] = "N";
            line2[5] = "G";
            line2[6] = " ";
            line2[7] = "U";
            line2[8] = "P";

        end
        else if (moving_down) begin

            line2[0] = "M";
            line2[1] = "O";
            line2[2] = "V";
            line2[3] = "I";
            line2[4] = "N";
            line2[5] = "G";
            line2[6] = " ";
            line2[7] = "D";
            line2[8] = "O";
            line2[9] = "W";
            line2[10] = "N";

        end
        else begin

            line2[0] = "I";
            line2[1] = "D";
            line2[2] = "L";
            line2[3] = "E";

        end
    end

    // --------------------------------------------------------
    // LCD output
    //
    // Only D4-D7 are used.
    //
    // lcd_data[7:4] -> D7-D4
    // --------------------------------------------------------

    always @(*) begin

        lcd_data = 8'b00000000;
        lcd_rs   = current_is_data;
        lcd_cs   = 1'b0;

        if (send_pending) begin

            lcd_cs = 1'b1;

            if (high_nibble) begin
                lcd_data[7:4] = current_byte[7:4];
            end
            else begin
                lcd_data[7:4] = current_byte[3:0];
            end

        end
    end

    // --------------------------------------------------------
    // Main LCD state machine
    // --------------------------------------------------------

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            state          <= S_POWER_WAIT;

            init_count     <= 8'd0;
            char_index     <= 6'd0;

            current_byte  <= 8'h00;
            current_is_data <= 1'b0;

            send_pending   <= 1'b0;
            high_nibble    <= 1'b1;

        end
        else if (tick_100us) begin

            case (state)

                // ====================================================
                // Wait ~20 ms after power-up
                // ====================================================

                S_POWER_WAIT: begin

                    if (init_count >= 8'd200) begin
                        init_count <= 8'd0;
                        state <= S_INIT1;
                    end
                    else begin
                        init_count <= init_count + 1'b1;
                    end

                end


                // ====================================================
                // Function set: 4-bit, 2-line, 5x8 font
                // Command = 0x28
                // ====================================================

                S_INIT1: begin

                    current_byte   <= 8'h28;
                    current_is_data <= 1'b0;
                    send_pending   <= 1'b1;
                    high_nibble    <= 1'b1;

                    state <= S_INIT2;

                end


                // ====================================================
                // Display ON, cursor OFF
                // Command = 0x0C
                // ====================================================

                S_INIT2: begin

                    current_byte   <= 8'h0C;
                    current_is_data <= 1'b0;
                    send_pending   <= 1'b1;
                    high_nibble    <= 1'b1;

                    state <= S_INIT3;

                end


                // ====================================================
                // Entry mode
                // Command = 0x06
                // ====================================================

                S_INIT3: begin

                    current_byte   <= 8'h06;
                    current_is_data <= 1'b0;
                    send_pending   <= 1'b1;
                    high_nibble    <= 1'b1;

                    state <= S_INIT4;

                end


                // ====================================================
                // Clear display
                // Command = 0x01
                // ====================================================

                S_INIT4: begin

                    current_byte   <= 8'h01;
                    current_is_data <= 1'b0;
                    send_pending   <= 1'b1;
                    high_nibble    <= 1'b1;

                    init_count <= 8'd0;

                    state <= S_INIT5;

                end


                // ====================================================
                // Wait after clear
                // ====================================================

                S_INIT5: begin

                    if (init_count >= 8'd20) begin

                        init_count <= 8'd0;
                        char_index <= 6'd0;

                        state <= S_SET_LINE1;

                    end
                    else begin

                        init_count <= init_count + 1'b1;

                    end

                end


                // ====================================================
                // Set DDRAM address to first line
                // Command = 0x80
                // ====================================================

                S_SET_LINE1: begin

                    current_byte    <= 8'h80;
                    current_is_data <= 1'b0;

                    send_pending <= 1'b1;
                    high_nibble  <= 1'b1;

                    char_index <= 6'd0;

                    state <= S_WRITE_LINE1;

                end


                // ====================================================
                // Write first line
                // ====================================================

                S_WRITE_LINE1: begin

                    if (char_index < 16) begin

                        current_byte    <= line1[char_index];
                        current_is_data <= 1'b1;

                        send_pending <= 1'b1;
                        high_nibble  <= 1'b1;

                        char_index <= char_index + 1'b1;

                    end
                    else begin

                        char_index <= 6'd0;

                        state <= S_SET_LINE2;

                    end

                end


                // ====================================================
                // Set DDRAM address to second line
                // Command = 0xC0
                // ====================================================

                S_SET_LINE2: begin

                    current_byte    <= 8'hC0;
                    current_is_data <= 1'b0;

                    send_pending <= 1'b1;
                    high_nibble  <= 1'b1;

                    char_index <= 6'd0;

                    state <= S_WRITE_LINE2;

                end


                // ====================================================
                // Write second line
                // ====================================================

                S_WRITE_LINE2: begin

                    if (char_index < 16) begin

                        current_byte    <= line2[char_index];
                        current_is_data <= 1'b1;

                        send_pending <= 1'b1;
                        high_nibble  <= 1'b1;

                        char_index <= char_index + 1'b1;

                    end
                    else begin

                        init_count <= 8'd0;

                        state <= S_REFRESH_WAIT;

                    end

                end


                // ====================================================
                // Wait before refreshing
                // ====================================================

                S_REFRESH_WAIT: begin

                    if (init_count >= 8'd50) begin

                        init_count <= 8'd0;
                        char_index <= 6'd0;

                        state <= S_SET_LINE1;

                    end
                    else begin

                        init_count <= init_count + 1'b1;

                    end

                end


                default: begin

                    state <= S_POWER_WAIT;

                end

            endcase

        end

    end

endmodule