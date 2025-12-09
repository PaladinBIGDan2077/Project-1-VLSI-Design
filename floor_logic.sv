/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator Floor Logic Controller
// Filename:                        floor_logic.sv
// Version:                         10
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
//                                  9/20/2025   DJL  7        Fixed minor bugs and improved comments
//                                  9/25/2025   DJL  8        Further review and cleanup
//                                  9/27/2025   DJL  9        Converted to fully hardware synthesizable logic
//                                  9/28/2025   DJL  10       Final submission for Project 2
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
    else if (power_switch && !emergency_btn) begin
        if (panel_buttons[0] && current_floor_state != FLOOR_1 && !panel_button_lights[0]) begin
            panel_button_lights[0] <= 1'b1;
        end else if (panel_buttons[1] && current_floor_state != FLOOR_2 && !panel_button_lights[1]) begin
            panel_button_lights[1] <= 1'b1;
        end else if (panel_buttons[2] && current_floor_state != FLOOR_3 && !panel_button_lights[2]) begin
            panel_button_lights[2] <= 1'b1;
        end else if (panel_buttons[3] && current_floor_state != FLOOR_4 && !panel_button_lights[3]) begin
            panel_button_lights[3] <= 1'b1;
        end else if (panel_buttons[4] && current_floor_state != FLOOR_5 && !panel_button_lights[4]) begin
            panel_button_lights[4] <= 1'b1;
        end else if (panel_buttons[5] && current_floor_state != FLOOR_6 && !panel_button_lights[5]) begin
            panel_button_lights[5] <= 1'b1;
        end else if (panel_buttons[6] && current_floor_state != FLOOR_7 && !panel_button_lights[6]) begin
            panel_button_lights[6] <= 1'b1;
        end else if (panel_buttons[7] && current_floor_state != FLOOR_8 && !panel_button_lights[7]) begin
            panel_button_lights[7] <= 1'b1;
        end else if (panel_buttons[8] && current_floor_state != FLOOR_9 && !panel_button_lights[8]) begin
            panel_button_lights[8] <= 1'b1;
        end else if (panel_buttons[9] && current_floor_state != FLOOR_10 && !panel_button_lights[9]) begin
            panel_button_lights[9] <= 1'b1;
        end else if (panel_buttons[10] && current_floor_state != FLOOR_11 && !panel_button_lights[10]) begin
            panel_button_lights[10] <= 1'b1;
        end
        if (floor_call_buttons[0] && current_floor_state != FLOOR_1 && !call_button_lights[0]) begin
            call_button_lights[0] <= 1'b1;
        end else if (floor_call_buttons[1] && current_floor_state != FLOOR_2 && !call_button_lights[1]) begin
            call_button_lights[1] <= 1'b1;
        end else if (floor_call_buttons[2] && current_floor_state != FLOOR_3 && !call_button_lights[2]) begin
            call_button_lights[2] <= 1'b1;
        end else if (floor_call_buttons[3] && current_floor_state != FLOOR_4 && !call_button_lights[3]) begin
            call_button_lights[3] <= 1'b1;
        end else if (floor_call_buttons[4] && current_floor_state != FLOOR_5 && !call_button_lights[4]) begin
            call_button_lights[4] <= 1'b1;
        end else if (floor_call_buttons[5] && current_floor_state != FLOOR_6 && !call_button_lights[5]) begin
            call_button_lights[5] <= 1'b1;
        end else if (floor_call_buttons[6] && current_floor_state != FLOOR_7 && !call_button_lights[6]) begin
            call_button_lights[6] <= 1'b1;
        end else if (floor_call_buttons[7] && current_floor_state != FLOOR_8 && !call_button_lights[7]) begin
            call_button_lights[7] <= 1'b1;
        end else if (floor_call_buttons[8] && current_floor_state != FLOOR_9 && !call_button_lights[8]) begin
            call_button_lights[8] <= 1'b1;
        end else if (floor_call_buttons[9] && current_floor_state != FLOOR_10 && !call_button_lights[9]) begin
            call_button_lights[9] <= 1'b1;
        end else if (floor_call_buttons[10] && current_floor_state != FLOOR_11 && !call_button_lights[10]) begin
            call_button_lights[10] <= 1'b1;
        end
        if (power_switch && !elevator_moving) begin
            if ((activate_elevator) && current_floor_state == FLOOR_1) begin
                panel_button_lights[0] <= 1'b0;
                call_button_lights[0] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_2) begin
                panel_button_lights[1] <= 1'b0;
                call_button_lights[1] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_3) begin
                panel_button_lights[2] <= 1'b0;
                call_button_lights[2] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_4) begin
                panel_button_lights[3] <= 1'b0;
                call_button_lights[3] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_5) begin
                panel_button_lights[4] <= 1'b0;
                call_button_lights[4] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_6) begin
                panel_button_lights[5] <= 1'b0;
                call_button_lights[5] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_7) begin
                panel_button_lights[6] <= 1'b0;
                call_button_lights[6] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_8) begin
                panel_button_lights[7] <= 1'b0;
                call_button_lights[7] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_9) begin
                panel_button_lights[8] <= 1'b0;
                call_button_lights[8] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_10) begin
                panel_button_lights[9] <= 1'b0;
                call_button_lights[9] <= 1'b0;
            end else if ((activate_elevator) && current_floor_state == FLOOR_11) begin
                panel_button_lights[10] <= 1'b0;
                call_button_lights[10] <= 1'b0;
            end
        end
    end
