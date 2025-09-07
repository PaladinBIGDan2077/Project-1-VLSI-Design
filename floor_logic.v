/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator Floor Logic Controller
// Filename:                        floor_logic.v
// Version:                         1
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/7/2025 
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Doctor Jeffrey Walling 
//  
// Hardware Description Language:   Verilog 2001 (IEEE 1364-2001)  
// Simulation Tool:                 ModelSim: Intel FPGA Starter Edition 21.1 
// 
// Description:                     Floor request logic controller that manages elevator call buttons,
//                                  destination requests, and priority handling for the elevator FSM.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/7/2025    DJL  1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////

module floor_logic_control_unit(clock, reset_n, floor_call_buttons, panel_buttons, door_open_btn, door_close_btn, emergency_btn, power_switch, current_floor_state, elevator_state, elevator_moving, elevator_direction, elevator_floor_selector, direction_selector, activate_elevator, power_switch_override, call_button_lights, panel_button_lights, door_open_light, door_close_light);
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
    output                                  power_switch_override;     // Signal to FSM for power switch handling
    
    // Button status outputs (for illumination)
    output              [10:0]              call_button_lights;
    output              [10:0]              panel_button_lights;
    output                                  door_open_light;
    output                                  door_close_light;

    reg                 [3:0]               elevator_floor_selector;
    reg                                     direction_selector;
    reg                                     activate_elevator;
    reg                                     power_switch_override;     // Signal to FSM for power switch handling
    
    // Button status outputs (for illumination)
    reg                 [10:0]              call_button_lights;
    reg                 [10:0]              panel_button_lights;
    reg                                     door_open_light;
    reg                                     door_close_light;

// Internal registers for request management
    reg                 [10:0]              up_requests;       // External calls for upward direction
    reg                 [10:0]              down_requests;     // External calls for downward direction  
    reg                 [10:0]              panel_requests;    // Internal destination requests
    reg                                     power_switch_active;      // Power switch state
    reg                 [3:0]               nearest_floor;      // Nearest floor for power switch shutdown

// Floor parameters matching FSM
    parameter                               FLOOR_1  = 4'h0, 
                                            FLOOR_2  = 4'h1, 
                                            FLOOR_3  = 4'h2, 
                                            FLOOR_4  = 4'h3, 
                                            FLOOR_5  = 4'h4,
                                            FLOOR_6  = 4'h5, 
                                            FLOOR_7  = 4'h6, 
                                            FLOOR_8  = 4'h7, 
                                            FLOOR_9  = 4'h8, 
                                            FLOOR_10 = 4'h9, 
                                            FLOOR_11 = 4'hA;

// State parameters for readability
    parameter                STOP_STATES = {STOP_FL1, 
                                            STOP_FL2, 
                                            STOP_FL3, 
                                            STOP_FL4, 
                                            STOP_FL5,
                                            STOP_FL6, 
                                            STOP_FL7, 
                                            STOP_FL8, 
                                            STOP_FL9, 
                                            STOP_FL10, 
                                            STOP_FL11};

    parameter                   UP_STATES = {UP_F1_F2, 
                                             UP_F2_F3, 
                                             UP_F3_F4, 
                                             UP_F4_F5, 
                                             UP_F5_F6,
                                             UP_F6_F7, 
                                             UP_F7_F8, 
                                             UP_F8_F9, 
                                             UP_F9_F10, 
                                             UP_F10_F11};

    parameter                 DOWN_STATES = {DOWN_F2_F1, 
                                             DOWN_F3_F2, 
                                             DOWN_F4_F3, 
                                             DOWN_F5_F4, 
                                             DOWN_F6_F5,
                                             DOWN_F7_F6, 
                                             DOWN_F8_F7, 
                                             DOWN_F9_F8, 
                                             DOWN_F10_F9, 
                                             DOWN_F11_F10};

// Power switch handling - detect rising edge
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        power_switch_active <= 1'b0;
    end else begin
        power_switch_active <= power_switch;
    end
end

wire power_switch_trigger = power_switch && !power_switch_active;

// Find nearest floor for power shutdown
always @(*) begin
    nearest_floor = current_floor_state;
    
    if (power_switch_trigger) begin
        // If already at a floor, stay there
        if (elevator_state inside STOP_STATES) begin
            nearest_floor = current_floor_state;
        end
        // If moving between floors, find closest floor
        else begin
            if (elevator_direction) begin
                // Moving up - go to next floor up
                if (current_floor_state < FLOOR_11) begin
                    nearest_floor = current_floor_state + 1;
                end else begin
                    nearest_floor = FLOOR_11;
                end
            end else begin
                // Moving down - go to next floor down
                if (current_floor_state > FLOOR_1) begin
                    nearest_floor = current_floor_state - 1;
                end else begin
                    nearest_floor = FLOOR_1;
                end
            end
        end
    end
end

