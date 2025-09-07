/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Clock Multiplier
// Filename:                        clk_multiplier.v
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
// Description:                     Simple clock generator module that produces a multiplied varient of the clk_in clock signal,
//                                  with adjustable scale, when enabled. Default frequency is 10 Hz.
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/7/2025    DJL  1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns
module clk_divider(clk_in, enable, clock_slow_output);
    input                   clk_in;           // Input clock (not used in this version)
    input                   enable;           // Enable signal
    output                  clock_slow_output;
    reg                     clock_slow_output; // 100ms period output clock

    parameter FREQUENCY = 100000000; // Clock period in nanoseconds (100ms)

    initial begin
        clock_slow_output = 0;
    end

    // Toggle the clock every 50ms (half of 100ms period) if enabled
    always(posedge clk_in) begin
        #(FREQUENCY/2); // 50ms delay (half of 100ms period)
        if (enable) begin
            clock_slow_output = ~clock_slow_output;
        end
    end

endmodule