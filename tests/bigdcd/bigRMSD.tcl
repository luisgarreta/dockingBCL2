#!/usr/bin/env xvmd.py
#
source bigdcd.tcl

proc myrmsd { frame } {
	global ref sel all 
	$all move [measure fit $sel $ref]
	set fout [open "rmsd.csv" a+]
	#puts "$frame: [measure rmsd $sel $ref]"
	#puts $fout [format "%f" [measure rmsd $sel $ref]]
	puts $fout [format "%s,%s,%f" $frame "Protein" "[measure rmsd $sel $ref]"]
	close $fout
}

set mol [mol new protein.psf waitfor all]
set all [atomselect $mol "segid PROA"]
set ref [atomselect $mol "segid PROA" frame 0]
set sel [atomselect $mol "segid PROA"]


set fout [open "rmsd.dat" w]
puts $fout "FRAME,TYPE,RMSD" 
close $fout
mol addfile protein.pdb type pdb waitfor all
bigdcd myrmsd dcd sim.dcd
bigdcd_wait
exit
