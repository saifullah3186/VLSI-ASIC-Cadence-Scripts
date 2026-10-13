#========================================================================
# GENUS FLOW - for Genus 16.23-s049_1 (built 2017)
# All files (RTL, .lib, .sdc) sit in ONE folder - no path variables.
# No DFT/scan (handled separately in Tessent).
#
# COMMAND SAFETY NOTE
#   Section 8 (core flow) uses only commands/attributes that have existed
#   since the earliest Common-UI Genus releases (set_db/get_db,
#   syn_generic/syn_map/syn_opt, lp_insert_clock_gating, dont_use,
#   basic reports). These should work as-is on 16.23.
#
#   Section 9 (bonus attributes) contains newer commands I am NOT certain
#   existed in 2017. Each is wrapped in safe_set_db/safe_run, so if one
#   is unknown to your build you'll see a line like:
#       WARNING(safe): could not set '...' -> ... (skipped)
#   in the log, and the run continues normally. Search the log for
#   "WARNING(safe)" after every run to see exactly what your build
#   does and doesn't support - that list is your real answer, more
#   reliable than any doc I can quote for a 2017 release.
#
# SWITCHES (environment variables, all optional)
#   LOW_POWER=1     turn on clock gating                  (default 0)
#   HIGH_EFFORT=1   high effort synthesis                 (default 1)
#   RUN_TAG=name    tag for report/output file names       (default base/lp)
#
# EXAMPLES
#   genus -f genus_2017_flow.tcl -log base.log
#   LOW_POWER=1 genus -f genus_2017_flow.tcl -log lp.log
#========================================================================

#------------------------------------------------------------------------
# 0. USER SETTINGS - edit this block only. Everything is in one folder.
#------------------------------------------------------------------------
set DESIGN     test_top

set RTL_FILES  [list test_top_1.v]

set LIB_FILES  [list slow_vdd1v0_basicCells.lib]

set SDC_FILE   test_top.sdc

# Cells the mapper must not use (patterns on base-cell names)
set DONT_USE_PATTERNS {*SMDFF* *SDFF* *MDFF*}

#------------------------------------------------------------------------
# 1. Helpers
#------------------------------------------------------------------------
proc env_or {name default} {
    if {[info exists ::env($name)]} { return $::env($name) }
    return $default
}

proc safe_set_db {args} {
    if {[catch {set_db {*}$args} err]} {
        puts "WARNING(safe): could not set '$args' -> $err  (skipped)"
    }
}