// Button processing - capture new requests
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        up_requests <= 11'b0;
        down_requests <= 11'b0;
        panel_requests <= 11'b0;
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
    end else if (power_switch_trigger) begin
        // Power switch triggered - clear all queues immediately
        up_requests <= 11'b0;
        down_requests <= 11'b0;
        panel_requests <= 11'b0;
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
    end else if (!power_switch) begin
        // Normal operation - process buttons
        for (integer i = 0; i < 11; i = i + 1) begin
            if (floor_call_buttons[i]) begin
                if (i > current_floor_state) begin
                    up_requests[i] <= 1'b1;
                end else if (i < current_floor_state) begin
                    down_requests[i] <= 1'b1;
                end
                call_button_lights[i] <= 1'b1;
            end
        end
        
        for (integer i = 0; i < 11; i = i + 1) begin
            if (panel_buttons[i]) begin
                panel_requests[i] <= 1'b1;
                panel_button_lights[i] <= 1'b1;
            end
        end
    end
end

// Clear only the current floor when elevator arrives
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // Keep existing reset
    end else if (!power_switch) begin
        if (elevator_state inside STOP_STATES) begin
            up_requests[current_floor_state] <= 1'b0;
            down_requests[current_floor_state] <= 1'b0;
            panel_requests[current_floor_state] <= 1'b0;
            call_button_lights[current_floor_state] <= 1'b0;
            panel_button_lights[current_floor_state] <= 1'b0;
        end
    end
end

// Target floor selection logic
always @(*) begin
    activate_elevator = 1'b0;
    elevator_floor_selector = current_floor_state;
    direction_selector = elevator_direction;
    power_switch_override = 1'b0;
    
    integer i;
    
    // Power switch takes highest priority
    if (power_switch_trigger) begin
        activate_elevator = 1'b1;
        power_switch_override = 1'b1;
        elevator_floor_selector = nearest_floor;
        direction_selector = (nearest_floor > current_floor_state) ? 1'b1 : 1'b0;
    end
    // Normal operation when power is on and no emergency
    else if (!power_switch && !emergency_btn) {
        // Only process requests when elevator is stopped
        if (elevator_state inside STOP_STATES) {
            // Check if there are any pending requests
            if (|panel_requests || |up_requests || |down_requests) {
                activate_elevator = 1'b1;
                
                // Priority 1: Panel requests
                if (|panel_requests) {
                    // [Existing panel request logic...]
                    if (elevator_direction) {
                        for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                            if (panel_requests[i]) {
                                elevator_floor_selector = i;
                                direction_selector = 1'b1;
                                break;
                            end
                        end
                        if (i == 11) begin
                            for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                                if (panel_requests[i]) {
                                    elevator_floor_selector = i;
                                    direction_selector = 1'b0;
                                    break;
                                }
                            }
                        end
                    end else begin
                        for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                            if (panel_requests[i]) {
                                elevator_floor_selector = i;
                                direction_selector = 1'b0;
                                break;
                            }
                        end
                        if (i == -1) begin
                            for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                                if (panel_requests[i]) {
                                    elevator_floor_selector = i;
                                    direction_selector = 1'b1;
                                    break;
                                }
                            }
                        end
                    end
                }
                // Priority 2: External calls in current direction
                else if (elevator_direction && (|up_requests)) {
                    // [Existing external call logic...]
                    for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                        if (up_requests[i]) {
                            elevator_floor_selector = i;
                            direction_selector = 1'b1;
                            break;
                        end
                    }
                }
                else if (!elevator_direction && (|down_requests)) {
                    for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                        if (down_requests[i]) {
                            elevator_floor_selector = i;
                            direction_selector = 1'b0;
                            break;
                        }
                    }
                }
                // Priority 3: Remaining external calls
                else if (|up_requests) {
                    for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                        if (up_requests[i]) {
                            elevator_floor_selector = i;
                            direction_selector = 1'b1;
                            break;
                        }
                    }
                    if (i == 11) begin
                        for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                            if (up_requests[i]) {
                                elevator_floor_selector = i;
                                direction_selector = 1'b0;
                                break;
                            }
                        }
                    end
                }
                else if (|down_requests) {
                    for (i = current_floor_state - 1; i >= 0; i = i - 1) begin
                        if (down_requests[i]) {
                            elevator_floor_selector = i;
                            direction_selector = 1'b0;
                            break;
                        }
                    }
                    if (i == -1) begin
                        for (i = current_floor_state + 1; i < 11; i = i + 1) begin
                            if (down_requests[i]) {
                                elevator_floor_selector = i;
                                direction_selector = 1'b1;
                                break;
                            }
                        }
                    end
                }
            }
        }
    end
end

// Door control logic
always @(*) begin
    door_open_light = 1'b0;
    door_close_light = 1'b0;
    
    // Door control only active when elevator is stopped and power is on
    if (elevator_state inside STOP_STATES && !emergency_btn && !power_switch) begin
        door_open_light = door_open_btn;
        door_close_light = door_close_btn;
    end
end

// Emergency handling - clear all requests
always @(posedge clock or negedge reset_n) begin
    if (emergency_btn) begin
        up_requests <= 11'b0;
        down_requests <= 11'b0;
        panel_requests <= 11'b0;
        call_button_lights <= 11'b0;
        panel_button_lights <= 11'b0;
    end
end

endmodule