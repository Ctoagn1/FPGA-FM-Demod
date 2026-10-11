set part   xc7a35tcpg236-1
set top    uart_demo
set outdir build
file mkdir $outdir

read_verilog -sv [glob rtl/*.sv]
read_xdc constr/basys3.xdc

# Synthesis
synth_design -top $top -part $part
write_checkpoint -force $outdir/post_synth.dcp
report_utilization -file $outdir/util_synth.rpt

# Implementation
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force $outdir/post_route.dcp

# Reports
report_timing_summary -file $outdir/timing.rpt -max_paths 10
report_utilization    -file $outdir/util_impl.rpt
report_power          -file $outdir/power.rpt
report_clock_utilization -file $outdir/clocks.rpt

# Fail the build if timing isn't met
set wns [get_property SLACK [get_timing_paths -max_paths 1 -setup]]
set whs [get_property SLACK [get_timing_paths -max_paths 1 -hold]]
puts "WNS = $wns ns, WHS = $whs ns"
if {$wns < 0 || $whs < 0} {
    puts "ERROR: timing not met"
    exit 1
}

# Bitstream
write_bitstream -force $outdir/$top.bit
