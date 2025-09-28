/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator Floor Logic Controller
// Filename:                        floor_logic.sv
// Version:                         6
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/7/2025 
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Doctor Jeffrey Walling 
//  
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)  
// Simulation Tool:                 iVerilog 12.0
// 
// Description:                     Floor request logic controller that manages elevator call buttons,
//                                  destination requests, and priority handling for the elevator FSM.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/7/2025    DJL  1        Original Code
//                                  9/13/2025   DJL  2        Revised logic for elevator calls
//                                  9/13/2025   DJL  3        Converted to SystemVerilog
//                                  9/14/2025   DJL  4        Streamlined Code
//                                  9/14/2025   DJL  5        Updated code for iVerilog Compatibility
//                                  9/15/2025   DJL  6        Added stack-based floor selection logic
/////////////////////////////////////////////////////////////////////////////////////////////////////////

module floor_logic_control_unit(clock, reset_n, floor_call_buttons, panel_buttons, door_open_btn, door_close_btn, emergency_btn, power_switch, current_floor_state, elevator_state, elevator_moving, elevator_direction, elevator_floor_selector, direction_selector, activate_elevator, call_button_lights, panel_button_lights, door_open_allowed, door_close_allowed);
    input                                                       clock;
    input                                                       reset_n;
    // Button inputs (active high when pressed)
    input                       [10:0]                          floor_call_buttons;      // External call buttons (floors 1-11)
    input                       [10:0]                          panel_buttons;           // Internal destination buttons (floors 1-11)
    input                                                       door_open_btn;
    input                                                       door_close_btn;
    input                                                       emergency_btn;
    input                                                       power_switch;                   // Power switch input  
    // Elevator status from FSM
    input                       [3:0]                           current_floor_state;      // Current floor from FSM (FLOOR_1 to FLOOR_11)
    input                       [4:0]                           elevator_state;           // Current state from elevator_fsm
    input                                                       elevator_moving;                // Derived from FSM state (UP/DOWN states)
    input                                                       elevator_direction;             // 1=up, 0=down 
    // Outputs to FSM
    output                      [3:0]                           elevator_floor_selector;
    output                                                      direction_selector;
    output                                                      activate_elevator;
    output                                                      door_open_allowed;
    output                                                      door_close_allowed;
    // Button status outputs (for illumination)
    output                      [10:0]                          call_button_lights;
    output                      [10:0]                          panel_button_lights;

    reg                         [3:0]                           elevator_floor_selector;
    reg                                                         door_open_allowed;
    reg                                                         door_close_allowed;
    reg                                                         direction_selector;
    reg                                                         activate_elevator;
    // Button status outputs (for illumination)
    reg                         [10:0]                          call_button_lights;
    reg                         [10:0]                          panel_button_lights;
    reg                         [3:0]                           next_floor;

    // Memory Unit for Elevator Requests
    reg                         [512:0]                         elevator_memory; 
    reg                         [7:0]                           stack_pointer;
    reg                         [7:0]                           stack_pointer_temporary;
    reg                                                         stack_full;
    reg                                                         stack_empty;
    reg                         [15:0]                          remaining_requests;
    reg                         [3:0]                           floor_number;

    parameter                   STOP_FL1                      = 5'h00,
                                STOP_FL2                      = 5'h01,
                                STOP_FL3                      = 5'h02,  
                                STOP_FL4                      = 5'h03,
                                STOP_FL5                      = 5'h04,
                                STOP_FL6                      = 5'h05,
                                STOP_FL7                      = 5'h06, 
                                STOP_FL8                      = 5'h07,
                                STOP_FL9                      = 5'h08,      
                                STOP_FL10                     = 5'h09,
                                STOP_FL11                     = 5'h0A, 
                                UP_F1_F2                      = 5'h0B,
                                UP_F2_F3                      = 5'h0C,
                                UP_F3_F4                      = 5'h0D,
                                UP_F4_F5                      = 5'h0E,
                                UP_F5_F6                      = 5'h0F,
                                UP_F6_F7                      = 5'h10,
                                UP_F7_F8                      = 5'h11,
                                UP_F8_F9                      = 5'h12,
                                UP_F9_F10                     = 5'h13,
                                UP_F10_F11                    = 5'h14,
                                DOWN_F11_F10                  = 5'h15,
                                DOWN_F10_F9                   = 5'h16,
                                DOWN_F9_F8                    = 5'h17,
                                DOWN_F8_F7                    = 5'h18,
                                DOWN_F7_F6                    = 5'h19,
                                DOWN_F6_F5                    = 5'h1A,
                                DOWN_F5_F4                    = 5'h1B,
                                DOWN_F4_F3                    = 5'h1C,
                                DOWN_F3_F2                    = 5'h1D,
                                DOWN_F2_F1                    = 5'h1E,
                                EMERGENCY                     = 5'h1F;
    
    parameter                   FLOOR_1                       = 4'h0,
                                FLOOR_2                       = 4'h1,
                                FLOOR_3                       = 4'h2,
                                FLOOR_4                       = 4'h3,
                                FLOOR_5                       = 4'h4,
                                FLOOR_6                       = 4'h5,
                                FLOOR_7                       = 4'h6,
                                FLOOR_8                       = 4'h7,
                                FLOOR_9                       = 4'h8,
                                FLOOR_10                      = 4'h9,
                                FLOOR_11                      = 4'hA,
                                EMERGENCY_STATE               = 4'hF;                               


