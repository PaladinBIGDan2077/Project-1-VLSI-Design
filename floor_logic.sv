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
// Button Reader - Register Buffer
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
    end
    else if (power_switch && !emergency_btn) begin  // Remove stack_full condition
        // Check elevator panel buttons (internal requests)
        case (1'b1)
            panel_buttons[0] && current_floor_state != FLOOR_1 && !panel_button_lights[0]: panel_button_lights[0] <= 1'b1;
            panel_buttons[1] && current_floor_state != FLOOR_2 && !panel_button_lights[1]: panel_button_lights[1] <= 1'b1;
            panel_buttons[2] && current_floor_state != FLOOR_3 && !panel_button_lights[2]: panel_button_lights[2] <= 1'b1;
            panel_buttons[3] && current_floor_state != FLOOR_4 && !panel_button_lights[3]: panel_button_lights[3] <= 1'b1;
            panel_buttons[4] && current_floor_state != FLOOR_5 && !panel_button_lights[4]: panel_button_lights[4] <= 1'b1;
            panel_buttons[5] && current_floor_state != FLOOR_6 && !panel_button_lights[5]: panel_button_lights[5] <= 1'b1;
            panel_buttons[6] && current_floor_state != FLOOR_7 && !panel_button_lights[6]: panel_button_lights[6] <= 1'b1;
            panel_buttons[7] && current_floor_state != FLOOR_8 && !panel_button_lights[7]: panel_button_lights[7] <= 1'b1;
            panel_buttons[8] && current_floor_state != FLOOR_9 && !panel_button_lights[8]: panel_button_lights[8] <= 1'b1;
            panel_buttons[9] && current_floor_state != FLOOR_10 && !panel_button_lights[9]: panel_button_lights[9] <= 1'b1;
            panel_buttons[10] && current_floor_state != FLOOR_11 && !panel_button_lights[10]: panel_button_lights[10] <= 1'b1;
        endcase
        // Check floor call buttons (external requests)
        case (1'b1)
            floor_call_buttons[0] && current_floor_state != FLOOR_1 && !call_button_lights[0]: call_button_lights[0] <= 1'b1;
            floor_call_buttons[1] && current_floor_state != FLOOR_2 && !call_button_lights[1]: call_button_lights[1] <= 1'b1;
            floor_call_buttons[2] && current_floor_state != FLOOR_3 && !call_button_lights[2]: call_button_lights[2] <= 1'b1;
            floor_call_buttons[3] && current_floor_state != FLOOR_4 && !call_button_lights[3]: call_button_lights[3] <= 1'b1;
            floor_call_buttons[4] && current_floor_state != FLOOR_5 && !call_button_lights[4]: call_button_lights[4] <= 1'b1;
            floor_call_buttons[5] && current_floor_state != FLOOR_6 && !call_button_lights[5]: call_button_lights[5] <= 1'b1;
            floor_call_buttons[6] && current_floor_state != FLOOR_7 && !call_button_lights[6]: call_button_lights[6] <= 1'b1;
            floor_call_buttons[7] && current_floor_state != FLOOR_8 && !call_button_lights[7]: call_button_lights[7] <= 1'b1;
            floor_call_buttons[8] && current_floor_state != FLOOR_9 && !call_button_lights[8]: call_button_lights[8] <= 1'b1;
            floor_call_buttons[9] && current_floor_state != FLOOR_10 && !call_button_lights[9]: call_button_lights[9] <= 1'b1;
            floor_call_buttons[10] && current_floor_state != FLOOR_11 && !call_button_lights[10]: call_button_lights[10] <= 1'b1;
        endcase
        // Check if elevator arrived at selected floor, clear light
        if (power_switch && !elevator_moving) begin
            case (1'b1)
                (activate_elevator) && current_floor_state == FLOOR_1: begin
                    panel_button_lights[0] <= 1'b0;
                    call_button_lights[0] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_2: begin
                    panel_button_lights[1] <= 1'b0;
                    call_button_lights[1] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_3: begin
                    panel_button_lights[2] <= 1'b0;
                    call_button_lights[2] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_4: begin
                    panel_button_lights[3] <= 1'b0;
                    call_button_lights[3] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_5: begin
                    panel_button_lights[4] <= 1'b0;
                    call_button_lights[4] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_6: begin
                    panel_button_lights[5] <= 1'b0;
                    call_button_lights[5] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_7: begin
                    panel_button_lights[6] <= 1'b0;
                    call_button_lights[6] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_8: begin
                    panel_button_lights[7] <= 1'b0;
                    call_button_lights[7] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_9: begin
                    panel_button_lights[8] <= 1'b0;
                    call_button_lights[8] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_10: begin
                    panel_button_lights[9] <= 1'b0;
                    call_button_lights[9] <= 1'b0;
                end
                (activate_elevator) && current_floor_state == FLOOR_11: begin
                    panel_button_lights[10] <= 1'b0;
                    call_button_lights[10] <= 1'b0;
                end
            endcase
        end
    end
end

always @(*) begin
    if (!reset_n) begin
        elevator_floor_selector <= 4'b0;
        direction_selector <= 1'b1;
        activate_elevator <= 1'b0;
    end
    else begin
        // Reset activation signal
        activate_elevator = 1'b0;
        
        // Only update target floor when elevator is not moving and has reached current target
        if (!elevator_moving && (elevator_floor_selector == current_floor_state)) begin
            // Priority: check for requests in the current direction first
            if (elevator_direction) begin // Moving up
                // Check for requests above current floor
                case (1'b1)
                    (current_floor_state > FLOOR_1) && (call_button_lights[0] || panel_button_lights[0]): elevator_floor_selector = FLOOR_1;
                    (current_floor_state > FLOOR_2) && (call_button_lights[1] || panel_button_lights[1]): elevator_floor_selector = FLOOR_2;
                    (current_floor_state > FLOOR_3) && (call_button_lights[2] || panel_button_lights[2]): elevator_floor_selector = FLOOR_3;
                    (current_floor_state > FLOOR_4) && (call_button_lights[3] || panel_button_lights[3]): elevator_floor_selector = FLOOR_4;
                    (current_floor_state > FLOOR_5) && (call_button_lights[4] || panel_button_lights[4]): elevator_floor_selector = FLOOR_5;
                    (current_floor_state > FLOOR_6) && (call_button_lights[5] || panel_button_lights[5]): elevator_floor_selector = FLOOR_6;
                    (current_floor_state > FLOOR_7) && (call_button_lights[6] || panel_button_lights[6]): elevator_floor_selector = FLOOR_7;
                    (current_floor_state > FLOOR_8) && (call_button_lights[7] || panel_button_lights[7]): elevator_floor_selector = FLOOR_8;
                    (current_floor_state > FLOOR_9) && (call_button_lights[8] || panel_button_lights[8]): elevator_floor_selector = FLOOR_9;
                    (current_floor_state > FLOOR_10) && (call_button_lights[9] || panel_button_lights[9]): elevator_floor_selector = FLOOR_10;
                    (current_floor_state > FLOOR_11) && (call_button_lights[10] || panel_button_lights[10]): elevator_floor_selector = FLOOR_11;
                    default: begin
                        // If no requests above, check for requests below
                        case (1'b1)
                            (call_button_lights[0] || panel_button_lights[0]): elevator_floor_selector = FLOOR_1;
                            (call_button_lights[1] || panel_button_lights[1]): elevator_floor_selector = FLOOR_2;
                            (call_button_lights[2] || panel_button_lights[2]): elevator_floor_selector = FLOOR_3;
                            (call_button_lights[3] || panel_button_lights[3]): elevator_floor_selector = FLOOR_4;
                            (call_button_lights[4] || panel_button_lights[4]): elevator_floor_selector = FLOOR_5;
                            (call_button_lights[5] || panel_button_lights[5]): elevator_floor_selector = FLOOR_6;
                            (call_button_lights[6] || panel_button_lights[6]): elevator_floor_selector = FLOOR_7;
                            (call_button_lights[7] || panel_button_lights[7]): elevator_floor_selector = FLOOR_8;
                            (call_button_lights[8] || panel_button_lights[8]): elevator_floor_selector = FLOOR_9;
                            (call_button_lights[9] || panel_button_lights[9]): elevator_floor_selector = FLOOR_10;
                            (call_button_lights[10] || panel_button_lights[10]): elevator_floor_selector = FLOOR_11;
                            default: elevator_floor_selector = current_floor_state; // No requests
                        endcase
                    end
                endcase
            end
            else begin // Moving down or stationary
                // Check for requests below current floor first
                case (1'b1)
                    (current_floor_state < FLOOR_1) && (call_button_lights[0] || panel_button_lights[0]): elevator_floor_selector = FLOOR_1;
                    (current_floor_state < FLOOR_2) && (call_button_lights[1] || panel_button_lights[1]): elevator_floor_selector = FLOOR_2;
                    (current_floor_state < FLOOR_3) && (call_button_lights[2] || panel_button_lights[2]): elevator_floor_selector = FLOOR_3;
                    (current_floor_state < FLOOR_4) && (call_button_lights[3] || panel_button_lights[3]): elevator_floor_selector = FLOOR_4;
                    (current_floor_state < FLOOR_5) && (call_button_lights[4] || panel_button_lights[4]): elevator_floor_selector = FLOOR_5;
                    (current_floor_state < FLOOR_6) && (call_button_lights[5] || panel_button_lights[5]): elevator_floor_selector = FLOOR_6;
                    (current_floor_state < FLOOR_7) && (call_button_lights[6] || panel_button_lights[6]): elevator_floor_selector = FLOOR_7;
                    (current_floor_state < FLOOR_8) && (call_button_lights[7] || panel_button_lights[7]): elevator_floor_selector = FLOOR_8;
                    (current_floor_state < FLOOR_9) && (call_button_lights[8] || panel_button_lights[8]): elevator_floor_selector = FLOOR_9;
                    (current_floor_state < FLOOR_10) && (call_button_lights[9] || panel_button_lights[9]): elevator_floor_selector = FLOOR_10;
                    (current_floor_state < FLOOR_11) && (call_button_lights[10] || panel_button_lights[10]): elevator_floor_selector = FLOOR_11;
                    default: begin
                        // If no requests below, check for requests above
                        case (1'b1)
                            (call_button_lights[0] || panel_button_lights[0]): elevator_floor_selector = FLOOR_1;
                            (call_button_lights[1] || panel_button_lights[1]): elevator_floor_selector = FLOOR_2;
                            (call_button_lights[2] || panel_button_lights[2]): elevator_floor_selector = FLOOR_3;
                            (call_button_lights[3] || panel_button_lights[3]): elevator_floor_selector = FLOOR_4;
                            (call_button_lights[4] || panel_button_lights[4]): elevator_floor_selector = FLOOR_5;
                            (call_button_lights[5] || panel_button_lights[5]): elevator_floor_selector = FLOOR_6;
                            (call_button_lights[6] || panel_button_lights[6]): elevator_floor_selector = FLOOR_7;
                            (call_button_lights[7] || panel_button_lights[7]): elevator_floor_selector = FLOOR_8;
                            (call_button_lights[8] || panel_button_lights[8]): elevator_floor_selector = FLOOR_9;
                            (call_button_lights[9] || panel_button_lights[9]): elevator_floor_selector = FLOOR_10;
                            (call_button_lights[10] || panel_button_lights[10]): elevator_floor_selector = FLOOR_11;
                            default: elevator_floor_selector = current_floor_state; // No requests
                        endcase
                    end
                endcase
            end
        end
        // Set direction and activation based on target vs current floor
        if ((power_switch && !emergency_btn && !elevator_moving) && (elevator_floor_selector != current_floor_state)) begin
            direction_selector = (elevator_floor_selector > current_floor_state);
            activate_elevator = 1'b1;
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
        door_open_allowed <= door_open_btn;
        door_close_allowed <= door_close_btn;
    end
end

endmodule