/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator State Machine for Multi-Cycle Datapath
// Filename:                        elevator_fsm.v
// Version:                         1
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            5/5/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Dcotor Jason Walling 
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
//                                  5/5/2025    DJL  1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module elevator_fsm(clock, init, operation_code, execute, control_output);
    input                                                     clock;     
	input                                                     init; // Active-low reset (KEY[1])
    input                       [3:0]                         operation_code;    
    input                                                     execute; 
	output                      [7:0]                         control_output;      // (SaveOpCode, LoadRegA, LoadRegB, LoadReg_B_4bit, DisplayRegisterResult, ActivateMultipler, ShiftMultiplier, MultiplierDone) control signals for counter unit

	reg                         [3:0]                         counter_state;
    reg                         [3:0]                         next_counter_state;
    reg                         [7:0]                         control_output;      // (SaveOpCode, LoadRegA, LoadRegB, LoadReg_B_4bit, DisplayRegisterResult, ActivateMultipler, ShiftMultiplier, MultiplierDone) control signals for counter unit
    reg                         [3:0]                         current_op;          // Operation code register

    parameter                   IDLE                          = 4'h0,      
                                OPCODE_DECODE                 = 4'h1,      
                                LOAD_REG_A                    = 4'h2,     
                                LOAD_REG_B                    = 4'h3,
                                LOAD_REG_B_4BIT               = 4'h4, // Used for 4-bit operations involing shifts
                                DISPLAY_ANSWER                = 4'h5,
                                EXECUTE_MULTIPLY              = 4'h6, 
                                SHIFT_MULTIPLY_1              = 4'h7,
                                SHIFT_MULTIPLY_2              = 4'h8,      
                                SHIFT_MULTIPLY_3              = 4'h9,
                                SHIFT_MULTIPLY_4              = 4'hA, 
                                SHIFT_MULTIPLY_5              = 4'hB,
                                SHIFT_MULTIPLY_6              = 4'hC,
                                SHIFT_MULTIPLY_7              = 4'hD,
                                MULTIPLY_DONE                 = 4'hE;         
	
    // Operation code register
    always @(posedge clock or negedge init) begin
        if (!init) begin
            current_op <= 4'h0;
        end 
        else if (control_output[7]) begin
            current_op <= operation_code;
        end
    end

	always @(posedge clock or negedge init) begin
		if (!init) begin
			counter_state <= IDLE; // Reset to initial state
        end
		else begin
            counter_state <= next_counter_state; // Update state to next state
        end
    end

    always @(*) begin
        case(counter_state)
            IDLE:   next_counter_state = (execute) ? OPCODE_DECODE : IDLE;
            OPCODE_DECODE:    next_counter_state = (execute) ? LOAD_REG_A : OPCODE_DECODE;
            LOAD_REG_A:        next_counter_state = (execute) ? LOAD_REG_B : LOAD_REG_A;
            LOAD_REG_B_4BIT:  next_counter_state = (execute) ? DISPLAY_ANSWER   : LOAD_REG_B_4BIT;
            DISPLAY_ANSWER:   next_counter_state = (execute) ? IDLE             :  DISPLAY_ANSWER;
            EXECUTE_MULTIPLY: next_counter_state = (execute) ? SHIFT_MULTIPLY_1 :  EXECUTE_MULTIPLY;
            SHIFT_MULTIPLY_1: next_counter_state = (execute) ? SHIFT_MULTIPLY_2 :  SHIFT_MULTIPLY_1;
            SHIFT_MULTIPLY_2: next_counter_state = (execute) ? SHIFT_MULTIPLY_3 :  SHIFT_MULTIPLY_2;
            SHIFT_MULTIPLY_3: next_counter_state = (execute) ? SHIFT_MULTIPLY_4 :  SHIFT_MULTIPLY_3;
            SHIFT_MULTIPLY_4: next_counter_state = (execute) ? SHIFT_MULTIPLY_5 :  SHIFT_MULTIPLY_4;
            SHIFT_MULTIPLY_5: next_counter_state = (execute) ? SHIFT_MULTIPLY_6 :  SHIFT_MULTIPLY_5;
            SHIFT_MULTIPLY_6: next_counter_state = (execute) ? SHIFT_MULTIPLY_7 :  SHIFT_MULTIPLY_6;
            SHIFT_MULTIPLY_7: next_counter_state = (execute) ? MULTIPLY_DONE    :  SHIFT_MULTIPLY_7;
            MULTIPLY_DONE:    next_counter_state = (execute) ? DISPLAY_ANSWER   :  MULTIPLY_DONE;
            default:          next_counter_state = 4'hx; 
        endcase
    end

	always @(counter_state) begin
        case(counter_state)
            // Upcounting states
            IDLE:               control_output = 8'b00000000; 
            OPCODE_DECODE:      control_output = 8'b10000000; 
            LOAD_REG_A:         control_output = 8'b01000000; 
            LOAD_REG_B:         control_output = 8'b00100000; 
            LOAD_REG_B_4BIT:    control_output = 8'b00010000;
            DISPLAY_ANSWER:     control_output = 8'b00001000;
            EXECUTE_MULTIPLY:   control_output = 8'b00000100; 
            SHIFT_MULTIPLY_1:   control_output = 8'b00000010; 
            SHIFT_MULTIPLY_2:   control_output = 8'b00000010; 
            SHIFT_MULTIPLY_3:   control_output = 8'b00000010;
            SHIFT_MULTIPLY_4:   control_output = 8'b00000010;
            SHIFT_MULTIPLY_5:   control_output = 8'b00000010;
            SHIFT_MULTIPLY_6:   control_output = 8'b00000010;
            SHIFT_MULTIPLY_7:   control_output = 8'b00000010;
            MULTIPLY_DONE:      control_output = 8'b00000001; 
            default:            control_output = 8'bxxxxxxxx;
        endcase
    end
endmodule
Outputs:
Safety Interlock = 0b0000000001
Motor Enable     = 0b0000000010
Elevator Up      = 0b0000000100
Elevator Down    = 0b0000001000
Door Open        = 0b0000010000
Door Close       = 0b0000100000
Alarm            = 0b0001000000
Floor Indicator  = 0bxxx0000000

Inputs:
Floor Request Buttons inside (3 bits for 8 floors) 0b00000000xxx
Elevator Call Button outside (3 bit for 8 floors)  0b00000xxx000
Emergency Stop Button (1 bit)                      0b00001000000
Door Close Button                                  0b00010000000
Door Open Button                                   0b00100000000
Weight Sensor (1 bit for overload)                 0b01000000000
Power Switch (1 bit for on/off)                    0b10000000000



