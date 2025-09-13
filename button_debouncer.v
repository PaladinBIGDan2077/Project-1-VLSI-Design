/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Button Press Debounce and Pulse Generator
// Filename:                        button_debouncer.v
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
// Description:                     Finite State Machine (FSM) that generates a single-clock-cycle
//                                  high pulse after an active-low button is pressed and released.
//                                  Provides clean signal debouncing and edge detection.
// 
// Modification History:  
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  9/7/2025    DJL  1        Original Code
/////////////////////////////////////////////////////////////////////////////////////////////////////////

module button_debouncer (clk, rst_n, btn_n_in, pulse_out);

    input                            clk;        // System clock
    input                            rst_n;      // Active-low asynchronous reset
    input                            btn_n_in;  // Active-low button input
    output                           pulse_out;   // Extended pulse output

    wire                             clk;        
    wire                             rst_n;      
    wire                             btn_n_in;  
    reg                              pulse_out;   

    // One-Hot State Encoding Parameters
    localparam [2:0] STATE_IDLE    = 3'b001;
    localparam [2:0] STATE_PRESSED = 3'b010;
    localparam [2:0] STATE_RELEASE = 3'b100;

    // State Registers
    reg [2:0] current_state, next_state;
    reg [7:0] pulse_counter; // Counter for pulse duration
    reg       pulse_trigger; // Internal trigger signal
    
    parameter PULSE_CYCLES = 1; // Number of clock cycles to keep pulse high

    // Sequential Logic: State Register with Asynchronous Reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            pulse_counter <= 8'b0;
            pulse_out <= 1'b0;
        end 
        else begin
            current_state <= next_state;
            
            // Pulse counter logic
            if (pulse_trigger) begin
                pulse_out <= 1'b1;
                pulse_counter <= PULSE_CYCLES;
            end 
            else if (pulse_counter > 0) begin
                pulse_counter <= pulse_counter - 1;
            end 
            else begin
                pulse_out <= 1'b0;
            end
        end
    end

    // Combinational Logic: Next State and Output Logic
    always @(*) begin
        // Default assignments
        next_state = current_state;
        pulse_trigger = 1'b0;

        case (current_state)
            STATE_IDLE: begin
                if (!btn_n_in) begin             // Button is pressed
                    next_state = STATE_PRESSED;
                end
            end

            STATE_PRESSED: begin
                if (btn_n_in) begin              // Button is released
                    next_state = STATE_RELEASE;
                end
            end

            STATE_RELEASE: begin
                pulse_trigger = 1'b1;           // Trigger the pulse
                next_state = STATE_IDLE;
            end

            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

endmodule