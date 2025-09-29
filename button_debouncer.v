/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Button Press Debounce and Pulse Generator
// Filename:                        button_debouncer.v
// Version:                         1
// Author:                          Sammy Craypoff
// Date:                            9/7/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Doctor Jeffrey Walling 
//  
// Hardware Description Language:   Verilog 2001 (IEEE 1364-2001)  
// Simulation Tool:                 ModelSim: Intel FPGA Starter Edition 21.1 
// 
// Description:                     Finite State Machine (FSM) that generates a single-clock-cycle
//                                  high pulse after an active-low button is pressed and released.
//                                  Provides clean signal debouncing and edge detection.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/7/2025    SC   1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module button_debouncer(clock, reset_n, key_in, enable_out);
    input                                           clock;
    input                                           reset_n;    
    input                                           key_in;
	output                                          enable_out;

	reg                     [1:0]                   key_current_state;
    reg                     [1:0]                   key_next_state;
	reg                                             enable_out;

	parameter UNPRESSED = 2'b00, 
              PRESSED = 2'b01, 
              RELEASED = 2'b10;

always@(posedge clock, negedge reset_n) begin
    if(reset_n == 1'b0)
        key_current_state <= UNPRESSED;
    else
        key_current_state <= key_next_state;
end 

always@(key_current_state, key_in) begin
    case(key_current_state)
        UNPRESSED: begin
            if(key_in == 1'b0)
                key_next_state = PRESSED;
            else
                key_next_state = UNPRESSED;
        end
        PRESSED: begin
            if(key_in == 1'b1)
                key_next_state = RELEASED;
            else
                key_next_state = PRESSED;
        end
        RELEASED: begin
            key_next_state = UNPRESSED;
        end
        default: key_next_state = 2'bxx;
    endcase
end 

always@(key_current_state) begin
    case(key_current_state)
        UNPRESSED: enable_out = 1'b0;
        PRESSED:   enable_out = 1'b0;
        RELEASED:  enable_out = 1'b1;
    default:       enable_out = 1'bx;
    endcase
end 
	
endmodule
