onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /elevator_top_tb/door_open_light
add wave -noupdate /elevator_top_tb/door_close_light
add wave -noupdate /elevator_top_tb/elevator_control_output
add wave -noupdate /elevator_top_tb/current_state_display
add wave -noupdate /elevator_top_tb/current_floor_display
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/clock
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/reset_n
add wave -noupdate -radix decimal -childformat {{{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[10]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[9]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[8]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[7]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[6]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[5]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[4]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[3]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[2]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[1]} -radix decimal} {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[0]} -radix decimal}} -subitemconfig {{/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[10]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[9]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[8]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[7]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[6]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[5]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[4]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[3]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[2]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[1]} {-height 15 -radix decimal} {/elevator_top_tb/dut/floor_logic_inst/floor_call_buttons[0]} {-height 15 -radix decimal}} /elevator_top_tb/dut/floor_logic_inst/floor_call_buttons
add wave -noupdate -radix decimal /elevator_top_tb/dut/floor_logic_inst/panel_buttons
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/door_open_btn
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/door_close_btn
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/emergency_btn
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/power_switch
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/current_floor_state
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/elevator_state
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/elevator_moving
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/elevator_direction
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/elevator_floor_selector
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/direction_selector
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/activate_elevator
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/power_switch_override
add wave -noupdate -radix decimal /elevator_top_tb/dut/floor_logic_inst/call_button_lights
add wave -noupdate -radix decimal /elevator_top_tb/dut/floor_logic_inst/panel_button_lights
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/door_open_light
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/door_close_light
add wave -noupdate -radix decimal /elevator_top_tb/dut/floor_logic_inst/up_requests
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/down_requests
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/panel_requests
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/power_switch_active
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/nearest_floor
add wave -noupdate /elevator_top_tb/dut/floor_logic_inst/power_switch_trigger
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/elevator_floor_selector
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/emergency_stop
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/activate_elevator
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/weight_sensor
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/power_switch
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/direction_selector
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/control_output
add wave -noupdate -radix hexadecimal /elevator_top_tb/dut/elevator_fsm_inst/counter_state
add wave -noupdate /elevator_top_tb/dut/elevator_fsm_inst/next_counter_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 377
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1122 ns}
