##	+----------------------------------------------------------------
##	|		 Synthesis and Optimization of Digital Systems			|
##	|				Politecnico di Torino - TO - Italy				|
##	|						DAUIN - EDA GROUP						|
##	+----------------------------------------------------------------
##	|	author: Valentino Peluso									|
##	|	mail:	valentino.peluso@polito.it							|
##	|	title:	synthesis.tcl										|
##	+----------------------------------------------------------------
##	| 	Copyright 2026 DAUIN - EDA GROUP							|
##	+----------------------------------------------------------------

######################################################################
##
## SPECIFY LIBRARIES
##
######################################################################

# SOURCE SETUP FILE
source "./flows/clock_gating_multi_vt/synopsys_dc.setup"

# SUPPRESS WARNING MESSAGES
suppress_message MWLIBP-319
suppress_message MWLIBP-324
suppress_message TFCHK-012
suppress_message TFCHK-014
suppress_message TFCHK-049
suppress_message TFCHK-072
suppress_message TFCHK-084
suppress_message PSYN-651
suppress_message PSYN-650
suppress_message UID-401
suppress_message LINK-14
suppress_message TIM-134
suppress_message VER-130
suppress_message UISN-40
suppress_message VO-4
suppress_message RTDC-126

######################################################################
##
## READ DESIGN
##
######################################################################

# DEFINE CIRCUITS and WORK DIRS
set blockName sha256_core
set active_design $blockName

# DEFINE WORK DIRS
set dirname "./saved/${blockName}"
if {![file exists $dirname]} {
	file mkdir $dirname
}
set dirname "./saved/${blockName}/synthesis"
if {![file exists $dirname]} {
	file mkdir $dirname
}
set libDir "./saved/${blockName}/synthesis/synlib"
file mkdir $libDir
define_design_lib $blockName -path $libDir

# ANALYZE HDL SOURCES
set HdlFileList [glob -dir "./rtl/${blockName}/src" "*.*v*"]
foreach hdlFile $HdlFileList {
	if {[file extension $hdlFile]==".v"} {
		analyze -format verilog  -library $blockName $hdlFile
	} elseif {[file extension $hdlFile]==".vhd"} {
		analyze -format vhdl -library $blockName $hdlFile
    } elseif {[file extension $hdlFile]==".sv"} {
		analyze -format sverilog -library $blockName $hdlFile
    }
}

# ELABORATE DESIGN
elaborate -lib $blockName $blockName

######################################################################
##
## DEFINE DESIGN ENVIRONMENT
##
######################################################################
set_operating_condition -library  "CORE65LPLVT_nom_1.20V_25C.db:CORE65LPLVT" nom_1.20V_25C
set_wire_load_model -library "CORE65LPLVT_nom_1.20V_25C.db:CORE65LPLVT" -name area_18Kto24K [find design *]
set_load 0.05 [all_outputs]

######################################################################
##
## SET DESIGN CONSTRAINTS
##
######################################################################
source "./rtl/${blockName}/sdc/${blockName}.sdc"

######################################################################
##
## OPTIMIZE DESIGN
##
######################################################################
link
ungroup -all -flatten


## Multi-VT threshold group labels
set_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT -type string
set_attribute [find library CORE65LPSVT] default_threshold_voltage_group SVT -type string
set_attribute [find library CORE65LPHVT] default_threshold_voltage_group HVT -type string


## Clock gating settings
set clockGateMinBitWidth 8
set clockGateMaxFanout 32

set_clock_gating_style \
    -minimum_bitwidth $clockGateMinBitWidth \
    -max_fanout $clockGateMaxFanout

compile_ultra -gate_clock


set_dont_retime [all_fanout -from [get_pins -filter is_clock_gate_output_pin] -only_cells]

optimize_registers -clock $clockName -minimum_period_only
set_fix_hold $clockName
compile -incremental_mapping -map_effort high -ungroup_all
######################################################################
##
## SAVE DESIGN
##
######################################################################

write -format verilog -hierarchy -output "${dirname}/${blockName}_postsyn.v"
write_sdc "${dirname}/${blockName}_postsyn.sdc"

######################################################################
##
## POST-SYNTHESIS REPORTS FOR RESULT ANALYSIS
##
## These reports are generated after the final optimization step and
## before cleaning the temporary design library. They are used to compare
## the different synthesis experiments in terms of area, cell count,
## combinational/sequential structure, resource mapping, and clock-gating
## insertion. The reports provide supporting evidence for explaining the
## observed changes in area, dynamic power, and leakage power.
##
######################################################################

report_clock_gating
report_clock_gating -structure
report_clock_gating -enable_conditions

report_reference > reference_count_ex2.2.rpt
report_area > area_ex2.2.rpt
report_area -hierarchy > area_hierarchy_ex2.2.rpt
report_qor > qor_ex2.2.rpt
report_resources > resources_ex2.2.rpt

######################################################################
##
## CLEAN & EXIT
##
######################################################################

exec rm -rf $libDir
exit
