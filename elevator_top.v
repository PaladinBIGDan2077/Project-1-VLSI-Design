/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator System Top Module
// Filename:                        elevator_top.v
// Version:                         1
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/13/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Doctor Jeffrey Walling 
//  
// Hardware Description Language:   Verilog 2001 (IEEE 1364-2001)  
// Simulation Tool:                 iVerilog 12.0
// 
// Description:                     Top-level module that integrates all elevator system components.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/13/2025    DJL  1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////

module elevator_top(clock, reset_n, raw_floor_call_buttons, raw_panel_buttons, raw_door_open_btn, raw_door_close_btn, raw_emergency_btn, raw_power_switch, weight_sensor, call_button_lights, panel_button_lights, door_open, elevator_control_output, safety_interlock, floor_indicator_lamps, elevator_upward_indicator_lamp, elevator_downward_indicator_lamp, alarm, weight_overload_lamp);
    // Primary inputs
    input                                           reset_n;                    // Active-low reset
    input                                           clock;

    // Button inputs (raw buttons - will be debounced)
    input                   [10:0]                  raw_floor_call_buttons;  // External call buttons
    input                   [10:0]                  raw_panel_buttons;       // Internal destination buttons
    input                                           raw_door_open_btn;
    input                                           raw_door_close_btn;
    input                                           raw_emergency_btn;
    input                                           raw_power_switch;
    input                                           weight_sensor;
    

    // Outputs to physical devices
    output                  [10:0]                  call_button_lights;      // External button illumination
    output                  [10:0]                  panel_button_lights;     // Internal button illumination
    output                                          door_open;
    output                  [10:0]                  elevator_control_output; // Control signals to elevator mechanism
    output                  [3:0]                   floor_indicator_lamps;      // For debugging/display
    output                                          safety_interlock;
    output                                          elevator_upward_indicator_lamp;
    output                                          elevator_downward_indicator_lamp;
    output                                          weight_overload_lamp;
    output                                          alarm;

    // Internal wires for debounced buttons
    wire                    [10:0]                  floor_call_buttons;
    wire                    [10:0]                  panel_buttons;
    wire                                            door_open_btn;
    wire                                            door_close_btn;
    wire                                            emergency_btn;
    wire                                            power_switch;
    wire                                            door_open_logic_check;
    wire                                            door_close_logic_check;
    wire                                            reset_n;
    wire                                            clock;


    // Internal wires between modules
    wire                    [3:0]                   elevator_floor_selector;
    wire                                            direction_selector;
    wire                                            activate_elevator;
    wire                    [4:0]                   elevator_state;
    wire                                            elevator_moving;
    wire                                            elevator_direction;
    wire                    [3:0]                   current_floor_state;
    wire                                            door_close;


    // FSM/Control Signalling
    wire                                            elevator_movement;
    
    // Debounce all button inputs
    // Floor call button debouncers (11 buttons)
    button_debouncer floor_call_debouncer0 (clock, reset_n, ~raw_floor_call_buttons[0], floor_call_buttons[0]);
    button_debouncer floor_call_debouncer1 (clock, reset_n, ~raw_floor_call_buttons[1], floor_call_buttons[1]);
    button_debouncer floor_call_debouncer2 (clock, reset_n, ~raw_floor_call_buttons[2], floor_call_buttons[2]);
    button_debouncer floor_call_debouncer3 (clock, reset_n, ~raw_floor_call_buttons[3], floor_call_buttons[3]);
    button_debouncer floor_call_debouncer4 (clock, reset_n, ~raw_floor_call_buttons[4], floor_call_buttons[4]);
    button_debouncer floor_call_debouncer5 (clock, reset_n, ~raw_floor_call_buttons[5], floor_call_buttons[5]);
    button_debouncer floor_call_debouncer6 (clock, reset_n, ~raw_floor_call_buttons[6], floor_call_buttons[6]);
    button_debouncer floor_call_debouncer7 (clock, reset_n, ~raw_floor_call_buttons[7], floor_call_buttons[7]);
    button_debouncer floor_call_debouncer8 (clock, reset_n, ~raw_floor_call_buttons[8], floor_call_buttons[8]);
    button_debouncer floor_call_debouncer9 (clock, reset_n, ~raw_floor_call_buttons[9], floor_call_buttons[9]);
    button_debouncer floor_call_debouncer10 (clock, reset_n, ~raw_floor_call_buttons[10], floor_call_buttons[10]);

    // Panel button debouncers (11 buttons)
    button_debouncer panel_debouncer0 (clock, reset_n, ~raw_panel_buttons[0], panel_buttons[0]);
    button_debouncer panel_debouncer1 (clock, reset_n, ~raw_panel_buttons[1], panel_buttons[1]);
    button_debouncer panel_debouncer2 (clock, reset_n, ~raw_panel_buttons[2], panel_buttons[2]);
    button_debouncer panel_debouncer3 (clock, reset_n, ~raw_panel_buttons[3], panel_buttons[3]);
    button_debouncer panel_debouncer4 (clock, reset_n, ~raw_panel_buttons[4], panel_buttons[4]);
    button_debouncer panel_debouncer5 (clock, reset_n, ~raw_panel_buttons[5], panel_buttons[5]);
    button_debouncer panel_debouncer6 (clock, reset_n, ~raw_panel_buttons[6], panel_buttons[6]);
    button_debouncer panel_debouncer7 (clock, reset_n, ~raw_panel_buttons[7], panel_buttons[7]);
    button_debouncer panel_debouncer8 (clock, reset_n, ~raw_panel_buttons[8], panel_buttons[8]);
    button_debouncer panel_debouncer9 (clock, reset_n, ~raw_panel_buttons[9], panel_buttons[9]);
    button_debouncer panel_debouncer10 (clock, reset_n, ~raw_panel_buttons[10], panel_buttons[10]);

    
    // Debounce control buttons
    button_debouncer door_open_debouncer (clock, reset_n, ~raw_door_open_btn, door_open_btn);
    button_debouncer door_close_debouncer (clock, reset_n, ~raw_door_close_btn, door_close_btn);
    button_debouncer emergency_debouncer (clock, reset_n, ~raw_emergency_btn, emergency_btn);
    assign power_switch = raw_power_switch; // No debouncing for power switch

    // Floor logic controller
    floor_logic_control_unit floor_logic_inst (clock, reset_n, floor_call_buttons, panel_buttons, door_open_btn, door_close_btn, emergency_btn, power_switch, floor_indicator_lamps, elevator_state, elevator_movement, elevator_direction, elevator_floor_selector, direction_selector, activate_elevator, call_button_lights, panel_button_lights, door_open_logic_check, door_close_logic_check);

    
    
    // Elevator finite state machine
    elevator_fsm elevator_fsm_inst (clock, reset_n, elevator_floor_selector, emergency_btn, activate_elevator, weight_sensor, power_switch, direction_selector, elevator_state, elevator_control_output);

    assign safety_interlock = elevator_control_output[0];
    assign elevator_movement = elevator_control_output[1];
    assign elevator_direction = elevator_control_output[2];
    assign elevator_upward_indicator_lamp = elevator_control_output[2];
    assign elevator_downward_indicator_lamp = elevator_control_output[3];
// Door control logic with button override
    assign door_open = door_open_logic_check ? 1'b1 : door_close_logic_check ? 1'b0 : elevator_control_output[4];
    assign door_close = door_close_logic_check ? 1'b1 : elevator_control_output[5];
    assign alarm = elevator_control_output[6];
    assign weight_overload_lamp = weight_sensor;
    assign floor_indicator_lamps = elevator_control_output[10:7];



endmodule