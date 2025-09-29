/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator System Top Module Testbench
// Filename:                        elevator_top_tb.v
// Version:                         2
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
// Description:                     Testbench for elevator_top.v. 
//                                  Provides basic simulation environment to verify floor button requests
//                                  and observe elevator movement across floors.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/13/2025   DJL  1        Original Testbench Code
//                                  9/14/2025   DJL  2        Added additional testing
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

    wire                                                        clock;
    wire                        [10:0]                          call_button_lights;
    wire                        [10:0]                          panel_button_lights;
    wire                                                        door_open;
    wire                        [10:0]                          elevator_control_output;
    wire                        [3:0]                           floor_indicator_lamps;
    wire                                                        safety_interlock;
    wire                                                        elevator_upward_indicator_lamp;
    wire                                                        elevator_downward_indicator_lamp;
    wire                                                        alarm;
    wire                                                        weight_overload_lamp;

    // Instantiate DUT
    elevator_top dut (clock, reset_n, raw_floor_call_buttons, raw_panel_buttons, raw_door_open_btn, raw_door_close_btn, raw_emergency_btn, raw_power_switch, weight_sensor, call_button_lights, panel_button_lights, door_open, elevator_control_output, safety_interlock, floor_indicator_lamps, elevator_upward_indicator_lamp, elevator_downward_indicator_lamp, alarm, weight_overload_lamp);
    clk clock_dut (1'b1, clock);



    initial begin
	// Dump sim files
	    $dumpfile("elevator_control_system.vcd");
	    $dumpvars(0,elevator_top_tb);

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
        #50
        reset_n = 1;
        $display("=== Reset complete ===");
        // Outside Elevator Testing
        // Request from Floor 3
        #1000
        raw_floor_call_buttons[2] = 1;
        $display("Floor 3 call button pressed @ %t", $time);
        #2000 
        raw_floor_call_buttons[2] = 0; // release button

        // Request from Floor 7
        #1000
        raw_floor_call_buttons[6] = 1;
        $display("Floor 7 call button pressed @ %t", $time);
        #2000 
        raw_floor_call_buttons[6] = 0;

        // Request from  Floor 2
        #1000
        raw_floor_call_buttons[1] = 1;
        $display("Floor 1 call button pressed @ %t", $time);
        #2000
        raw_floor_call_buttons[1] = 0;

        // Inside Elevator Testing
        // Call to Floor 5
        #1000
        raw_panel_buttons[] = 1;
        $display("Floor 5 call button pressed @ %t", $time);
        #2000
        raw_panel_buttons[4] = 0;
        // Call to Floor 10
        #1000
        raw_panel_buttons[9] = 1;
        $display("Floor 10 call button pressed @ %t", $time);
        #2000
        raw_panel_buttons[9] = 0;
        // Call to Floor 8
        #1000
        raw_panel_buttons[7] = 1;
        $display("Floor 8 call button pressed @ %t", $time);
        #2000
        raw_panel_buttons[7] = 0;

        // Return to first floor
        #1000
        raw_panel_buttons[0] = 1;
        $display("Floor 1 call button pressed @ %t", $time);
        #2000
        raw_panel_buttons[0] = 0;

        // Inside Elevator Testing -- Select Destination, then select a destination while moving
        // Call to Floor 11
        #1000
        raw_panel_buttons[10] = 1;
        $display("Floor 11 call button pressed @ %t", $time);
        #200
        raw_panel_buttons[10] = 0;
        // Call to Floor 6
        #100
        raw_panel_buttons[5] = 1;
        $display("Floor 6 call button pressed @ %t", $time);
        #100
        raw_panel_buttons[5] = 0;
        // Call to Floor 8
        #100
        raw_panel_buttons[7] = 1;
        $display("Floor 8 call button pressed @ %t", $time);
        #100
        raw_panel_buttons[7] = 0;
        #2000
        // Reset for next test
        reset_n = 0;
        #50
        reset_n = 1;
        $display("=== Reset complete ===");

        // Emergency Conditions - Weight
        // Go to Floor 4
        #1000
        raw_panel_buttons[3] = 1;
        $display("Floor 4 call button pressed @ %t", $time);
        #2000
        raw_panel_buttons[3] = 0;
        #1000
        weight_sensor = 1;
        $display("Weight Sensor activated @ %t", $time);
        #200

        // Attempt to go to Floor 2
        raw_panel_buttons[1] = 1;
        $display("Floor 2 call button pressed @ %t", $time);
        #1000
        raw_panel_buttons[1] = 0;
        #2000

        weight_sensor = 0;
        #1000
        // Reset for next test
        reset_n = 0;
        #50
        reset_n = 1;
        $display("=== Reset complete ===");

        // Emergency Conditions - Emergency Button
        // Go to Floor 4
        #1000
        raw_panel_buttons[3] = 1;
        $display("Floor 4 call button pressed @ %t", $time);
        #200
        raw_panel_buttons[3] = 0;
        #500
        raw_emergency_btn = 1;
        $display("Emergency Button activated @ %t", $time);
        #200
        raw_emergency_btn = 0;
        #500
        // Attempt to go to Floor 2
        raw_panel_buttons[1] = 1;
        $display("Floor 2 call button pressed @ %t", $time);
        #200
        raw_panel_buttons[1] = 0;
        #500
        
        // Reset for next test
        reset_n = 0;
        #50
        reset_n = 1;
        $display("=== Reset complete ===");
        // Test Door Close Button
        #1000
        raw_door_close_btn = 1;
        $display("Door Close button pressed @ %t", $time);
        #2000
        raw_door_close_btn = 0;
        $display("Door Close button released @ %t", $time);
        #1000; // Wait to observe door behavior
        
        // Test Door Open Button
        #1000
        raw_door_open_btn = 1;
        $display("Door Open button pressed @ %t", $time);
        #2000
        raw_door_open_btn = 0;
        $display("Door Open button released @ %t", $time);
        #1000; // Wait to observe door behavior
        

        // Test Door Open while moving (should be ignored)
        #500
        raw_panel_buttons[5] = 1; // Request floor 6
        $display("Floor 6 call button pressed @ %t", $time);
        #50
        raw_panel_buttons[5] = 0;
        #1000 // Wait for elevator to start moving
        raw_door_open_btn = 1;
        $display("Door Open button pressed while moving @ %t", $time);
        #200
        raw_door_open_btn = 0;
        $display("Door Open button released @ %t", $time);
        #2000; // Wait to observe that door doesn't open while moving
        
        // Test Door Close while stopped (should work)
        #1000
        raw_door_close_btn = 1;
        $display("Door Close button pressed while stopped @ %t", $time);
        #2000
        raw_door_close_btn = 0;
        $display("Door Close button released @ %t", $time);
        #1000;

        // Power Switch Functionaility
        // Reset for final test
        reset_n = 0;
        #50
        reset_n = 1;
        $display("=== Reset complete ===");
        // Test Power Switch Button
        #1000
        raw_panel_buttons[5] = 1;
        $display("Floor 6 call button pressed @ %t", $time);
        #2000
        raw_panel_buttons[5] = 0;
        #1000
        raw_power_switch = 0;
        $display("Power switched off @ %t", $time);
        #100
        // Attempt to open doors
        raw_door_open_btn = 1;
        // Attempt to move floors
        raw_panel_buttons[8] = 1;
        $display("Floor 9 call button pressed @ %t", $time);
        #1000
        raw_door_open_btn = 0;
        raw_panel_buttons[8] = 0;
        #2000
        raw_power_switch = 1;
        $display("Power switched on @ %t", $time);
        #1000; // Wait to observe door behavior

        // Edge Case - Pressing all the buttons inside
        // 
        $display("All Floor panel buttons begin pressing @ %t", $time);

        reset_n = 0;
        #50
        reset_n = 1;
        $display("=== Reset complete ===");

        raw_panel_buttons[10:0] = 11'b10000000000; // Request floor 11
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;
        #1500
        raw_panel_buttons[10:0] = 11'b01000000000; // Request floor 10
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;
        #1500
        raw_panel_buttons[10:0] = 11'b00100000000; // Request floor 9
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;     
        #1500
        raw_panel_buttons[10:0] = 11'b00010000000; // Request floor 8
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;
        #1500
        raw_panel_buttons[10:0] = 11'b00001000000; // Request floor 7
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;     
        #1500
        raw_panel_buttons[10:0] = 11'b00000100000; // Request floor 6
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;
        #1500
        raw_panel_buttons[10:0] = 11'b00000010000; // Request floor 5
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;     
        #1500
        raw_panel_buttons[10:0] = 11'b00000001000; // Request floor 4
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;
        #1500
        raw_panel_buttons[10:0] = 11'b00000000100; // Request floor 3
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;     
        #1500
        raw_panel_buttons[10:0] = 11'b01000000010; // Request floor 2
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;
        #1500
        raw_panel_buttons[10:0] = 11'b00000000001; // Request floor 1
        #100
        raw_panel_buttons[10:0] = 11'b00000000000;     
        $display("All Floor panel buttons end pressing @ %t", $time);

        #2000;
        $display("Simulation finished.");
        $finish;
    end
endmodule
