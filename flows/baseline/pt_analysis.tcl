##	+----------------------------------------------------------------
##	|		 Synthesis and Optimization of Digital Systems			|
##	|				Politecnico di Torino - TO - Italy				|
##	|						DAUIN - EDA GROUP						|
##	+----------------------------------------------------------------
##	|	author: Valentino Peluso									|
##	|	mail:	valentino.peluso@polito.it							|
##	|	title:	pt_analysis.tcl										|
##	+----------------------------------------------------------------
##	| 	Copyright 2026 DAUIN - EDA GROUP							|
##	+----------------------------------------------------------------

######################################################################
##
## SPECIFY LIBRARIES
##
######################################################################

# SOURCE SETUP FILE
source "./flows/baseline/synopsys_pt.setup"

# DEFINE OPTIONS
set report_default_significant_digits 6
set power_enable_analysis true

# SUPPRESS WARNING MESSAGES
suppress_message RC-004
suppress_message PTE-003
suppress_message UID-401
suppress_message ENV-003
suppress_message UITE-489
suppress_message CMD-041
suppress_message PLIB-166
suppress_message PLIB-167
suppress_message PTE-139
suppress_message NED-045
######################################################################
##
## READ DESIGN
##
######################################################################
# DEFINE CIRCUITS
set blockName sha256_core

# DEFINE INPUT FILES
set dir "./saved/${blockName}/synthesis"
set in_verilog_filename "${dir}/${blockName}_postsyn.v"
set in_sdc_filename "${dir}/${blockName}_postsyn.sdc"

# READ
read_verilog $in_verilog_filename
link_design $blockName
read_sdc $in_sdc_filename

set_ideal_network clk
set_ideal_network reset_n


update_timing -full

######################################################################
##
## TIMING ANALYSIS
##
######################################################################
# SETUP TIME
report_timing -delay_type max

# SLACK CONDITION
report_timing -delay_type min -slack_lesser_than 0.1 -max_paths 2
report_timing -delay_type max -slack_lesser_than 0.0 -max_paths 2

######################################################################
##
## POWER ANALYSIS
##
######################################################################
set_user_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT

read_vcd ./saved/sha256_core/simulation/sha256_core.vcd \
    -strip_path /tb_sha256_core/dut \
    -zero_delay

#clock scaling
set_power_clock_scaling -period 2 [get_clocks]
set power_enable_clock_scaling true

#calculate the power
update_power

#report power
report_power


set corner [get_attribute [current_design] operating_condition_max]
set clockPeriod [get_attribute [get_clocks] period]
set wrt_slack [get_attribute [get_timing_paths] slack]
set area [get_attribute [current_design] area]
set dynamic [get_attribute [current_design] dynamic_power]
set leakage [get_attribute [current_design] leakage_power]

set fp [open "${blockName}.csv" "a"]
puts $fp [format "${corner},%.1f,%.3f,%.3f,%.3e,%.3e" $clockPeriod $wrt_slack $area $dynamic $leakage]
close $fp

# ----------------------------------------------------------------------

# Report

# ----------------------------------------------------------------------



set report_string "\n==========================================================\n"

append report_string "                   FINAL MEASUREMENTS                 \n"

append report_string "==========================================================\n"

append report_string [format "%-25s : %s\n" "Operating Corner" $corner]

append report_string [format "%-25s : %.2f ns\n" "Clock Period" $clockPeriod]

append report_string [format "%-25s : %.6f ns\n" "Timing Slack" $wrt_slack]

append report_string [format "%-25s : %.2f um^2\n" "Total Area" $area]

append report_string [format "%-25s : %.3e mW\n" "Dynamic Power" $dynamic]

append report_string [format "%-25s : %.3e mW\n" "Leakage Power" $leakage]

append report_string "==========================================================\n"



puts $report_string



set fp [open "${blockName}_metrics.rpt" "a"]

puts $fp $report_string

close $fp

## to check with the other parts of the project, figuring out why the dynamic and static power changed in this way
report_power -verbose > power_verbose_ex1.rpt
report_power -hierarchy > power_hierarchy_ex1.rpt
report_power -cell_power > power_cell_ex1.rpt

exit
