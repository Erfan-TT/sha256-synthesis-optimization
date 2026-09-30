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
source "./flows/clock_gating_multi_vt/synopsys_pt.setup"

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

# Multi-VT groups, needed for report_threshold_voltage_group
set_user_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT
set_user_attribute [find library CORE65LPSVT] default_threshold_voltage_group SVT
set_user_attribute [find library CORE65LPHVT] default_threshold_voltage_group HVT


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

report_threshold_voltage_group

## calculating the percentage of different VT cells

set gates [get_cells -hierarchical -filter "is_hierarchical == false"]

set lvt_gates ""
set svt_gates ""
set hvt_gates ""
set unclassified_gates ""

foreach_in_collection c $gates {
    set libcell [get_lib_cells -of_objects $c]
    set libcell_name [get_object_name $libcell]

    if {[regexp {CORE65LPLVT/} $libcell_name]} {
        set lvt_gates [add_to_collection $lvt_gates $c]
    } elseif {[regexp {CORE65LPSVT/} $libcell_name]} {
        set svt_gates [add_to_collection $svt_gates $c]
    } elseif {[regexp {CORE65LPHVT/} $libcell_name]} {
        set hvt_gates [add_to_collection $hvt_gates $c]
    } else {
        set unclassified_gates [add_to_collection $unclassified_gates $c] ## to check if all the gates are divided or not
    }
}

set total_gates [sizeof_collection $gates]
set num_lvt [sizeof_collection $lvt_gates]
set num_svt [sizeof_collection $svt_gates]
set num_hvt [sizeof_collection $hvt_gates]
set num_unclassified [sizeof_collection $unclassified_gates]

set pct_lvt [expr {100.0 * $num_lvt / $total_gates}]
set pct_svt [expr {100.0 * $num_svt / $total_gates}]
set pct_hvt [expr {100.0 * $num_hvt / $total_gates}]
set pct_unclassified [expr {100.0 * $num_unclassified / $total_gates}]


set corner [get_attribute [current_design] operating_condition_max]
set clockPeriod [get_attribute [get_clocks] period]
set wrt_slack [get_attribute [get_timing_paths] slack]
set area [get_attribute [current_design] area]
set dynamic [get_attribute [current_design] dynamic_power]
set leakage [get_attribute [current_design] leakage_power]


# ----------------------------------------------------------------------

# Report

# ----------------------------------------------------------------------



set report_string "\n==========================================================\n"

append report_string "                   FINAL MEASUREMENTS                 \n"

append report_string "==========================================================\n"

append report_string [format "Percentage of LVT cells : %2f \n" $pct_lvt]

append report_string [format "Percentage of SVT cells : %2f \n" $pct_svt]

append report_string [format "Percentage of HVT cells : %2f \n" $pct_hvt]

append report_string [format "Percentage of unclassified cells : %2f \n" $pct_unclassified]  ## which should be zero

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
report_power -verbose > power_verbose_ex2.2.rpt
report_power -hierarchy > power_hierarchy_ex2.2.rpt
report_power -cell_power > power_cell_ex2.2.rpt

exit
