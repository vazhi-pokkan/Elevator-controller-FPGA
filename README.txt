ELEVATOR FPGA HARDWARE PACKAGE

Target: VPTB-20 / Spartan-6 / XC6SLX16
Default board clock: 20 MHz

FILES
- elevator_top.v          Top-level integration
- clock_divider.v        20 MHz -> floor tick + 1 kHz service tick
- keypad_scanner.v       4x4 matrix scanner; keys 1,2,3,4 = floors 1-4
- request_register.v     Pending request bitmap
- elevator_scheduler.v   Elevator-style request selection
- movement_logic.v       Up/down/destination decision
- floor_counter.v        Current floor register
- door_timer.v            Door-open timer
- elevator_fsm.v           Main elevator FSM
- sevenseg_floor.v        Current-floor decoder for display 1
- elevator_top.ucf       Pin constraints

TIMING
- FLOOR_TICK_DIV = 10,000,000 at 20 MHz -> 2 floor ticks/sec -> 0.5 s/floor
- DOOR_TICK_DIV = 20,000 at 20 MHz -> 1 kHz timer tick
- DOOR_TIME_TICKS = 2,000 -> 2 s door-open time

KEYPAD ASSUMPTION
Rows are active LOW and columns idle HIGH. Standard 4x4 layout is assumed:
  1 2 3 A
  4 5 6 B
  7 8 9 C
  * 0 # D
Only 1,2,3,4 are used as floor requests.

DISPLAY
Display 1 is common-cathode. Set J10 to the common-cathode position / GND as specified by the manual.
The segment table is active HIGH, matching the manual's character table.

IMPORTANT
1. Remove/disable older copies of modules with the same module names before adding these files.
2. Add elevator_top as the ISE top module.
3. Add elevator_top.ucf as the User Constraints File.
4. The manual lists the reset input at P175, but does not state its active polarity in the text. If pressing the board RESET button makes the design stay in reset, invert the reset signal in elevator_top.
5. The keypad column PULLUP constraints are included. If the board already provides pull-ups, they can remain; if ISE reports a constraint issue, remove only the four PULLUP lines.
6. The first hardware test should be keypad + LEDs/display before judging the complete elevator timing.