end
// Elevator Floor Selection Logic
always @(*) begin
    if (!reset_n) begin
        elevator_floor_selector = 4'b0;
    end
    else if (!elevator_moving && (elevator_floor_selector == current_floor_state)) begin
        if (elevator_direction) begin 
            // Check requests ABOVE current floor (Priority: Highest floor first)
            if ((current_floor_state < FLOOR_11) && (call_button_lights[10] || panel_button_lights[10])) begin
                elevator_floor_selector = FLOOR_11;
            end else if ((current_floor_state < FLOOR_10) && (call_button_lights[9] || panel_button_lights[9])) begin
                elevator_floor_selector = FLOOR_10;
            end else if ((current_floor_state < FLOOR_9) && (call_button_lights[8] || panel_button_lights[8])) begin
                elevator_floor_selector = FLOOR_9;
            end else if ((current_floor_state < FLOOR_8) && (call_button_lights[7] || panel_button_lights[7])) begin
                elevator_floor_selector = FLOOR_8;
            end else if ((current_floor_state < FLOOR_7) && (call_button_lights[6] || panel_button_lights[6])) begin
                elevator_floor_selector = FLOOR_7;
            end else if ((current_floor_state < FLOOR_6) && (call_button_lights[5] || panel_button_lights[5])) begin
                elevator_floor_selector = FLOOR_6;
            end else if ((current_floor_state < FLOOR_5) && (call_button_lights[4] || panel_button_lights[4])) begin
                elevator_floor_selector = FLOOR_5;
            end else if ((current_floor_state < FLOOR_4) && (call_button_lights[3] || panel_button_lights[3])) begin
                elevator_floor_selector = FLOOR_4;
            end else if ((current_floor_state < FLOOR_3) && (call_button_lights[2] || panel_button_lights[2])) begin
                elevator_floor_selector = FLOOR_3;
            end else if ((current_floor_state < FLOOR_2) && (call_button_lights[1] || panel_button_lights[1])) begin
                elevator_floor_selector = FLOOR_2;
            end else if ((current_floor_state < FLOOR_1) && (call_button_lights[0] || panel_button_lights[0])) begin
                elevator_floor_selector = FLOOR_1;
            // If no requests above, check requests BELOW (Priority: Highest floor first, reverse travel)
            end else if ((current_floor_state > FLOOR_11) && (call_button_lights[10] || panel_button_lights[10])) begin
                elevator_floor_selector = FLOOR_11;
            end else if ((current_floor_state > FLOOR_10) && (call_button_lights[9] || panel_button_lights[9])) begin
                elevator_floor_selector = FLOOR_10;
            end else if ((current_floor_state > FLOOR_9) && (call_button_lights[8] || panel_button_lights[8])) begin
                elevator_floor_selector = FLOOR_9;
            end else if ((current_floor_state > FLOOR_8) && (call_button_lights[7] || panel_button_lights[7])) begin
                elevator_floor_selector = FLOOR_8;
            end else if ((current_floor_state > FLOOR_7) && (call_button_lights[6] || panel_button_lights[6])) begin
                elevator_floor_selector = FLOOR_7;
            end else if ((current_floor_state > FLOOR_6) && (call_button_lights[5] || panel_button_lights[5])) begin
                elevator_floor_selector = FLOOR_6;
            end else if ((current_floor_state > FLOOR_5) && (call_button_lights[4] || panel_button_lights[4])) begin
                elevator_floor_selector = FLOOR_5;
            end else if ((current_floor_state > FLOOR_4) && (call_button_lights[3] || panel_button_lights[3])) begin
                elevator_floor_selector = FLOOR_4;
            end else if ((current_floor_state > FLOOR_3) && (call_button_lights[2] || panel_button_lights[2])) begin
                elevator_floor_selector = FLOOR_3;
            end else if ((current_floor_state > FLOOR_2) && (call_button_lights[1] || panel_button_lights[1])) begin
                elevator_floor_selector = FLOOR_2;
            end else if ((current_floor_state > FLOOR_1) && (call_button_lights[0] || panel_button_lights[0])) begin
                elevator_floor_selector = FLOOR_1;
            end
        end else begin // !elevator_direction (Moving Down or Idle)
            // Check requests BELOW current floor (Priority: Lowest floor first)
            if ((current_floor_state > FLOOR_1) && (call_button_lights[0] || panel_button_lights[0])) begin
                elevator_floor_selector = FLOOR_1;
            end else if ((current_floor_state > FLOOR_2) && (call_button_lights[1] || panel_button_lights[1])) begin
                elevator_floor_selector = FLOOR_2;
            end else if ((current_floor_state > FLOOR_3) && (call_button_lights[2] || panel_button_lights[2])) begin
                elevator_floor_selector = FLOOR_3;
            end else if ((current_floor_state > FLOOR_4) && (call_button_lights[3] || panel_button_lights[3])) begin
                elevator_floor_selector = FLOOR_4;
            end else if ((current_floor_state > FLOOR_5) && (call_button_lights[4] || panel_button_lights[4])) begin
                elevator_floor_selector = FLOOR_5;
            end else if ((current_floor_state > FLOOR_6) && (call_button_lights[5] || panel_button_lights[5])) begin
                elevator_floor_selector = FLOOR_6;
            end else if ((current_floor_state > FLOOR_7) && (call_button_lights[6] || panel_button_lights[6])) begin
                elevator_floor_selector = FLOOR_7;
            end else if ((current_floor_state > FLOOR_8) && (call_button_lights[7] || panel_button_lights[7])) begin
                elevator_floor_selector = FLOOR_8;
            end else if ((current_floor_state > FLOOR_9) && (call_button_lights[8] || panel_button_lights[8])) begin
                elevator_floor_selector = FLOOR_9;
            end else if ((current_floor_state > FLOOR_10) && (call_button_lights[9] || panel_button_lights[9])) begin
                elevator_floor_selector = FLOOR_10;
            end else if ((current_floor_state > FLOOR_11) && (call_button_lights[10] || panel_button_lights[10])) begin
                elevator_floor_selector = FLOOR_11;
            // If no requests below, check requests ABOVE (Priority: Lowest floor first, reverse travel)
            end else if ((current_floor_state < FLOOR_1) && (call_button_lights[0] || panel_button_lights[0])) begin
                elevator_floor_selector = FLOOR_1;
            end else if ((current_floor_state < FLOOR_2) && (call_button_lights[1] || panel_button_lights[1])) begin
                elevator_floor_selector = FLOOR_2;
            end else if ((current_floor_state < FLOOR_3) && (call_button_lights[2] || panel_button_lights[2])) begin
                elevator_floor_selector = FLOOR_3;
            end else if ((current_floor_state < FLOOR_4) && (call_button_lights[3] || panel_button_lights[3])) begin
                elevator_floor_selector = FLOOR_4;
            end else if ((current_floor_state < FLOOR_5) && (call_button_lights[4] || panel_button_lights[4])) begin
                elevator_floor_selector = FLOOR_5;
            end else if ((current_floor_state < FLOOR_6) && (call_button_lights[5] || panel_button_lights[5])) begin
                elevator_floor_selector = FLOOR_6;
            end else if ((current_floor_state < FLOOR_7) && (call_button_lights[6] || panel_button_lights[6])) begin
                elevator_floor_selector = FLOOR_7;
            end else if ((current_floor_state < FLOOR_8) && (call_button_lights[7] || panel_button_lights[7])) begin
                elevator_floor_selector = FLOOR_8;
            end else if ((current_floor_state < FLOOR_9) && (call_button_lights[8] || panel_button_lights[8])) begin
                elevator_floor_selector = FLOOR_9;
            end else if ((current_floor_state < FLOOR_10) && (call_button_lights[9] || panel_button_lights[9])) begin
                elevator_floor_selector = FLOOR_10;
            end else if ((current_floor_state < FLOOR_11) && (call_button_lights[10] || panel_button_lights[10])) begin
                elevator_floor_selector = FLOOR_11;
            end
        end
    end
end

always @(*) begin
    if (!reset_n) begin
        direction_selector = 1'b1; // Default to up
        activate_elevator = 1'b0;
    end
    else if (power_switch && !emergency_btn && !elevator_moving) begin
        if (elevator_floor_selector > current_floor_state) begin
            direction_selector = 1'b1; // Up
            if (elevator_floor_selector != current_floor_state)
                activate_elevator = 1'b1;
            else
                activate_elevator = 1'b0;
        end
        else if (elevator_floor_selector < current_floor_state) begin
            direction_selector = 1'b0; // Down
            if (elevator_floor_selector != current_floor_state)
                activate_elevator = 1'b1;
            else
                activate_elevator = 1'b0;
        end
        else begin
            activate_elevator = 1'b0; // No movement needed
        end
    end
    else begin
        activate_elevator = 1'b0; // Power off or emergency, do not activate
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