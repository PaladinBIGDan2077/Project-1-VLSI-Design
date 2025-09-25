/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Clock Generator
// Filename:                        clk.v
// Version:                         1
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/7/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4540 - VLSI Circuit Design
// Instructor:                      Doctor Jeffrey Walling 
//  
// Hardware Description Language:   Verilog 2001 (IEEE 1364-2001)  
// Simulation Tool:                 iVerilog 12.0
// 
// Description:                     Simple clock generator module that produces a clock signal,
//                                  with adjustable frequency, when enabled. Default frequency is 25 MHz.
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/7/2025    DJL  1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns
module clk(enable, clock_output);
    input                enable;		        
    output               clock_output;		
    reg                  clock_output;

    initial clock_output = 0; // Initial value of the clock

    // Toggle the clock every half period if enabled
    always begin
        #40; 
        clock_output = enable ? ~clock_output : clock_output;
    end
endmodule