// Emergency handling - clear all requests
always @(*) begin
    if (!reset_n) begin
       // direction_selector <= 1'b1; 
        //door_open_allowed <= 1'b0;
        //door_close_allowed <= 1'b0;
    end 
    else if (!power_switch) begin
        elevator_memory <= 44'b0;
    end
    else if (emergency_btn) begin

        //direction_selector <= 1'b1; 
        //elevator_floor_selector <= EMERGENCY_STATE;
    end
end

// Button reader - push floor requests onto stack (FIXED)
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
        floor_number <= 4'd0;
    end
    else if (power_switch && !emergency_btn) begin  // Remove stack_full condition
        // Check elevator panel buttons (internal requests)
        case (1'b1)
            panel_buttons[0] && current_floor_state != FLOOR_1 && !panel_button_lights[0]: begin
                floor_number = 4'd0;
                panel_button_lights[0] <= 1'b1;
            end
            panel_buttons[1] && current_floor_state != FLOOR_2 && !panel_button_lights[1]: begin
                floor_number = 4'd1;
                panel_button_lights[1] <= 1'b1;
            end
            panel_buttons[2] && current_floor_state != FLOOR_3 && !panel_button_lights[2]: begin
                floor_number = 4'd2;
                panel_button_lights[2] <= 1'b1;
            end
            panel_buttons[3] && current_floor_state != FLOOR_4 && !panel_button_lights[3]: begin
                floor_number = 4'd3;
                panel_button_lights[3] <= 1'b1;
            end
            panel_buttons[4] && current_floor_state != FLOOR_5 && !panel_button_lights[4]: begin
                floor_number = 4'd4;
                panel_button_lights[4] <= 1'b1;
            end
            panel_buttons[5] && current_floor_state != FLOOR_6 && !panel_button_lights[5]: begin
                floor_number = 4'd5;
                panel_button_lights[5] <= 1'b1;
            end
            panel_buttons[6] && current_floor_state != FLOOR_7 && !panel_button_lights[6]: begin
                floor_number = 4'd6;
                panel_button_lights[6] <= 1'b1;
            end
            panel_buttons[7] && current_floor_state != FLOOR_8 && !panel_button_lights[7]: begin
                floor_number = 4'd7;
                panel_button_lights[7] <= 1'b1;
            end
            panel_buttons[8] && current_floor_state != FLOOR_9 && !panel_button_lights[8]: begin
                floor_number = 4'd8;
                panel_button_lights[8] <= 1'b1;
            end
            panel_buttons[9] && current_floor_state != FLOOR_10 && !panel_button_lights[9]: begin
                floor_number = 4'd9;
                panel_button_lights[9] <= 1'b1;
            end
            panel_buttons[10] && current_floor_state != FLOOR_11 && !panel_button_lights[10]: begin
                floor_number = 4'd10;
                panel_button_lights[10] <= 1'b1;
            end
        endcase
        // Check floor call buttons (external requests)
        case (1'b1)
            floor_call_buttons[0] && current_floor_state != FLOOR_1 && !call_button_lights[0]: begin
                floor_number = FLOOR_1;
                call_button_lights[0] <= 1'b1;
            end
            floor_call_buttons[1] && current_floor_state != FLOOR_2 && !call_button_lights[1]: begin
                floor_number = FLOOR_2;
                call_button_lights[1] <= 1'b1;
            end
            floor_call_buttons[2] && current_floor_state != FLOOR_3 && !call_button_lights[2]: begin
                floor_number = FLOOR_3;
                call_button_lights[2] <= 1'b1;
            end
            floor_call_buttons[3] && current_floor_state != FLOOR_4 && !call_button_lights[3]: begin
                floor_number = FLOOR_4;
                call_button_lights[3] <= 1'b1;
            end
            floor_call_buttons[4] && current_floor_state != FLOOR_5 && !call_button_lights[4]: begin
                floor_number = FLOOR_5;
                call_button_lights[4] <= 1'b1;
            end
            floor_call_buttons[5] && current_floor_state != FLOOR_6 && !call_button_lights[5]: begin
                floor_number = FLOOR_6;
                call_button_lights[5] <= 1'b1;
            end
            floor_call_buttons[6] && current_floor_state != FLOOR_7 && !call_button_lights[6]: begin
                floor_number =FLOOR_7;
                call_button_lights[6] <= 1'b1;
            end
            floor_call_buttons[7] && current_floor_state != FLOOR_8 && !call_button_lights[7]: begin
                floor_number = FLOOR_8;
                call_button_lights[7] <= 1'b1;
            end
            floor_call_buttons[8] && current_floor_state != FLOOR_9 && !call_button_lights[8]: begin
                floor_number = FLOOR_9;
                call_button_lights[8] <= 1'b1;
            end
            floor_call_buttons[9] && current_floor_state != FLOOR_10 && !call_button_lights[9]: begin
                floor_number = FLOOR_10;
                call_button_lights[9] <= 1'b1;
            end
            floor_call_buttons[10] && current_floor_state != FLOOR_11 && !call_button_lights[10]: begin
                floor_number = FLOOR_11;
                call_button_lights[10] <= 1'b1;
            end
        endcase
        // Check if elevator arrived at selected floor, clear light
        if (power_switch && !stack_full && !elevator_moving) begin
            case (1'b1)
                (!activate_elevator) && current_floor_state == FLOOR_1: begin
                    panel_button_lights[0] <= 1'b0;
                    call_button_lights[0] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_2: begin
                    panel_button_lights[1] <= 1'b0;
                    call_button_lights[1] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_3: begin
                    panel_button_lights[2] <= 1'b0;
                    call_button_lights[2] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_4: begin
                    panel_button_lights[3] <= 1'b0;
                    call_button_lights[3] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_5: begin
                    panel_button_lights[4] <= 1'b0;
                    call_button_lights[4] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_6: begin
                    panel_button_lights[5] <= 1'b0;
                    call_button_lights[5] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_7: begin
                    panel_button_lights[6] <= 1'b0;
                    call_button_lights[6] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_8: begin
                    panel_button_lights[7] <= 1'b0;
                    call_button_lights[7] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_9: begin
                    panel_button_lights[8] <= 1'b0;
                    call_button_lights[8] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_10: begin
                    panel_button_lights[9] <= 1'b0;
                    call_button_lights[9] <= 1'b0;
                end
                (!activate_elevator) && current_floor_state == FLOOR_11: begin
                    panel_button_lights[10] <= 1'b0;
                    call_button_lights[10] <= 1'b0;
                end
            endcase
        end
    end
end
// OG Stack - Will need work.
always @(*) begin
    if (!reset_n) begin
        elevator_memory <= 512'b0;
        stack_pointer <= 4'b0;
        stack_full <= 1'b0;
        stack_empty <= 1'b1;
        remaining_requests <= 16'b0;
    end
    else begin
        if (!stack_full) begin
            case (stack_pointer)
                8'h00: elevator_memory[3:0] = floor_number;
                8'h01: elevator_memory[7:4] = floor_number;
                8'h02: elevator_memory[11:8] = floor_number;
                8'h03: elevator_memory[15:12] = floor_number;
                8'h04: elevator_memory[19:16] = floor_number;
                8'h05: elevator_memory[23:20] = floor_number;
                8'h06: elevator_memory[27:24] = floor_number;
                8'h07: elevator_memory[31:28] = floor_number;
                8'h08: elevator_memory[35:32] = floor_number;
                8'h09: elevator_memory[39:36] = floor_number;
                8'h0A: elevator_memory[43:40] = floor_number;
                8'h0B: elevator_memory[47:44] = floor_number;
                8'h0C: elevator_memory[51:48] = floor_number;
                8'h0D: elevator_memory[55:52] = floor_number;
                8'h0E: elevator_memory[59:56] = floor_number;
                8'h0F: elevator_memory[63:60] = floor_number;
                8'h10: elevator_memory[67:64] = floor_number;
                8'h11: elevator_memory[71:68] = floor_number;
                8'h12: elevator_memory[75:72] = floor_number;
                8'h13: elevator_memory[79:76] = floor_number;
                8'h14: elevator_memory[83:80] = floor_number;
                8'h15: elevator_memory[87:84] = floor_number;
                8'h16: elevator_memory[91:88] = floor_number;
                8'h17: elevator_memory[95:92] = floor_number;
                8'h18: elevator_memory[99:96] = floor_number;
                8'h19: elevator_memory[103:100] = floor_number;
                8'h1A: elevator_memory[107:104] = floor_number;
                8'h1B: elevator_memory[111:108] = floor_number;
                8'h1C: elevator_memory[115:112] = floor_number;
                8'h1D: elevator_memory[119:116] = floor_number;
                8'h1E: elevator_memory[123:120] = floor_number;
                8'h1F: elevator_memory[127:124] = floor_number;
                8'h20: elevator_memory[131:128] = floor_number;
                8'h21: elevator_memory[135:132] = floor_number;
                8'h22: elevator_memory[139:136] = floor_number;
                8'h23: elevator_memory[143:140] = floor_number;
                8'h24: elevator_memory[147:144] = floor_number;
                8'h25: elevator_memory[151:148] = floor_number;
                8'h26: elevator_memory[155:152] = floor_number;
                8'h27: elevator_memory[159:156] = floor_number;
                8'h28: elevator_memory[163:160] = floor_number;
                8'h29: elevator_memory[167:164] = floor_number;
                8'h2A: elevator_memory[171:168] = floor_number;
                8'h2B: elevator_memory[175:172] = floor_number;
                8'h2C: elevator_memory[179:176] = floor_number;
                8'h2D: elevator_memory[183:180] = floor_number;
                8'h2E: elevator_memory[187:184] = floor_number;
                8'h2F: elevator_memory[191:188] = floor_number;
                8'h30: elevator_memory[195:192] = floor_number;
                8'h31: elevator_memory[199:196] = floor_number;
                8'h32: elevator_memory[203:200] = floor_number;
                8'h33: elevator_memory[207:204] = floor_number;
                8'h34: elevator_memory[211:208] = floor_number;
                8'h35: elevator_memory[215:212] = floor_number;
                8'h36: elevator_memory[219:216] = floor_number;
                8'h37: elevator_memory[223:220] = floor_number;
                8'h38: elevator_memory[227:224] = floor_number;
                8'h39: elevator_memory[231:228] = floor_number;
                8'h3A: elevator_memory[235:232] = floor_number;
                8'h3B: elevator_memory[239:236] = floor_number;
                8'h3C: elevator_memory[243:240] = floor_number;
                8'h3D: elevator_memory[247:244] = floor_number;
                8'h3E: elevator_memory[251:248] = floor_number;
                8'h3F: elevator_memory[255:252] = floor_number;
                8'h40: elevator_memory[259:256] = floor_number;
                8'h41: elevator_memory[263:260] = floor_number;
                8'h42: elevator_memory[267:264] = floor_number;
                8'h43: elevator_memory[271:268] = floor_number;
                8'h44: elevator_memory[275:272] = floor_number;
                8'h45: elevator_memory[279:276] = floor_number;
                8'h46: elevator_memory[283:280] = floor_number;
                8'h47: elevator_memory[287:284] = floor_number;
                8'h48: elevator_memory[291:288] = floor_number;
                8'h49: elevator_memory[295:292] = floor_number;
                8'h4A: elevator_memory[299:296] = floor_number;
                8'h4B: elevator_memory[303:300] = floor_number;
                8'h4C: elevator_memory[307:304] = floor_number;
                8'h4D: elevator_memory[311:308] = floor_number;
                8'h4E: elevator_memory[315:312] = floor_number;
                8'h4F: elevator_memory[319:316] = floor_number;
                8'h50: elevator_memory[323:320] = floor_number;
                8'h51: elevator_memory[327:324] = floor_number;
                8'h52: elevator_memory[331:328] = floor_number;
                8'h53: elevator_memory[335:332] = floor_number;
                8'h54: elevator_memory[339:336] = floor_number;
                8'h55: elevator_memory[343:340] = floor_number;
                8'h56: elevator_memory[347:344] = floor_number;
                8'h57: elevator_memory[351:348] = floor_number;
                8'h58: elevator_memory[355:352] = floor_number;
                8'h59: elevator_memory[359:356] = floor_number;
                8'h5A: elevator_memory[363:360] = floor_number;
                8'h5B: elevator_memory[367:364] = floor_number;
                8'h5C: elevator_memory[371:368] = floor_number;
                8'h5D: elevator_memory[375:372] = floor_number;
                8'h5E: elevator_memory[379:376] = floor_number;
                8'h5F: elevator_memory[383:380] = floor_number;
                8'h60: elevator_memory[387:384] = floor_number;
                8'h61: elevator_memory[391:388] = floor_number;
                8'h62: elevator_memory[395:392] = floor_number;
                8'h63: elevator_memory[399:396] = floor_number;
                8'h64: elevator_memory[403:400] = floor_number;
                8'h65: elevator_memory[407:404] = floor_number;
                8'h66: elevator_memory[411:408] = floor_number;
                8'h67: elevator_memory[415:412] = floor_number;
                8'h68: elevator_memory[419:416] = floor_number;
                8'h69: elevator_memory[423:420] = floor_number;
                8'h6A: elevator_memory[427:424] = floor_number;
                8'h6B: elevator_memory[431:428] = floor_number;
                8'h6C: elevator_memory[435:432] = floor_number;
                8'h6D: elevator_memory[439:436] = floor_number;
                8'h6E: elevator_memory[443:440] = floor_number;
                8'h6F: elevator_memory[447:444] = floor_number;
                8'h70: elevator_memory[451:448] = floor_number;
                8'h71: elevator_memory[455:452] = floor_number;
                8'h72: elevator_memory[459:456] = floor_number;
                8'h73: elevator_memory[463:460] = floor_number;
                8'h74: elevator_memory[467:464] = floor_number;
                8'h75: elevator_memory[471:468] = floor_number;
                8'h76: elevator_memory[475:472] = floor_number;
                8'h77: elevator_memory[479:476] = floor_number;
                8'h78: elevator_memory[483:480] = floor_number;
                8'h79: elevator_memory[487:484] = floor_number;
                8'h7A: elevator_memory[491:488] = floor_number;
                8'h7B: elevator_memory[495:492] = floor_number;
                8'h7C: elevator_memory[499:496] = floor_number;
                8'h7D: elevator_memory[503:500] = floor_number;
                8'h7E: elevator_memory[507:504] = floor_number;
                8'h7F: elevator_memory[511:508] = floor_number;
            endcase
        end
        if (!elevator_moving) begin
            stack_pointer = stack_pointer + 1;
            stack_empty = 1'b0;
            stack_full = (stack_pointer == 4'd10);
            next_floor = current_floor_state;
        end
        if (elevator_moving && |call_button_lights) begin
            remaining_requests = remaining_requests + 1'b1;
            stack_pointer_temporary = stack_pointer;
        end
        if (!elevator_moving && (remaining_requests > 0)) begin
            remaining_requests = remaining_requests - 1'b1;
            stack_pointer = stack_pointer - 1'b1;
    end

    elevator_floor_selector = current_floor_state;
    if (power_switch && () begin
        if (stack_full) begin // Stack was full
            stack_pointer = 4'b0;
            stack_full = 1'b0;
            stack_empty = 1'b1;
            elevator_memory = 512'b0; // Clear the entire stack
        end
        // When elevator reaches target floor, clear the served floor from stack
        if (elevator_floor_selector == current_floor_state && activate_elevator) begin
            if (!stack_empty) begin
                stack_pointer = stack_pointer - 1;
                stack_empty = (stack_pointer == 4'd1);
                stack_full = 1'b0;
                
                // Shift stack down to remove the served floor
                if (stack_pointer > 1) begin
                    elevator_memory = {4'b0, elevator_memory[43:4]}; // Shift right by 4 bits
                end 
                else begin
                    elevator_memory = 44'b0;
                end
            end
        end
    end
end
    
// Floor selection logic - pull from stack and set direction
always @(*) begin
    if (!reset_n) begin
        activate_elevator = 1'b0;
    end 
    activate_elevator = 1'b0;
    if (power_switch && !emergency_btn && !elevator_moving) begin
        activate_elevator = 1'b1;
        if (elevator_floor_selector > current_floor_state) begin
            direction_selector = 1'b1; // Up direction
        end
        else begin
            direction_selector = 1'b0; // Down direction
        end
    end
end

// Door control logic
always @(*) begin
    if (!reset_n) begin
        door_open_allowed <= 1'b0;
        door_close_allowed <= 1'b0;
    end
    
    // Door control only active when elevator is stopped and power is on
    if ((!elevator_moving) && power_switch) begin
        door_open_allowed = door_open_btn;
        door_close_allowed = door_close_btn;
    end
end

endmodule