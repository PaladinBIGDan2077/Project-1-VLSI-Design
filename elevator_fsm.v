/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator State Machine
// Filename:                        elevator_fsm.v
// Version:                         1
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/7/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Dcotor Jeffrey Walling 
//  
// Hardware Description Language:   Verilog 2001 (IEEE 1364-2001)  
// Simulation Tool:                 ModelSim: Intel FPGA Starter Edition 21.1 
// 
// Description:                     Elevator Finite State Machine (FSM) that controls the operation 
//                                  of the elevator based on inputs from buttons and sensors.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/7/2025    DJL  1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module elevator_fsm(clock, init, operation_code, execute, control_output);
    input                                                     clock;     
	input                                                     init; // Active-low reset (KEY[1])
    input                       [3:0]                         elevator_floor_selector; // Elevator Floor Selector (4 bits for 11 floors) Comes from floor_logic.v
    input                                                     emergency_stop;
    input                                                     activate_elevator;
    input                                                     weight_sensor;
    input                                                     power_switch;
    input                                                     direction_selector; // 1 bit for up / 0 for down
	output                      [7:0]                         control_output;    
    output                      [5:0]                         counter_state;         

	reg                         [5:0]                         counter_state;
    reg                         [5:0]                         next_counter_state;
    reg                         [7:0]                         control_output;      

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
	
    // Operation code register
    // 
    assign operation_code = counter_state;
    always @(posedge clock or negedge init) begin
		if (!init) begin
			counter_state <= STOP_FL1; // Reset to initial state
        end
		else begin
            counter_state <= next_counter_state; // Update state to next state
        end
    end

    always @(*) begin
        case(counter_state)
            STOP_FL1:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F1_F2                                                                                                         : (emergency_stop) ? EMERGENCY : STOP_FL1;
            UP_F1_F2:         next_counter_state = ((elevator_floor_selector == FLOOR_2) & (direction_selector)                     ) ? STOP_FL2     : ((direction_selector)                                                             ) ? UP_F2_F3    : (emergency_stop) ? EMERGENCY : UP_F1_F2;
            DOWN_F2_F1:       next_counter_state = ((elevator_floor_selector == FLOOR_1) & (!direction_selector)                    ) ? STOP_FL1                                                                                                         : (emergency_stop) ? EMERGENCY : DOWN_F2_F1;
            STOP_FL2:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F2_F3     : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F2_F1  : (emergency_stop) ? EMERGENCY : STOP_FL2;
            UP_F2_F3:         next_counter_state = ((elevator_floor_selector == FLOOR_3) & (direction_selector)                     ) ? STOP_FL3     : ((direction_selector)                                                             ) ? UP_F3_F4    : (emergency_stop) ? EMERGENCY : UP_F2_F3;
            DOWN_F3_F2:       next_counter_state = ((elevator_floor_selector == FLOOR_2) & (!direction_selector)                    ) ? STOP_FL2     : ((!direction_selector)                                                            ) ? DOWN_F2_F1  : (emergency_stop) ? EMERGENCY : DOWN_F3_F2;
            STOP_FL3:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F3_F4     : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F3_F2  : (emergency_stop) ? EMERGENCY : STOP_FL3;
            UP_F3_F4:         next_counter_state = ((elevator_floor_selector == FLOOR_4) & (direction_selector)                     ) ? STOP_FL4     : ((direction_selector)                                                             ) ? UP_F4_F5    : (emergency_stop) ? EMERGENCY : UP_F3_F4;
            DOWN_F4_F3:       next_counter_state = ((elevator_floor_selector == FLOOR_3) & (!direction_selector)                    ) ? STOP_FL3     : ((!direction_selector)                                                            ) ? DOWN_F3_F2  : (emergency_stop) ? EMERGENCY : DOWN_F4_F3;
            STOP_FL4:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F4_F5     : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F4_F3  : (emergency_stop) ? EMERGENCY : STOP_FL4;
            UP_F4_F5:         next_counter_state = ((elevator_floor_selector == FLOOR_5) & (direction_selector)                     ) ? STOP_FL5     : ((direction_selector)                                                             ) ? UP_F5_F6    : (emergency_stop) ? EMERGENCY : UP_F4_F5;
            DOWN_F5_F4:       next_counter_state = ((elevator_floor_selector == FLOOR_4) & (!direction_selector)                    ) ? STOP_FL4     : ((!direction_selector)                                                            ) ? DOWN_F4_F3  : (emergency_stop) ? EMERGENCY : DOWN_F5_F4;
            STOP_FL5:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F5_F6     : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F5_F4  : (emergency_stop) ? EMERGENCY : STOP_FL5;
            UP_F5_F6:         next_counter_state = ((elevator_floor_selector == FLOOR_6) & (direction_selector)                     ) ? STOP_FL6     : ((direction_selector)                                                             ) ? UP_F6_F7    : (emergency_stop) ? EMERGENCY : UP_F5_F6;
            DOWN_F6_F5:       next_counter_state = ((elevator_floor_selector == FLOOR_5) & (!direction_selector)                    ) ? STOP_FL5     : ((!direction_selector)                                                            ) ? DOWN_F5_F4  : (emergency_stop) ? EMERGENCY : DOWN_F6_F5;
            STOP_FL6:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F6_F7     : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F6_F5  : (emergency_stop) ? EMERGENCY : STOP_FL6;
            UP_F6_F7:         next_counter_state = ((elevator_floor_selector == FLOOR_7) & (direction_selector)                     ) ? STOP_FL7     : ((direction_selector)                                                             ) ? UP_F7_F8    : (emergency_stop) ? EMERGENCY : UP_F6_F7;
            DOWN_F7_F6:       next_counter_state = ((elevator_floor_selector == FLOOR_6) & (!direction_selector)                    ) ? STOP_FL6     : ((!direction_selector)                                                            ) ? DOWN_F6_F5  : (emergency_stop) ? EMERGENCY : DOWN_F7_F6;
            STOP_FL7:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F7_F8     : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F7_F6  : (emergency_stop) ? EMERGENCY : STOP_FL7;
            UP_F7_F8:         next_counter_state = ((elevator_floor_selector == FLOOR_8) & (direction_selector)                     ) ? STOP_FL8     : ((direction_selector)                                                             ) ? UP_F8_F9    : (emergency_stop) ? EMERGENCY : UP_F7_F8;
            DOWN_F8_F7:       next_counter_state = ((elevator_floor_selector == FLOOR_7) & (!direction_selector)                    ) ? STOP_FL7     : ((!direction_selector)                                                            ) ? DOWN_F7_F6  : (emergency_stop) ? EMERGENCY : DOWN_F8_F7;
            STOP_FL8:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F8_F9     : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F8_F7  : (emergency_stop) ? EMERGENCY : STOP_FL8;
            UP_F8_F9:         next_counter_state = ((elevator_floor_selector == FLOOR_9) & (direction_selector)                     ) ? STOP_FL9     : ((direction_selector)                                                             ) ? UP_F9_F10   : (emergency_stop) ? EMERGENCY : UP_F8_F9;
            DOWN_F9_F8:       next_counter_state = ((elevator_floor_selector == FLOOR_8) & (!direction_selector)                    ) ? STOP_FL8     : ((!direction_selector)                                                            ) ? DOWN_F8_F7  : (emergency_stop) ? EMERGENCY : DOWN_F9_F8;
            STOP_FL9:         next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F9_F10    : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F9_F8  : (emergency_stop) ? EMERGENCY : STOP_FL9;
            UP_F9_F10:        next_counter_state = ((elevator_floor_selector == FLOOR_10) & (direction_selector)                    ) ? STOP_FL10    : ((direction_selector)                                                             ) ? UP_F10_F11  : (emergency_stop) ? EMERGENCY : UP_F9_F10;
            DOWN_F10_F9:      next_counter_state = ((elevator_floor_selector == FLOOR_9) & (!direction_selector)                    ) ? STOP_FL9     : ((!direction_selector)                                                            ) ? DOWN_F9_F8  : (emergency_stop) ? EMERGENCY : DOWN_F10_F9;
            STOP_FL10:        next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (direction_selector) ) ? UP_F10_F11   : ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector) ) ? DOWN_F10_F9 : (emergency_stop) ? EMERGENCY : STOP_FL10;
            UP_F10_F11:       next_counter_state = ((elevator_floor_selector == FLOOR_11) & (direction_selector)                    ) ? STOP_FL11    : ((direction_selector)                                                             ) ? UP_F10_F11  : (emergency_stop) ? EMERGENCY : UP_F10_F11;
            DOWN_F11_F10:     next_counter_state = ((elevator_floor_selector == FLOOR_10) & (!direction_selector)                   ) ? STOP_FL10    : ((!direction_selector)                                                            ) ? DOWN_F10_F9 : (emergency_stop) ? EMERGENCY : DOWN_F11_F10;
            STOP_FL11:        next_counter_state = ((activate_elevator) & (power_switch) & (!emergency_stop) & (!direction_selector)) ? DOWN_F11_F10                                                                                                     : (emergency_stop) ? EMERGENCY : STOP_FL11;
            EMERGENCY:        next_counter_state = ((!power_switch) & (!emergency_stop)                                             ) ? STOP_FL1                                                                                                         : (emergency_stop) ? EMERGENCY : EMERGENCY; // Stay in emergency until reset
            default:          next_counter_state = 6'hxx; 
        endcase     
    end

	always @(counter_state) begin
        case(counter_state)
            // Upcounting states                      xxxxACODUMS
            STOP_FL1:           control_output = 11'bx00000010001;
            UP_F1_F2:           control_output = 11'bx00010100110;
            DOWN_F2_F1:         control_output = 11'bx00000101010;
            STOP_FL2:           control_output = 11'bx00010010001;
            UP_F2_F3:           control_output = 11'bx00100100110;
            DOWN_F3_F2:         control_output = 11'bx00010101010;
            STOP_FL3:           control_output = 11'bx00100010001;
            UP_F3_F4:           control_output = 11'bx00110100110;
            DOWN_F4_F3:         control_output = 11'bx00100101010;
            STOP_FL4:           control_output = 11'bx00110010001;
            UP_F4_F5:           control_output = 11'bx01000100110;
            DOWN_F5_F4:         control_output = 11'bx00110101010;
            STOP_FL5:           control_output = 11'bx01000010001;
            UP_F5_F6:           control_output = 11'bx01010100110;
            DOWN_F6_F5:         control_output = 11'bx01000101010;
            STOP_FL6:           control_output = 11'bx01010010001;
            UP_F6_F7:           control_output = 11'bx01100100110;
            DOWN_F7_F6:         control_output = 11'bx01010101010;
            STOP_FL7:           control_output = 11'bx01100010001;
            UP_F7_F8:           control_output = 11'bx01110100110;
            DOWN_F8_F7:         control_output = 11'bx01100101010;
            STOP_FL8:           control_output = 11'bx01110010001;
            UP_F8_F9:           control_output = 11'bx10000100110;
            DOWN_F9_F8:         control_output = 11'bx01110101010;
            STOP_FL9:           control_output = 11'bx10000010001;
            UP_F9_F10:          control_output = 11'bx10010100110;
            DOWN_F10_F9:        control_output = 11'bx10000101010;
            STOP_FL10:          control_output = 11'bx10010010001;
            UP_F10_F11:         control_output = 11'bx10100100110;
            DOWN_F11_F10:       control_output = 11'bx10010101010;
            STOP_FL11:          control_output = 11'bx10100010001;
            EMERGENCY:          control_output = 11'bx00001010001;  
            default:            control_output = 11'bxxxxxxxxxxxx;
        endcase
    end
endmodule



// Outputs:             xxxxACODUMS
// Safety Interlock = 0b00000000001
// Motor Enable     = 0b00000000010
// Elevator Up      = 0b00000000100
// Elevator Down    = 0b00000001000
// Door Open        = 0b00000010000
// Door Close       = 0b00000100000
// Alarm            = 0b00001000000
// Floor Indicator  = 0bxxxx0000000

// Inputs:
// Elevator Floor Selector                            0b00000xxxx
// Activate Elevator (1 bit)                          0b000010000
// Direction Selector (1 bit for up/down)             0b000100000
// Emergency Stop Button (1 bit)                      0b001000000
// Weight Sensor (1 bit for overload)                 0b010000000
// Power Switch (1 bit for on/off)                    0b100000000
