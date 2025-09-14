/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator Floor Logic Controller
// Filename:                        floor_logic.v
// Version:                         4
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/7/2025 
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Doctor Jeffrey Walling 
//  
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)  
// Simulation Tool:                 ModelSim: Intel FPGA Starter Edition 21.1 
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
    input               [5:0]               elevator_state;           // Current state from elevator_fsm
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
    reg                                     direction_selector;
    reg                                     activate_elevator;
    // Button status outputs (for illumination)
    reg                 [10:0]              call_button_lights;
    reg                 [10:0]              panel_button_lights;

    // Internal registers for request management
    reg                 [10:0]              up_requests;       // External calls for upward direction
    reg                 [10:0]              down_requests;     // External calls for downward direction  
    reg                 [10:0]              panel_requests;    // Internal destination requests
    reg                                     door_open_allowed;
    reg                                     door_close_allowed;
    // Internal Variables
    integer                                 i;

    parameter                   STOP_FL1                      = 6'h00,      
                                STOP_FL2                      = 6'h01,      
                                STOP_FL3                      = 6'h02,     
                                STOP_FL4                      = 6'h03,
                                STOP_FL5                      = 6'h04,
                                STOP_FL6                      = 6'h05,
                                STOP_FL7                      = 6'h06, 
                                STOP_FL8                      = 6'h07,
                                STOP_FL9                      = 6'h08,      
                                STOP_FL10                     = 6'h09,
                                STOP_FL11                     = 6'h0A, 
                                UP_F1_F2                      = 6'h0B,
                                UP_F2_F3                      = 6'h0C,
                                UP_F3_F4                      = 6'h0D,
                                UP_F4_F5                      = 6'h0E,
                                UP_F5_F6                      = 6'h0F,
                                UP_F6_F7                      = 6'h10,
                                UP_F7_F8                      = 6'h11,
                                UP_F8_F9                      = 6'h12,
                                UP_F9_F10                     = 6'h13,
                                UP_F10_F11                    = 6'h14,
                                DOWN_F11_F10                  = 6'h15,
                                DOWN_F10_F9                   = 6'h16,
                                DOWN_F9_F8                    = 6'h17,
                                DOWN_F8_F7                    = 6'h18,
                                DOWN_F7_F6                    = 6'h19,
                                DOWN_F6_F5                    = 6'h1A,
                                DOWN_F5_F4                    = 6'h1B,
                                DOWN_F4_F3                    = 6'h1C,
                                DOWN_F3_F2                    = 6'h1D,
                                DOWN_F2_F1                    = 6'h1E,
                                EMERGENCY                     = 6'h1F;
    
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
	

// Function to check if state is a STOP state
function is_stop_state;
    input [5:0] state;
    begin
        is_stop_state = (state == STOP_FL1) || (state == STOP_FL2) || 
                        (state == STOP_FL3) || (state == STOP_FL4) || 
                        (state == STOP_FL5) || (state == STOP_FL6) || 
                        (state == STOP_FL7) || (state == STOP_FL8) || 
                        (state == STOP_FL9) || (state == STOP_FL10) || 
                        (state == STOP_FL11);
    end
