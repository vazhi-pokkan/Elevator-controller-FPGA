module keypad_scanner(
 input clk,
 input reset,
 input scan_tick,
 input [3:0] col,
 output reg [3:0] row,
 output reg new_request,
 output reg [1:0] request_floor
);
reg [1:0] row_index;
reg cycle_seen;
reg [3:0] cycle_key;
reg key_latched;
reg detected_valid;
reg [3:0] detected_key;
wire end_seen = cycle_seen | detected_valid;
wire [3:0] end_key = cycle_seen ? cycle_key : detected_key;

/*
  Keypad is scanned one row at a time.
  Rows are active LOW and columns are expected HIGH when idle.
  Standard 4x4 layout assumed:
       1 2 3 A
       4 5 6 B
       7 8 9 C
       * 0 # D
  Only keys 1,2,3,4 are used as floor requests.
*/
always @(*) begin
 row = 4'b1111;
 case(row_index)
  2'd0: row = 4'b1110;
  2'd1: row = 4'b1101;
  2'd2: row = 4'b1011;
  2'd3: row = 4'b0111;
 endcase
end

always @(*) begin
 detected_valid = 1'b0;
 detected_key = 4'hF;
 if(col != 4'b1111) begin
  detected_valid = 1'b1;
  if(col[0] == 1'b0) detected_key = {row_index,2'd0};
  else if(col[1] == 1'b0) detected_key = {row_index,2'd1};
  else if(col[2] == 1'b0) detected_key = {row_index,2'd2};
  else detected_key = {row_index,2'd3};
 end
end

always @(posedge clk or posedge reset) begin
 if(reset) begin
  row_index <= 2'd0;
  cycle_seen <= 1'b0;
  cycle_key <= 4'hF;
  key_latched <= 1'b0;
  new_request <= 1'b0;
  request_floor <= 2'd0;
 end
 else begin
  new_request <= 1'b0;

  if(scan_tick) begin
   if(detected_valid && !cycle_seen)
     cycle_key <= detected_key;

   if(row_index == 2'd3) begin
    if(end_seen) begin
     /* Only keypad keys 1,2,3,4 are floor requests. */
     if(end_key == 4'b0000) begin       // key 1 -> floor 1
      if(!key_latched) begin request_floor <= 2'd0; new_request <= 1'b1; end
      key_latched <= 1'b1;
     end
     else if(end_key == 4'b0001) begin  // key 2 -> floor 2
      if(!key_latched) begin request_floor <= 2'd1; new_request <= 1'b1; end
      key_latched <= 1'b1;
     end
     else if(end_key == 4'b0010) begin  // key 3 -> floor 3
      if(!key_latched) begin request_floor <= 2'd2; new_request <= 1'b1; end
      key_latched <= 1'b1;
     end
     else if(end_key == 4'b0100) begin  // key 4 -> floor 4
      if(!key_latched) begin request_floor <= 2'd3; new_request <= 1'b1; end
      key_latched <= 1'b1;
     end
    end
    else begin
     key_latched <= 1'b0;
    end

    cycle_seen <= 1'b0;
    cycle_key <= 4'hF;
   end
   else begin
    if(detected_valid) begin
     cycle_seen <= 1'b1;
     if(!cycle_seen) cycle_key <= detected_key;
    end
   end

   row_index <= row_index + 1'b1;
  end
 end
end
endmodule
