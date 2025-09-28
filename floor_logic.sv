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
    reg                         [8:0]                           memory_pointer;
    reg                         [8:0]                           memory_pointer_temporary;
    reg                         [15:0]                          remaining_requests;
    reg                         [3:0]                           floor_number;
    reg                         [3:0]                           check_timer;

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
                floor_number = FLOOR_1;
                panel_button_lights[0] = 1'b1;
            end
            panel_buttons[1] && current_floor_state != FLOOR_2 && !panel_button_lights[1]: begin
                floor_number = FLOOR_2;
                panel_button_lights[1] = 1'b1;
            end
            panel_buttons[2] && current_floor_state != FLOOR_3 && !panel_button_lights[2]: begin
                floor_number = FLOOR_3;
                panel_button_lights[2] = 1'b1;
            end
            panel_buttons[3] && current_floor_state != FLOOR_4 && !panel_button_lights[3]: begin
                floor_number = FLOOR_4;
                panel_button_lights[3] = 1'b1;
            end
            panel_buttons[4] && current_floor_state != FLOOR_5 && !panel_button_lights[4]: begin
                floor_number = FLOOR_5;
                panel_button_lights[4] = 1'b1;
            end
            panel_buttons[5] && current_floor_state != FLOOR_6 && !panel_button_lights[5]: begin
                floor_number = FLOOR_6;
                panel_button_lights[5] = 1'b1;
            end
            panel_buttons[6] && current_floor_state != FLOOR_7 && !panel_button_lights[6]: begin
                floor_number = FLOOR_7;
                panel_button_lights[6] = 1'b1;
            end
            panel_buttons[7] && current_floor_state != FLOOR_8 && !panel_button_lights[7]: begin
                floor_number = FLOOR_8;
                panel_button_lights[7] = 1'b1;
            end
            panel_buttons[8] && current_floor_state != FLOOR_9 && !panel_button_lights[8]: begin
                floor_number = FLOOR_9;
                panel_button_lights[8] = 1'b1;
            end
            panel_buttons[9] && current_floor_state != FLOOR_10 && !panel_button_lights[9]: begin
                floor_number = FLOOR_10;
                panel_button_lights[9] = 1'b1;
            end
            panel_buttons[10] && current_floor_state != FLOOR_11 && !panel_button_lights[10]: begin
                floor_number = FLOOR_11;
                panel_button_lights[10] = 1'b1;
            end
        endcase
        // Check floor call buttons (external requests)
        case (1'b1)
            floor_call_buttons[0] && current_floor_state != FLOOR_1 && !call_button_lights[0]: begin
                floor_number = FLOOR_1;
                call_button_lights[0] = 1'b1;
            end
            floor_call_buttons[1] && current_floor_state != FLOOR_2 && !call_button_lights[1]: begin
                floor_number = FLOOR_2;
                call_button_lights[1] = 1'b1;
            end
            floor_call_buttons[2] && current_floor_state != FLOOR_3 && !call_button_lights[2]: begin
                floor_number = FLOOR_3;
                call_button_lights[2] = 1'b1;
            end
            floor_call_buttons[3] && current_floor_state != FLOOR_4 && !call_button_lights[3]: begin
                floor_number = FLOOR_4;
                call_button_lights[3] = 1'b1;
            end
            floor_call_buttons[4] && current_floor_state != FLOOR_5 && !call_button_lights[4]: begin
                floor_number = FLOOR_5;
                call_button_lights[4] = 1'b1;
            end
            floor_call_buttons[5] && current_floor_state != FLOOR_6 && !call_button_lights[5]: begin
                floor_number = FLOOR_6;
                call_button_lights[5] = 1'b1;
            end
            floor_call_buttons[6] && current_floor_state != FLOOR_7 && !call_button_lights[6]: begin
                floor_number = FLOOR_7;
                call_button_lights[6] = 1'b1;
            end
            floor_call_buttons[7] && current_floor_state != FLOOR_8 && !call_button_lights[7]: begin
                floor_number = FLOOR_8;
                call_button_lights[7] = 1'b1;
            end
            floor_call_buttons[8] && current_floor_state != FLOOR_9 && !call_button_lights[8]: begin
                floor_number = FLOOR_9;
                call_button_lights[8] = 1'b1;
            end
            floor_call_buttons[9] && current_floor_state != FLOOR_10 && !call_button_lights[9]: begin
                floor_number = FLOOR_10;
                call_button_lights[9] = 1'b1;
            end
            floor_call_buttons[10] && current_floor_state != FLOOR_11 && !call_button_lights[10]: begin
                floor_number = FLOOR_11;
                call_button_lights[10] = 1'b1;
            end
        endcase
        // Check if elevator arrived at selected floor, clear light
        if (power_switch && !elevator_moving) begin
            case (1'b1)
                (activate_elevator) && current_floor_state == FLOOR_1: begin
                    panel_button_lights[0] = 1'b0;
                    call_button_lights[0] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_2: begin
                    panel_button_lights[1] = 1'b0;
                    call_button_lights[1] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_3: begin
                    panel_button_lights[2] = 1'b0;
                    call_button_lights[2] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_4: begin
                    panel_button_lights[3] = 1'b0;
                    call_button_lights[3] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_5: begin
                    panel_button_lights[4] = 1'b0;
                    call_button_lights[4] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_6: begin
                    panel_button_lights[5] = 1'b0;
                    call_button_lights[5] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_7: begin
                    panel_button_lights[6] = 1'b0;
                    call_button_lights[6] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_8: begin
                    panel_button_lights[7] = 1'b0;
                    call_button_lights[7] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_9: begin
                    panel_button_lights[8] = 1'b0;
                    call_button_lights[8] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_10: begin
                    panel_button_lights[9] = 1'b0;
                    call_button_lights[9] = 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_11: begin
                    panel_button_lights[10] = 1'b0;
                    call_button_lights[10] = 1'b0;
                end
            endcase
        end
    end
end
// OG Stack - Will need work.
always @(*) begin
    if (!reset_n) begin
        memory_pointer <= 4'b0;
        remaining_requests <= 16'b0;
        elevator_floor_selector <= 4'b0;
        next_floor <= 4'b0;
        direction_selector <= 1'b1;
        activate_elevator <= 1'b0;
        check_timer <= 4'b0;
    end
    else begin
        if (!elevator_moving && (elevator_floor_selector == current_floor_state)) begin
            case(direction_selector)
                1'b1: begin
                    if (call_button_lights[0] || panel_button_lights[0]) next_floor = FLOOR_1;
                    if (call_button_lights[1] || panel_button_lights[1]) next_floor = FLOOR_2;
                    if (call_button_lights[2] || panel_button_lights[2]) next_floor = FLOOR_3;
                    if (call_button_lights[3] || panel_button_lights[3]) next_floor = FLOOR_4;
                    if (call_button_lights[4] || panel_button_lights[4]) next_floor = FLOOR_5;
                    if (call_button_lights[5] || panel_button_lights[5]) next_floor = FLOOR_6;
                    if (call_button_lights[6] || panel_button_lights[6]) next_floor = FLOOR_7;
                    if (call_button_lights[7] || panel_button_lights[7]) next_floor = FLOOR_8;
                    if (call_button_lights[8] || panel_button_lights[8]) next_floor = FLOOR_9;
                    if (call_button_lights[9] || panel_button_lights[9]) next_floor = FLOOR_10;
                    if (call_button_lights[10] || panel_button_lights[10]) next_floor = FLOOR_11;
                    if (&call_button_lights && &panel_button_lights) next_floor = current_floor_state;
                end
                1'b0: begin
                    if (call_button_lights[10] || panel_button_lights[10]) next_floor = FLOOR_11;
                    if (call_button_lights[9] || panel_button_lights[9]) next_floor = FLOOR_10;
                    if (call_button_lights[8] || panel_button_lights[8]) next_floor = FLOOR_9;
                    if (call_button_lights[7] || panel_button_lights[7]) next_floor = FLOOR_8;
                    if (call_button_lights[6] || panel_button_lights[6]) next_floor = FLOOR_7;
                    if (call_button_lights[5] || panel_button_lights[5]) next_floor = FLOOR_6;
                    if (call_button_lights[4] || panel_button_lights[4]) next_floor = FLOOR_5;
                    if (call_button_lights[3] || panel_button_lights[3]) next_floor = FLOOR_4;
                    if (call_button_lights[2] || panel_button_lights[2]) next_floor = FLOOR_3;
                    if (call_button_lights[1] || panel_button_lights[1]) next_floor = FLOOR_2;
                    if (call_button_lights[0] || panel_button_lights[0]) next_floor = FLOOR_1;
                    if (&call_button_lights && &panel_button_lights) next_floor = current_floor_state;
                end
            endcase

            elevator_floor_selector = next_floor;
            activate_elevator = 1'b0;
            if ((power_switch && !emergency_btn && !elevator_moving) && elevator_floor_selector != current_floor_state) begin
                activate_elevator = 1'b1;
            end
        end
    end 
end
always @(*) begin
    if (!reset_n) begin
        check_timer = 4'b0;
    end
    else begin
        if (check_timer < 4'd10) begin
            check_timer = check_timer + 1;
        end
        else begin
            check_timer = 4'b0;
            direction_selector = ~direction_selector; // Toggle direction if no requests found after timer expires
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