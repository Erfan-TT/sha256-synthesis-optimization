set clockName clk
set rstName reset_n
set clockPeriod 20

;# Set-up Clock
create_clock -period $clockPeriod $clockName
set_clock_uncertainty 0.05 $clockName
set_clock_transition 0.05 $clockName
set_clock_latency 0.05 $clockName
set_dont_touch_network $clockName
set_ideal_network $clockName
set_dont_touch_network $rstName
set_ideal_network $rstName

;# fix hold constraints
set_min_delay 0.20 -from [all_inputs] -to [all_outputs]

;# Set-up IOs
set_driving_cell -library "CORE65LPLVT_nom_1.20V_25C.db:CORE65LPLVT" -lib_cell "HS65_LL_BFX7" [all_inputs]

set_input_delay 0.25 -clock $clockName [all_inputs]
set_output_delay 0.15 -clock $clockName [all_outputs]
set_input_delay 0 -clock clk clk

set max_transition_time 0.1
set_max_transition $max_transition_time [all_outputs]

;# Set area constraint
set_max_area 0