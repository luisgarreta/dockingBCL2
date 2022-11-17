#!/usr/bin/env xvmd.py
#
#!/users/legarreta/bin/xvmd
#!/home/lg/.bin/xvmd
#
# Calculate hydrogen bonds from namd trajectories

#if { $argc < 4 } then {
#	puts "-----------------------------------------------------------------------"
#	puts "Calculate non-bonded energies from namd trajectories"
#	puts "USAGE: hbonds-trajectory.tcl <PSF file> <DCD file> [output filename]"
#	puts "-----------------------------------------------------------------------"
#	exit
#}

package require hbonds

set PSFFILE [lindex $argv 0];
set DCDFILE [lindex $argv 1];
set OUTFILE "hbonds.csv"

puts ">>>"
puts $argc
puts [lindex $argv 0]
puts [lindex $argv 1]
puts [lindex $argv 2]
puts [lindex $argv 3]

if {$argc == 4} {
	set OUTFILE [lindex $argv 2]
}

#set PSFFILE "step3_input.psf"
#set DCDFILE "step5_1.dcd"

puts $PSFFILE

mol new $PSFFILE first 0 last -1
mol addfile $DCDFILE first 0 last -1 step 1 waitfor -1 0

hbonds -sel1 [atomselect top "segname PROA"] \
       -sel2 [atomselect top "segid HETA"] \
	   -writefile yes \
       -type all 

sed "s/  */,/g" "hbonds.dat" > $OUTFILE
sed -i "1s/^/FRAME,HBONDS\\n/g" $OUTFILE

exit
