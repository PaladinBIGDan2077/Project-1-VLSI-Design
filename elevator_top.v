/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Elevator System Top Module (fixed)
// Filename:                        elevator_top.v
// Version:                         1.1
// Author:                          Daniel J. Lomis, Sammy Craypoff
// Date:                            9/13/2025  (patched)
// ...
/////////////////////////////////////////////////////////////////////////////////////////////////////////

module elevator_top(
    input  wire                 clock,
    input  wire                 reset_n,
    input  wire  [10:0]         raw_floor_call_buttons,
    input  wire  [10:0]         raw_panel_buttons,
    input  wire                 raw_door_open_btn,
    input  wire                 raw_door_close_btn,
    input  wire                 raw_emergency_btn,
    input  wire                 raw_power_switch,
    input  wire                 weight_sensor,

    output wire  [10:0]         call_button_lights,
    output wire  [10:0]         panel_button_lights,
    output wire                 door_open,
    output wire  [10:0]         elevator_control_output, // [10:0] per FSM
    output wire  [3:0]          floor_indicator_lamps,
    output wire                 safety_interlock,
    output wire                 elevator_upward_indicator_lamp,
    output wire                 elevator_downward_indicator_lamp,
    output wire                 weight_overload_lamp,
    output wire                 alarm
);

    // Internal, explicit wires
    wire  [10:0] floor_call_buttons;
    wire  [10:0] panel_buttons;
    wire          door_open_btn;
    wire          door_close_btn;
    wire          emergency_btn;
    wire          power_switch = raw_power_switch; // pass-through
    wire  [5:0]   elevator_state;       // MATCH width to elevator_fsm (6 bits)
    wire          elevator_movement;    // derived from control output
    wire          elevator_direction;   // derived from control output
    wire  [3:0]   current_floor_state;  // derived below
    wire          door_open_logic_check;
    wire          door_close_logic_check;

    // ------------------------------------------------------------------
    // Debouncers (testbench / sim) - instantiations kept as-is but note:
    // These modules must be synthesizable or excluded from synthesis.
    // ------------------------------------------------------------------
    // floor call debouncers
    button_debouncer floor_call_debouncer0  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[0]),  .pulse_out(floor_call_buttons[0]));
    button_debouncer floor_call_debouncer1  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[1]),  .pulse_out(floor_call_buttons[1]));
    button_debouncer floor_call_debouncer2  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[2]),  .pulse_out(floor_call_buttons[2]));
    button_debouncer floor_call_debouncer3  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[3]),  .pulse_out(floor_call_buttons[3]));
    button_debouncer floor_call_debouncer4  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[4]),  .pulse_out(floor_call_buttons[4]));
    button_debouncer floor_call_debouncer5  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[5]),  .pulse_out(floor_call_buttons[5]));
    button_debouncer floor_call_debouncer6  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[6]),  .pulse_out(floor_call_buttons[6]));
    button_debouncer floor_call_debouncer7  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[7]),  .pulse_out(floor_call_buttons[7]));
    button_debouncer floor_call_debouncer8  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[8]),  .pulse_out(floor_call_buttons[8]));
    button_debouncer floor_call_debouncer9  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[9]),  .pulse_out(floor_call_buttons[9]));
    button_debouncer floor_call_debouncer10 (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_floor_call_buttons[10]), .pulse_out(floor_call_buttons[10]));

    // panel debouncers
    button_debouncer panel_debouncer0  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[0]),  .pulse_out(panel_buttons[0]));
    button_debouncer panel_debouncer1  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[1]),  .pulse_out(panel_buttons[1]));
    button_debouncer panel_debouncer2  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[2]),  .pulse_out(panel_buttons[2]));
    button_debouncer panel_debouncer3  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[3]),  .pulse_out(panel_buttons[3]));
    button_debouncer panel_debouncer4  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[4]),  .pulse_out(panel_buttons[4]));
    button_debouncer panel_debouncer5  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[5]),  .pulse_out(panel_buttons[5]));
    button_debouncer panel_debouncer6  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[6]),  .pulse_out(panel_buttons[6]));
    button_debouncer panel_debouncer7  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[7]),  .pulse_out(panel_buttons[7]));
    button_debouncer panel_debouncer8  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[8]),  .pulse_out(panel_buttons[8]));
    button_debouncer panel_debouncer9  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[9]),  .pulse_out(panel_buttons[9]));
    button_debouncer panel_debouncer10 (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_panel_buttons[10]), .pulse_out(panel_buttons[10]));

    // control debouncers
    button_debouncer door_open_debouncer  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_door_open_btn),  .pulse_out(door_open_btn));
    button_debouncer door_close_debouncer (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_door_close_btn), .pulse_out(door_close_btn));
    button_debouncer emergency_debouncer  (.clk(clock), .rst_n(reset_n), .btn_n_in(~raw_emergency_btn),   .pulse_out(emergency_btn));

    // ------------------------------------------------------------------
    // Elevator FSM instantiation (use named mapping)
    // ------------------------------------------------------------------
    // elevator_fsm outputs: counter_state (6 bits) and control_output (11 bits)
    elevator_fsm elevator_fsm_inst (
        .clock(clock),
        .reset_n(reset_n),
        .elevator_floor_selector(elevator_floor_selector), // from floor logic
        .emergency_stop(emergency_btn),
        .activate_elevator(activate_elevator),
        .weight_sensor(weight_sensor),
        .power_switch(power_switch),
        .direction_selector(direction_selector),
        .counter_state(elevator_state),               // 6-bit state out
        .control_output(elevator_control_output)      // 11-bit control out
    );

    // Derive signals from elevator control output
    assign safety_interlock                    = elevator_control_output[0];
    assign elevator_movement                   = elevator_control_output[1];
    assign elevator_direction                  = elevator_control_output[2];
    assign elevator_upward_indicator_lamp      = elevator_control_output[2];
    assign elevator_downward_indicator_lamp    = elevator_control_output[3];
    assign alarm                               = elevator_control_output[6];
    assign floor_indicator_lamps               = elevator_control_output[10:7]; // 4 bits
    assign weight_overload_lamp                = weight_sensor;

    // expose current_floor_state to floor logic (derived from floor_indicator_lamps)
    assign current_floor_state = floor_indicator_lamps;

    // ------------------------------------------------------------------
    // Floor logic controller:
    // Use named-port mapping so ports are not mixed up
    // ------------------------------------------------------------------
    floor_logic_control_unit floor_logic_inst (
        .clock(clock),
        .reset_n(reset_n),
        .floor_call_buttons(floor_call_buttons),
        .panel_buttons(panel_buttons),
        .door_open_btn(door_open_btn),
        .door_close_btn(door_close_btn),
        .emergency_btn(emergency_btn),
        .power_switch(power_switch),
        .current_floor_state(current_floor_state),      // 4-bit
        .elevator_state(elevator_state),                // 6-bit
        .elevator_moving(elevator_movement),
        .elevator_direction(elevator_direction),
        .elevator_floor_selector(elevator_floor_selector), // output to FSM
        .direction_selector(direction_selector),
        .activate_elevator(activate_elevator),
        .call_button_lights(call_button_lights),
        .panel_button_lights(panel_button_lights),
        .door_open_allowed(door_open_logic_check),
        .door_close_allowed(door_close_logic_check)
    );

    // Door control logic with button override
    assign door_open  = door_open_logic_check ? 1'b1 : (door_close_logic_check ? 1'b0 : elevator_control_output[4]);
    assign door_close = door_close_logic_check ? 1'b1 : elevator_control_output[5];

endmodule
