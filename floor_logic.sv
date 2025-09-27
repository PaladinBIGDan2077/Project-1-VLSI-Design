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
    input                                   clock;
    input                                   reset_n;
    // Button inputs (active high when pressed)
    input               [10:0]              floor_call_buttons;      // External call buttons (floors 1-11)
    input               [10:0]              panel_buttons;           // Internal destination buttons (floors 1-11)
    input                                   door_open_btn;
    input                                   door_close_btn;
    input                                   emergency_btn;
    input                                   power_switch;                   // Power switch input  
    // Elevator status from FSM
    input               [3:0]               current_floor_state;      // Current floor from FSM (FLOOR_1 to FLOOR_11)
    input               [4:0]               elevator_state;           // Current state from elevator_fsm
    input                                   elevator_moving;                // Derived from FSM state (UP/DOWN states)
    input                                   elevator_direction;             // 1=up, 0=down 
    // Outputs to FSM
    output              [3:0]               elevator_floor_selector;
    output                                  direction_selector;
    output                                  activate_elevator;
    output                                  door_open_allowed;
    output                                  door_close_allowed;
    // Button status outputs (for illumination)
    output              [10:0]              call_button_lights;
    output              [10:0]              panel_button_lights;

    reg                 [3:0]               elevator_floor_selector;
    reg                                     door_open_allowed;
    reg                                     door_close_allowed;
    reg                                     direction_selector;
    reg                                     activate_elevator;
    // Button status outputs (for illumination)
    reg                 [10:0]              call_button_lights;
    reg                 [10:0]              panel_button_lights;
    reg                 [3:0]               next_floor;

    // Internal registers for request management
// Internal registers for stack management
reg                     [43:0]              floor_stack; // 44-bit stack (11 floors × 4 bits each)
reg                     [43:0]              moving_stack; // 44-bit stack (11 floors × 4 bits each)
reg                     [3:0]               stack_pointer; // Points to next available slot (0-10)
reg                     [3:0]               moving_stack_pointer; // Points to next available slot (0-10)
reg                                         stack_full;
reg                                         stack_empty;
reg                     [3:0]               remaining_requests;
reg                     [3:0]               floor_number;


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
                                FLOOR_11                      = 4'hA;
                                


// Emergency handling - clear all requests
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
        floor_stack <= 44'b0;
        stack_pointer <= 4'b0;
        stack_full <= 1'b0;
        stack_empty <= 1'b1;
        elevator_floor_selector <= FLOOR_1; 
        next_floor <= FLOOR_1;
        moving_stack <= 44'b0;
        moving_stack_pointer <= 4'b0;
        remaining_requests <= 4'b0;
        direction_selector <= 1'b1; 
        door_open_allowed <= 1'b0;
        door_close_allowed <= 1'b0;
        activate_elevator <= 1'b0;
        remaining_requests <= 4'b0;
        floor_number <= 4'b0;
    end 
    else if (!power_switch) begin
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
        floor_stack <= 44'b0;
        stack_pointer <= 4'b0;
        stack_full <= 1'b0;
        stack_empty <= 1'b1;
    end
    else if (emergency_btn) begin
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
        stack_pointer <= 44'b0;
        stack_full <= 1'b0;
        floor_stack <= 44'b0;
        stack_pointer <= 4'b0;
        stack_empty <= 1'b1;
        moving_stack <= 44'b0;
        moving_stack_pointer <= 4'b0;
        remaining_requests <= 4'b0;
        direction_selector <= 1'b1; 
        elevator_floor_selector <= EMERGENCY;
    end
end



