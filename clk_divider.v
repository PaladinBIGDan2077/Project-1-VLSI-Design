/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Clock Divider
// Filename:                        clk_divider.v
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
module clk_divider(clk_in, reset_n, enable, clock_slow_output);
    input                   clk_in;           // Input clock (not used in this version)
    input                   reset_n;        
    input                   enable;           // Enable signal
    output                  clock_slow_output;
    reg                                     clock_slow_output; // 100ms period output clock

    parameter                           DIVISION_RATIO = 50;   // Creates 1us period clock from 100MHz input

    reg             [7:0]               counter;               // 8-bit counter (up to 255 division)

    initial begin
        clock_slow_output = 0;
        counter = 0;
    end

    // Clock division logic
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            clock_slow_output <= 0;
            counter <= 0;
        end 
        else if (enable) begin
            if (counter >= DIVISION_RATIO - 1) begin
                clock_slow_output <= ~clock_slow_output;
                counter <= 0;
            end 
            else begin
                counter <= counter + 1;
            end
        end 
        else begin
            // Optional: hold current state when disabled
            counter <= counter;
            clock_slow_output <= clock_slow_output;
        end
    end

endmodule