onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /elevator_top_tb/reset_n
add wave -noupdate /elevator_top_tb/raw_floor_call_buttons
add wave -noupdate /elevator_top_tb/raw_panel_buttons
add wave -noupdate /elevator_top_tb/call_button_lights
add wave -noupdate /elevator_top_tb/panel_button_lights
add wave -noupdate /elevator_top_tb/raw_door_open_btn
add wave -noupdate /elevator_top_tb/raw_door_close_btn
add wave -noupdate /elevator_top_tb/raw_emergency_btn
add wave -noupdate /elevator_top_tb/raw_power_switch
add wave -noupdate /elevator_top_tb/weight_sensor
add wave -noupdate /elevator_top_tb/elevator_control_output
add wave -noupdate -radix binary /elevator_top_tb/door_open
add wave -noupdate -radix unsigned /elevator_top_tb/floor_indicator_lamps
add wave -noupdate -radix binary /elevator_top_tb/safety_interlock
add wave -noupdate -radix binary /elevator_top_tb/elevator_upward_indicator_lamp
add wave -noupdate -radix binary /elevator_top_tb/elevator_downward_indicator_lamp
add wave -noupdate -radix binary /elevator_top_tb/alarm
add wave -noupdate -radix binary /elevator_top_tb/weight_overload_lamp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22004 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 232
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
WaveRestoreZoom {18649 ns} {22545 ns}
