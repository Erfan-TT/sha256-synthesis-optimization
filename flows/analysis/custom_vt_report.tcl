##   custom_vt_report max
##   custom_vt_report min

## Return the VT group of a cell based on its reference name

proc get_vt_group_from_cell {cell} {

    set libcell [get_lib_cells -quiet -of_objects $cell]

    if {[sizeof_collection $libcell] == 0} {
        return "UNKNOWN"
    }

    set libcell_name [get_object_name $libcell]

    if {[regexp {CORE65LPLVT/} $libcell_name]} {
        return "LVT"
    } elseif {[regexp {CORE65LPSVT/} $libcell_name]} {
        return "SVT"
    } elseif {[regexp {CORE65LPHVT/} $libcell_name]} {
        return "HVT"
    } else {
        return "UNKNOWN"
    }
}

## Count LVT/SVT/HVT cells in one timing path

proc count_vt_cells_in_timing_path {path} {

    set lvt_count 0
    set svt_count 0
    set hvt_count 0

    # Avoid double-counting the same cell if both input and output pins
    # of that cell appear in the timing path.
    array set visited_cells {}

    set points [get_attribute $path points]

    foreach_in_collection timing_point $points {

        set point_object [get_attribute $timing_point object]

        # If point_object is a pin, this returns the parent cell.
        # If point_object is a port, this returns an empty collection.
        set cell [get_cells -quiet -of_objects $point_object]

        if {[sizeof_collection $cell] == 0} {
            continue
        }

        set cell_name [get_object_name $cell]

        if {[info exists visited_cells($cell_name)]} {
            continue
        }

        set visited_cells($cell_name) 1

        set vt_group [get_vt_group_from_cell $cell]

        if {$vt_group == "LVT"} {
            incr lvt_count
        } elseif {$vt_group == "SVT"} {
            incr svt_count
        } elseif {$vt_group == "HVT"} {
            incr hvt_count
        }
    }

    return [list $lvt_count $svt_count $hvt_count]
}

## Helper procedure: print to command line and append to file
proc puts_both {fp line} {
    puts $line
    puts $fp $line
}


######################################################################
## Main custom report procedure
##
## Required input:
##   delay_type = min or max
######################################################################

proc custom_vt_report {delay_type} {

    ## Input validation
    if {$delay_type != "min" && $delay_type != "max"} {
        puts "ERROR: delay_type must be either 'min' or 'max'."
        puts "Usage:"
        puts "  custom_vt_report max"
        puts "  custom_vt_report min"
        return
    }


    set report_file "custom_vt_report_$delay_type.rpt"
    set fp [open $report_file "a"]


    ## Get all timing endpoints

    set endpoints [add_to_collection [all_registers -data_pins] [all_outputs]]
    set num_endpoints [sizeof_collection $endpoints]

    set report_data [list]
    set skipped_endpoints 0


    ## For each endpoint, get exactly one critical path ending there ########################

    foreach_in_collection endpoint $endpoints {

        set endpoint_name [get_object_name $endpoint]

        set path [get_timing_paths \
            -delay_type $delay_type \
            -to $endpoint \
            -nworst 1 \
            -max_paths 1 \
            -slack_lesser_than 1000]

        if {[sizeof_collection $path] == 0} {
            incr skipped_endpoints
            continue
        }

        set slack [get_attribute $path slack]

        set vt_counts [count_vt_cells_in_timing_path $path]
        set lvt_count [lindex $vt_counts 0]
        set svt_count [lindex $vt_counts 1]
        set hvt_count [lindex $vt_counts 2]

        lappend report_data [list $endpoint_name $slack $lvt_count $svt_count $hvt_count]
    }


    ## Sort rows by number of LVT cells in descending order ########################

    set sorted_data [lsort -integer -decreasing -index 2 $report_data]

    ## Print to command line and append to .rpt file ########################

    puts_both $fp ""
    puts_both $fp "================================================================================================================"
    puts_both $fp " Endpoint-based Multi-VT Critical-Path Report"
    puts_both $fp " Delay type: $delay_type"
    puts_both $fp "================================================================================================================"
    puts_both $fp [format "%-35s : %d" "Total endpoints found" $num_endpoints]
    puts_both $fp [format "%-35s : %d" "Reported endpoint paths" [llength $sorted_data]]
    puts_both $fp [format "%-35s : %d" "Skipped endpoints without path" $skipped_endpoints]
    puts_both $fp "================================================================================================================"
    puts_both $fp [format "%-80s %15s %10s %10s %10s" \
        "ENDPOINT" "SLACK(ns)" "NUM_LVT" "NUM_SVT" "NUM_HVT"]
    puts_both $fp "----------------------------------------------------------------------------------------------------------------"

    foreach row $sorted_data {

        set ep  [lindex $row 0]
        set sl  [lindex $row 1]
        set lvt [lindex $row 2]
        set svt [lindex $row 3]
        set hvt [lindex $row 4]

        puts_both $fp [format "%-80s %15.6f %10d %10d %10d" \
            $ep $sl $lvt $svt $hvt]
    }

    puts_both $fp "----------------------------------------------------------------------------------------------------------------"
    puts_both $fp "Critical-path Multi-VT analysis completed."
    puts_both $fp "Report appended to: $report_file"
    puts_both $fp "================================================================================================================"

    close $fp
}