// Button reader - push floor requests onto stack (FIXED)
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // Stack initialization handled above
    end
    else if (power_switch && !emergency_btn) begin  // Remove stack_full condition
        // Check elevator panel buttons (internal requests)
        case (1'b1)
            panel_buttons[0] && current_floor_state != FLOOR_1 && !panel_button_lights[0]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd0;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd0;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[0] <= 1'b1;
            end
            panel_buttons[1] && current_floor_state != FLOOR_2 && !panel_button_lights[1]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd1;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd1;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[1] <= 1'b1;
            end
            panel_buttons[2] && current_floor_state != FLOOR_3 && !panel_button_lights[2]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd2;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase               
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd2;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[2] <= 1'b1;
            end
            panel_buttons[3] && current_floor_state != FLOOR_4 && !panel_button_lights[3]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd3;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase               
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd3;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[3] <= 1'b1;
            end
            panel_buttons[4] && current_floor_state != FLOOR_5 && !panel_button_lights[4]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd4;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase                
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd4;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[4] <= 1'b1;
            end
            panel_buttons[5] && current_floor_state != FLOOR_6 && !panel_button_lights[5]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd5;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase                
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd5;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[5] <= 1'b1;
            end
            panel_buttons[6] && current_floor_state != FLOOR_7 && !panel_button_lights[6]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd6;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd6;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[6] <= 1'b1;
            end
            panel_buttons[7] && current_floor_state != FLOOR_8 && !panel_button_lights[7]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd7;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd7;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[7] <= 1'b1;
            end
            panel_buttons[8] && current_floor_state != FLOOR_9 && !panel_button_lights[8]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd8;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd8;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[8] <= 1'b1;
            end
            panel_buttons[9] && current_floor_state != FLOOR_10 && !panel_button_lights[9]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd9;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd9;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[9] <= 1'b1;
            end
            panel_buttons[10] && current_floor_state != FLOOR_11 && !panel_button_lights[10]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd10;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                    moving_stack_pointer = moving_stack_pointer + 1;
                    remaining_requests = remaining_requests + 1;
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd10;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                panel_button_lights[10] <= 1'b1;
            end
        endcase

        // Check floor call buttons (external requests)
        case (1'b1)
            floor_call_buttons[0] && current_floor_state != FLOOR_1 && !call_button_lights[0]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd0;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd0;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[0] <= 1'b1;
            end
            floor_call_buttons[1] && current_floor_state != FLOOR_2 && !call_button_lights[1]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd1;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd1;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[1] <= 1'b1;
            end
            floor_call_buttons[2] && current_floor_state != FLOOR_3 && !call_button_lights[2]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd2;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd2;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[2] <= 1'b1;
            end
            floor_call_buttons[3] && current_floor_state != FLOOR_4 && !call_button_lights[3]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd3;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd3;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[3] <= 1'b1;
            end
            floor_call_buttons[4] && current_floor_state != FLOOR_5 && !call_button_lights[4]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd4;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd4;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[4] <= 1'b1;
            end
            floor_call_buttons[5] && current_floor_state != FLOOR_6 && !call_button_lights[5]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd5;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd5;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[5] <= 1'b1;
            end
            floor_call_buttons[6] && current_floor_state != FLOOR_7 && !call_button_lights[6]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd6;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd6;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[6] <= 1'b1;
            end
            floor_call_buttons[7] && current_floor_state != FLOOR_8 && !call_button_lights[7]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd7;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd7;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[7] <= 1'b1;
            end
            floor_call_buttons[8] && current_floor_state != FLOOR_9 && !call_button_lights[8]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd8;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd8;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[8] <= 1'b1;
            end
            floor_call_buttons[9] && current_floor_state != FLOOR_10 && !call_button_lights[9]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd9;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd9;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[9] <= 1'b1;
            end
            floor_call_buttons[10] && current_floor_state != FLOOR_11 && !call_button_lights[10]: begin
                if (elevator_moving) begin
                    // If elevator is moving, push to moving stack instead
                    floor_number = 4'd10;
                    case (moving_stack_pointer)
                        4'd0: moving_stack[3:0] = floor_number;
                        4'd1: moving_stack[7:4] = floor_number;
                        4'd2: moving_stack[11:8] = floor_number;
                        4'd3: moving_stack[15:12] = floor_number;
                        4'd4: moving_stack[19:16] = floor_number;
                        4'd5: moving_stack[23:20] = floor_number;
                        4'd6: moving_stack[27:24] = floor_number;
                        4'd7: moving_stack[31:28] = floor_number;
                        4'd8: moving_stack[35:32] = floor_number;
                        4'd9: moving_stack[39:36] = floor_number;
                        4'd10: moving_stack[43:40] = floor_number;
                    endcase
                end
                else begin
                    // If elevator is stopped, push to main stack
                    floor_number = 4'd10;
                    if (!stack_full) begin
                        case (stack_pointer)
                            4'd0: floor_stack[3:0] = floor_number;
                            4'd1: floor_stack[7:4] = floor_number;
                            4'd2: floor_stack[11:8] = floor_number;
                            4'd3: floor_stack[15:12] = floor_number;
                            4'd4: floor_stack[19:16] = floor_number;
                            4'd5: floor_stack[23:20] = floor_number;
                            4'd6: floor_stack[27:24] = floor_number;
                            4'd7: floor_stack[31:28] = floor_number;
                            4'd8: floor_stack[35:32] = floor_number;
                            4'd9: floor_stack[39:36] = floor_number;
                            4'd10: floor_stack[43:40] = floor_number;
                        endcase
                        stack_pointer = stack_pointer + 1;
                        stack_empty = 1'b0;
                        stack_full = (stack_pointer == 4'd10);
                    end
                end
                call_button_lights[10] <= 1'b1;
            end
        endcase
    end
end
// Button reader - clear floor lights when served
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // Stack initialization handled above
    end
    else if (power_switch && !stack_full) begin
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


    
// Floor selection logic - pull from stack and set direction
always @(*) begin
    activate_elevator = 1'b0;
    
    if (power_switch && !emergency_btn) begin

        if (!stack_empty) begin
            // Get next floor from stack WITHOUT popping (just read)
            // 
            if (remaining_requests >= 1) begin
                // If multiple requests, prioritize based on current direction
                if (((elevator_state == STOP_FL1) || (elevator_state == STOP_FL2) || (elevator_state == STOP_FL3) || (elevator_state == STOP_FL4) || (elevator_state == STOP_FL5) || (elevator_state == STOP_FL6) || (elevator_state == STOP_FL7) || (elevator_state == STOP_FL8) || (elevator_state == STOP_FL9) || (elevator_state == STOP_FL10) || (elevator_state == STOP_FL11))) begin
                    case (moving_stack_pointer)
                        4'd1: next_floor = moving_stack[3:0];
                        4'd2: next_floor = moving_stack[7:4];
                        4'd3: next_floor = moving_stack[11:8];
                        4'd4: next_floor = moving_stack[15:12];
                        4'd5: next_floor = moving_stack[19:16];
                        4'd6: next_floor = moving_stack[23:20];
                        4'd7: next_floor = moving_stack[27:24];
                        4'd8: next_floor = moving_stack[31:28];
                        4'd9: next_floor = moving_stack[35:32];
                        4'd10: next_floor = moving_stack[39:36];
                        4'd11: next_floor = moving_stack[43:40];
                        default: next_floor = current_floor_state;
                    endcase
                    elevator_floor_selector = next_floor;
                    if (current_floor_state == next_floor) begin
                        moving_stack_pointer = moving_stack_pointer - 1;
                        floor_stack <= 44'b0; // Clear the entire stack
                        remaining_requests = remaining_requests - 1;
                    end
                end
                else begin
                    elevator_floor_selector = next_floor;
                end
            end
            else if (((elevator_state == STOP_FL1) || (elevator_state == STOP_FL2) || (elevator_state == STOP_FL3) || (elevator_state == STOP_FL4) || (elevator_state == STOP_FL5) || (elevator_state == STOP_FL6) || (elevator_state == STOP_FL7) || (elevator_state == STOP_FL8) || (elevator_state == STOP_FL9) || (elevator_state == STOP_FL10) || (elevator_state == STOP_FL11))) begin
                case (stack_pointer)
                    4'd1: next_floor = floor_stack[3:0];
                    4'd2: next_floor = floor_stack[7:4];
                    4'd3: next_floor = floor_stack[11:8];
                    4'd4: next_floor = floor_stack[15:12];
                    4'd5: next_floor = floor_stack[19:16];
                    4'd6: next_floor = floor_stack[23:20];
                    4'd7: next_floor = floor_stack[27:24];
                    4'd8: next_floor = floor_stack[31:28];
                    4'd9: next_floor = floor_stack[35:32];
                    4'd10: next_floor = floor_stack[39:36];
                    4'd11: next_floor = floor_stack[43:40];
                    default: next_floor = current_floor_state;
                endcase
                elevator_floor_selector = next_floor;
            end
            else begin
                elevator_floor_selector = next_floor; // No change if stack empty
            end
        end
        // Only activate if it's a different floor AND we're in a stop state
        if ((elevator_floor_selector != current_floor_state) && ((elevator_state == STOP_FL1) || (elevator_state == STOP_FL2) || (elevator_state == STOP_FL3) || (elevator_state == STOP_FL4) || (elevator_state == STOP_FL5) || (elevator_state == STOP_FL6) || (elevator_state == STOP_FL7) || (elevator_state == STOP_FL8) || (elevator_state == STOP_FL9) || (elevator_state == STOP_FL10) || (elevator_state == STOP_FL11))) begin
            activate_elevator = 1'b1;
            
            // Natural direction selection
            if (elevator_floor_selector > current_floor_state) begin
                direction_selector = 1'b1; // Up direction
            end
            else begin
                direction_selector = 1'b0; // Down direction
            end
        end
    end
end


// Clear floor request when elevator arrives - reset stack pointer when full
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // Handled in main reset
    end
    else if (power_switch && ((elevator_state == STOP_FL1) || (elevator_state == STOP_FL2) || (elevator_state == STOP_FL3) || (elevator_state == STOP_FL4) || (elevator_state == STOP_FL5) || (elevator_state == STOP_FL6) || (elevator_state == STOP_FL7) || (elevator_state == STOP_FL8) || (elevator_state == STOP_FL9) || (elevator_state == STOP_FL10) || (elevator_state == STOP_FL11))) begin
        if (stack_full) begin // Stack was full
            stack_pointer <= 4'b0;
            stack_full <= 1'b0;
            stack_empty <= 1'b1;
            floor_stack <= 44'b0; // Clear the entire stack
        end
        // When elevator reaches target floor, clear the served floor from stack
        if (elevator_floor_selector == current_floor_state && activate_elevator) begin
            if (!stack_empty) begin
                stack_pointer <= stack_pointer - 1;
                stack_empty <= (stack_pointer == 4'd1);
                stack_full <= 1'b0;
                
                // Shift stack down to remove the served floor
                if (stack_pointer > 1) begin
                    floor_stack <= {4'b0, floor_stack[43:4]}; // Shift right by 4 bits
                end else begin
                    floor_stack <= 44'b0;
                end
            end
            
            // Turn off button lights for current floor
            call_button_lights[current_floor_state] <= 1'b0;
            panel_button_lights[current_floor_state] <= 1'b0;
        end
    end
end


// Door control logic
always @(*) begin
    door_open_allowed = 1'b0;
    door_close_allowed = 1'b0;
    
    // Door control only active when elevator is stopped and power is on
    if (((elevator_state == STOP_FL1) || (elevator_state == STOP_FL2) || (elevator_state == STOP_FL3) || (elevator_state == STOP_FL4) || (elevator_state == STOP_FL5) || (elevator_state == STOP_FL6) || (elevator_state == STOP_FL7) || (elevator_state == STOP_FL8) || (elevator_state == STOP_FL9) || (elevator_state == STOP_FL10) || (elevator_state == STOP_FL11)) && power_switch) begin
        door_open_allowed = door_open_btn;
        door_close_allowed = door_close_btn;
    end
end



endmodule