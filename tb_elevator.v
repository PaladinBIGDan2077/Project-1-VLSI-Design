/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator System Top Module Testbench
// Filename:                        elevator_top_tb.v
// Version:                         1
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/13/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Doctor Jeffrey Walling 
//  
// Hardware Description Language:   Verilog 2001 (IEEE 1364-2001)  
// Simulation Tool:                 ModelSim: Intel FPGA Starter Edition 21.1 
// 
// Description:                     Testbench for elevator_top.v. 
//                                  Provides basic simulation environment to verify floor button requests
//                                  and observe elevator movement across floors.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/13/2025   DJL  1        Original Testbench Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns
module elevator_top_tb;

    // Testbench signals
    reg                                                         reset_n;
    reg                         [10:0]                          raw_floor_call_buttons;
    reg                         [10:0]                          raw_panel_buttons;
    reg                                                         raw_door_open_btn;
    reg                                                         raw_door_close_btn;
    reg                                                         raw_emergency_btn;
    reg                                                         raw_power_switch;
    reg                                                         weight_sensor;

    wire                        [10:0]                          call_button_lights;
    wire                        [10:0]                          panel_button_lights;
    wire                                                        door_open_light;
    wire                                                        door_close_light;
    wire                        [10:0]                          elevator_control_output;
    wire                        [5:0]                           current_state_display;
    wire                        [3:0]                           current_floor_display;

    // Instantiate DUT
    elevator_top dut (reset_n, raw_floor_call_buttons, raw_panel_buttons, raw_door_open_btn, raw_door_close_btn, raw_emergency_btn, raw_power_switch, weight_sensor, call_button_lights, panel_button_lights, door_open_light, door_close_light, elevator_control_output, current_state_display, current_floor_display);

    initial begin
        // Initialize inputs
        reset_n = 0;
        raw_floor_call_buttons = 11'b0;
        raw_panel_buttons = 11'b0;
        raw_door_open_btn = 0;
        raw_door_close_btn = 0;
        raw_emergency_btn = 0;
        raw_power_switch = 1;   // power ON
        weight_sensor = 0;

        // Apply reset
        #20;
        reset_n = 1;
        $display("=== Reset complete ===");

        // Request Floor 3
        #50;
        raw_floor_call_buttons[2] = 1;
        $display("Floor 3 call button pressed @ %t", $time);
        #20 raw_floor_call_buttons[2] = 0; // release button

        // Request Floor 7
        #200;
        raw_floor_call_buttons[6] = 1;
        $display("Floor 7 call button pressed @ %t", $time);
        #20 raw_floor_call_buttons[6] = 0;

        // Request Floor 1
        #300;
        raw_floor_call_buttons[0] = 1;
        $display("Floor 1 call button pressed @ %t", $time);
        #20 raw_floor_call_buttons[0] = 0;

        // Run for a while
        #1000;
        $display("Simulation finished.");
        $stop;
    end

endmodule