endfunction

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        up_requests <= 11'b0;
        down_requests <= 11'b0;
        panel_requests <= 11'b0;
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
    end
    else if (power_switch) begin
        // Normal operation - process buttons (manual unrolling of for loops)
        // Floor 1
        if (floor_call_buttons[0]) begin
            if (0 > current_floor_state) begin
                up_requests[0] <= 1'b1;
            end 
            else if (0 < current_floor_state) begin
                down_requests[0] <= 1'b1;
            end
            call_button_lights[0] <= 1'b1;
        end
        // Floor 2
        if (floor_call_buttons[1]) begin
            if (1 >current_floor_state) begin
                up_requests[1] <= 1'b1;
            end 
            else if (1 < current_floor_state) begin
                down_requests[1] <= 1'b1;
            end
            call_button_lights[1] <= 1'b1;
        end
        // Floor 3
        if (floor_call_buttons[2]) begin
            if (2 > current_floor_state) begin
                up_requests[2] <= 1'b1;
            end 
            else if (2 < current_floor_state) begin
                down_requests[2] <= 1'b1;
            end
            call_button_lights[2] <= 1'b1;
        end
        // Floor 4
        if (floor_call_buttons[3]) begin
            if (3 > current_floor_state) begin
                up_requests[3] <= 1'b1;
            end 
            else if (3 < current_floor_state) begin
                down_requests[3] <= 1'b1;
            end
            call_button_lights[3] <= 1'b1;
        end
        // Floor 5
        if (floor_call_buttons[4]) begin
            if (4 > current_floor_state) begin
                up_requests[4] <= 1'b1;
            end 
            else if (4 < current_floor_state) begin
                down_requests[4] <= 1'b1;
            end
            call_button_lights[4] <= 1'b1;
        end
        // Floor 6
        if (floor_call_buttons[5]) begin
            if (5 > current_floor_state) begin
                up_requests[5] <= 1'b1;
            end 
            else if (5 < current_floor_state) begin
                down_requests[5] <= 1'b1;
            end
            call_button_lights[5] <= 1'b1;
        end
        // Floor 7
        if (floor_call_buttons[6]) begin
            if (6 > current_floor_state) begin
                up_requests[6] <= 1'b1;
            end 
            else if (6 < current_floor_state) begin
                down_requests[6] <= 1'b1;
            end
            call_button_lights[6] <= 1'b1;
        end
        // Floor 8
        if (floor_call_buttons[7]) begin
            if (7 > current_floor_state) begin
                up_requests[7] <= 1'b1;
            end 
            else if (7 < current_floor_state) begin
                down_requests[7] <= 1'b1;
            end
            call_button_lights[7] <= 1'b1;
        end
        // Floor 9
        if (floor_call_buttons[8]) begin
            if (8 > current_floor_state) begin
                up_requests[8] <= 1'b1;
            end 
            else if (8 < current_floor_state) begin
                down_requests[8] <= 1'b1;
            end
            call_button_lights[8] <= 1'b1;
        end
        // Floor 10
        if (floor_call_buttons[9]) begin
            if (9 > current_floor_state) begin
                up_requests[9] <= 1'b1;
            end 
            else if (9 < current_floor_state) begin
                down_requests[9] <= 1'b1;
            end
            call_button_lights[9] <= 1'b1;
        end
        // Floor 11
        if (floor_call_buttons[10]) begin
            if (10 > current_floor_state) begin
                up_requests[10] <= 1'b1;
            end 
            else if (10 < current_floor_state) begin
                down_requests[10] <= 1'b1;
            end
            call_button_lights[10] <= 1'b1;
        end
        // Panel buttons (similarly unrolled)
        if (panel_buttons[0]) begin
            panel_requests[0] <= 1'b1;
            panel_button_lights[0] <= 1'b1;
        end
        if (panel_buttons[1]) begin
            panel_requests[1] <= 1'b1;
            panel_button_lights[1] <= 1'b1;
        end
        if (panel_buttons[2]) begin
            panel_requests[2] <= 1'b1;
            panel_button_lights[2] <= 1'b1;
        end
        if (panel_buttons[3]) begin
            panel_requests[3] <= 1'b1;
            panel_button_lights[3] <= 1'b1;
        end
        if (panel_buttons[4]) begin
            panel_requests[4] <= 1'b1;
            panel_button_lights[4] <= 1'b1;
        end
        if (panel_buttons[5]) begin
            panel_requests[5] <= 1'b1;
            panel_button_lights[5] <= 1'b1;
        end
        if (panel_buttons[6]) begin
            panel_requests[6] <= 1'b1;
            panel_button_lights[6] <= 1'b1;
        end
        if (panel_buttons[7]) begin
            panel_requests[7] <= 1'b1;
            panel_button_lights[7] <= 1'b1;
        end
        if (panel_buttons[8]) begin
            panel_requests[8] <= 1'b1;
            panel_button_lights[8] <= 1'b1;
        end
        if (panel_buttons[9]) begin
            panel_requests[9] <= 1'b1;
            panel_button_lights[9] <= 1'b1;
        end
        if (panel_buttons[10]) begin
            panel_requests[10] <= 1'b1;
            panel_button_lights[10] <= 1'b1;
        end
    end
