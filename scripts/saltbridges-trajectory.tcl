#!/usr/bin/env xvmd.py

#!/users/legarreta/bin/xvmd
#!/home/lg/.bin/xvmd
#
# Calculate hydrogen bonds from namd trajectories

#if { $argc < 4 } then {
#	puts "-----------------------------------------------------------------------"
#	puts "Calculate non-bonded energies from namd trajectories"
#	puts "USAGE: hbonds-trajectory.tcl <PSF file> <DCD file>"
#	puts "-----------------------------------------------------------------------"
#	exit
#}

package require saltbr

set PSFFILE [lindex $argv 0];
set DCDFILE [lindex $argv 1];
#set OUTFILE "hbonds.csv"

mol new $PSFFILE first 0 last -1
mol addfile $DCDFILE first 0 last -1 step 1 waitfor -1 0

saltbr -sel [atomselect top "segname PROA or segname HETA"] \
	   -writefiles yes -log "sb.log"

#sed "s/  */,/g" "hbonds.dat" > $OUTFILE
#sed -i "1s/^/FRAME,HBONDS\\n/g" "hbonds.csv"

exit
