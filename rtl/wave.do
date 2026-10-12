onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {System Controls}
add wave -noupdate /tb_moving_average/clk
add wave -noupdate /tb_moving_average/rst

add wave -noupdate -divider {Inputs}
add wave -noupdate /tb_moving_average/valid_in
add wave -noupdate -radix decimal -format Analog-Step -height 74 -max 127.0 -min -128.0 /tb_moving_average/x

add wave -noupdate -divider {Refreshed Filter (Shadow)}
add wave -noupdate /tb_moving_average/ready_out_ref
add wave -noupdate /tb_moving_average/valid_out_ref
add wave -noupdate -radix decimal -format Analog-Step -height 74 -max 127.0 -min -128.0 /tb_moving_average/y_ref

add wave -noupdate -divider {Non-Recursive Filter (Baseline)}
add wave -noupdate /tb_moving_average/valid_out_non_rec
add wave -noupdate -radix decimal -format Analog-Step -height 74 -max 127.0 -min -128.0 /tb_moving_average/y_non_rec

add wave -noupdate -divider {Datapath Debug (Internal)}
add wave -noupdate -radix decimal /tb_moving_average/uut_refreshed/running_sum
add wave -noupdate -radix decimal /tb_moving_average/uut_refreshed/shadow_sum
add wave -noupdate -radix unsigned /tb_moving_average/uut_refreshed/timer
add wave -noupdate -radix decimal /tb_moving_average/uut_non_rec/tree_sum

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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