end

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // Keep existing reset
    end 
    else if (power_switch) begin
        if (elevator_floor_selector == current_floor_state) begin
            up_requests[current_floor_state] <= 1'b0;
            down_requests[current_floor_state] <= 1'b0;
            panel_requests[current_floor_state] <= 1'b0;
            call_button_lights[current_floor_state] <= 1'b0;
            panel_button_lights[current_floor_state] <= 1'b0;
            activate_elevator = 1'b0;
        end
    end
end

// Target floor selection logic
always @(*) begin
    activate_elevator = 1'b0;
    // elevator_floor_selector = current_floor_state;
   // direction_selector = elevator_direction;    
    // Normal operation when power is on and no emergency
    if (power_switch && !emergency_btn) begin
        // Only process requests when elevator is stopped
        if (is_stop_state(elevator_state)) begin
            // Check if there are any pending requests
            if (|panel_requests || |up_requests || |down_requests) begin
                activate_elevator = 1'b1;
                // Priority 1: Panel requests
                if (|panel_requests) begin
                    // Panel request logic
                    if (elevator_direction) begin
                        for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                            if (panel_requests[i]) begin
                                elevator_floor_selector = i;
                                direction_selector = 1'b1;
                                break;
                            end
                        end
                        if (i == 11) begin
                            for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                                if (panel_requests[i]) begin
                                    elevator_floor_selector = i;
                                    direction_selector = 1'b0;
                                    break;
                                end
                            end
                        end
                    end 
                    else begin
                        for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                            if (panel_requests[i]) begin
                                elevator_floor_selector = i;
                                direction_selector = 1'b0;
                                break;
                            end
                        end
                        if (i == -1) begin
                            for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                                if (panel_requests[i]) begin
                                    elevator_floor_selector = i;
                                    direction_selector = 1'b1;
                                    break;
                                end
                            end
                        end
                    end
                end
                // Priority 2: External calls in current direction
                else if (elevator_direction && (|up_requests)) begin
                    // External call logic
                    for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                        if (up_requests[i]) begin
                            elevator_floor_selector = i;
                            direction_selector = 1'b1;
                            break;
                        end
                    end
                end
                else if (!elevator_direction && (|down_requests)) begin
                    for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                        if (down_requests[i]) begin
                            elevator_floor_selector = i;
                            direction_selector = 1'b0;
                            break;
                        end
                    end
                end
                // Priority 3: Remaining external calls
                else if (|up_requests) begin
                    for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                        if (up_requests[i]) begin
                            elevator_floor_selector = i;
                            direction_selector = 1'b1;
                            break;
                        end
                    end
                    if (i == 11) begin
                        for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                            if (up_requests[i]) begin
                                elevator_floor_selector = i;
                                direction_selector = 1'b0;
                                break;
                            end
                        end
                    end
                end
                else if (|down_requests) begin
                    for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                        if (down_requests[i]) begin
                            elevator_floor_selector = i;
                            direction_selector = 1'b0;
                            break;
                        end
                    end
                    if (i == -1) begin
                        for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                            if (down_requests[i]) begin
                                elevator_floor_selector = i;
                                direction_selector = 1'b1;
                                break;
                            end
                        end
                    end
                end
            end
        end
    end
end

// Door control logic
always @(*) begin
    
    // Door control only active when elevator is stopped and power is on
    if (is_stop_state(elevator_state) && power_switch) begin
        door_open_allowed = door_open_btn;
        door_close_allowed = door_close_btn;
    end
end

// Emergency handling - clear all requests
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // Reset logic
    end 
    else if (emergency_btn) begin
        up_requests <= 11'b0;
        down_requests <= 11'b0;
        panel_requests <= 11'b0;
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
    end
end

endmodule