proc safe_run {cmd} {
    if {[catch {uplevel #0 $cmd} err]} {
        puts "WARNING(safe): '$cmd' failed -> $err  (skipped)"
        return 0
    }
    return 1
}

proc safe_report {cmd file} {
    if {[catch {uplevel #0 "$cmd > $file"} err]} {
        puts "WARNING(safe): report '$cmd' failed -> $err  (skipped)"
    }
}

# Plain Tcl file reading - no Genus-specific commands, so these cannot
# break regardless of tool version. Used only to analyse report files
# that this script itself already generated.
proc count_occurrences {fname needle} {
    if {[catch {open $fname r} fh]} { return -1 }
    set content [read $fh]
    close $fh
    set count 0
    set start 0
    while {[set idx [string first $needle $content $start]] >= 0} {
        incr count
        set start [expr {$idx + [string length $needle]}]
    }
    return $count
}

#------------------------------------------------------------------------
# 2. Switches
#------------------------------------------------------------------------
set LOW_POWER   [env_or LOW_POWER   0]
set HIGH_EFFORT [env_or HIGH_EFFORT 1]
set EFFORT      [expr {$HIGH_EFFORT ? "high" : "medium"}]
set TAG         [env_or RUN_TAG [expr {$LOW_POWER ? "lp" : "base"}]]

puts "=================================================================="
puts " Design=$DESIGN  Tag=$TAG  Effort=$EFFORT  LowPower=$LOW_POWER"
puts "=================================================================="

#------------------------------------------------------------------------
# 3. Read library + RTL  (no search-path variables - plain filenames)
#------------------------------------------------------------------------
read_libs $LIB_FILES
read_hdl  $RTL_FILES
elaborate $DESIGN
current_design $DESIGN

check_design -unresolved
check_design -all

#------------------------------------------------------------------------
# 4. Constraints
#------------------------------------------------------------------------
read_sdc $SDC_FILE
safe_run check_timing_intent

#------------------------------------------------------------------------
# 5. Dont-use cells
#------------------------------------------------------------------------
foreach pat $DONT_USE_PATTERNS {
    set cells [get_db lib_cells $pat]
    if {[llength $cells] > 0} {
        if {![safe_run "set_db \[get_db lib_cells $pat\] .dont_use true"]} {
            safe_run "set_dont_use \[get_db lib_cells $pat\]"
        }
        puts "dont_use attempted on [llength $cells] cell(s) matching $pat"
    } else {
        puts "NOTE: no library cells match $pat"
    }
}

#------------------------------------------------------------------------
# 6. Clock gating (classic feature - should exist on 16.23)
#    Must be set before syn_generic for full effect.
#------------------------------------------------------------------------
if {$LOW_POWER} {
    set_db lp_insert_clock_gating true
}

#------------------------------------------------------------------------
# 7. Core synthesis effort (long-standing attributes)
#------------------------------------------------------------------------
set_db syn_generic_effort $EFFORT
set_db syn_map_effort     $EFFORT
set_db syn_opt_effort     $EFFORT

#------------------------------------------------------------------------
# 8. Core synthesis - the part that should just work
#------------------------------------------------------------------------
syn_generic
syn_map
syn_opt

#------------------------------------------------------------------------
# 9. Bonus attributes - UNCERTAIN on 2017 builds, all wrapped safely.
#    Run once, then check the log for WARNING(safe) lines to see which
#    of these your install actually has.
#------------------------------------------------------------------------
safe_set_db auto_ungroup both              ;# flatten hierarchy for opt
safe_set_db optimize_constant_0_flops true
safe_set_db optimize_constant_1_flops true
safe_set_db remove_assigns true

if {$LOW_POWER} {
    safe_set_db design_power_effort high
}

safe_run "syn_opt -incremental"

#------------------------------------------------------------------------
# 10. Reports
#------------------------------------------------------------------------
report_timing -max_paths 10  > ${DESIGN}_${TAG}.timing.rpt
report_area                  > ${DESIGN}_${TAG}.area.rpt
report_power                 > ${DESIGN}_${TAG}.power.rpt
report_gates                 > ${DESIGN}_${TAG}.gates.rpt
report_qor                   > ${DESIGN}_${TAG}.qor.rpt

if {$LOW_POWER} {
    safe_report "report_clock_gating" ${DESIGN}_${TAG}.cg.rpt
}

set CHECK_FILE ${DESIGN}_${TAG}.check_design.rpt
safe_run "check_design -all > $CHECK_FILE"

#------------------------------------------------------------------------
# 11. Write results (no scan/DFT - handled in Tessent)
#------------------------------------------------------------------------
write_hdl > ${DESIGN}_${TAG}_synth.v
write_sdc > ${DESIGN}_${TAG}_synth.sdc
write_db  -to_file ${DESIGN}_${TAG}.db

#------------------------------------------------------------------------
# 12. FINAL SUMMARY REPORT
#     Reads back the report files this run just produced and gives a
#     plain PASS/FAIL verdict, instead of you having to open five
#     separate files to find out if anything went wrong.
#------------------------------------------------------------------------
set TIMING_FILE ${DESIGN}_${TAG}.timing.rpt
set violated    [count_occurrences $TIMING_FILE "VIOLATED"]
set met         [count_occurrences $TIMING_FILE "MET"]
set errors      [count_occurrences $CHECK_FILE   "Error"]
set warnings    [count_occurrences $CHECK_FILE   "Warning"]

set SUMMARY_FILE ${DESIGN}_${TAG}.FINAL_SUMMARY.rpt
set fh [open $SUMMARY_FILE w]

puts $fh "========================================================"
puts $fh "GENUS RUN SUMMARY"
puts $fh "========================================================"
puts $fh "Date        : [clock format [clock seconds]]"
puts $fh "Design      : $DESIGN"
puts $fh "Run tag     : $TAG"
puts $fh "Effort      : $EFFORT"
puts $fh "Low power   : $LOW_POWER"
puts $fh "--------------------------------------------------------"
puts $fh "Timing paths MET       : $met"
puts $fh "Timing paths VIOLATED  : $violated"
puts $fh "check_design Errors    : $errors"
puts $fh "check_design Warnings  : $warnings"
puts $fh "--------------------------------------------------------"

if {$errors > 0 || $violated > 0} {
    puts $fh "VERDICT : NEEDS ATTENTION - see $CHECK_FILE / $TIMING_FILE"
    set verdict "NEEDS ATTENTION"
} elseif {$errors == -1 || $violated == -1} {
    puts $fh "VERDICT : UNKNOWN - one of the report files could not be read"
    set verdict "UNKNOWN"
} else {
    puts $fh "VERDICT : CLEAN - no check_design errors, no timing violations found"
    set verdict "CLEAN"
}
puts $fh "========================================================"
puts $fh "Report files generated this run:"
foreach f [list ${DESIGN}_${TAG}.timing.rpt ${DESIGN}_${TAG}.area.rpt \
                ${DESIGN}_${TAG}.power.rpt ${DESIGN}_${TAG}.gates.rpt \
                ${DESIGN}_${TAG}.qor.rpt ${DESIGN}_${TAG}.check_design.rpt] {
    puts $fh "  - $f"
}
if {$LOW_POWER} { puts $fh "  - ${DESIGN}_${TAG}.cg.rpt" }
close $fh

puts "=================================================================="
puts "=== Done. Files written as ${DESIGN}_${TAG}.* in the current folder"
puts "=== VERDICT: $verdict  (full details in $SUMMARY_FILE)"
puts "=== Search the log for 'WARNING(safe)' to see any skipped commands"
puts "=================================================================="

# exit
