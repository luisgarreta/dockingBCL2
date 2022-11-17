#!/home/lg/.bin/xvmd
#
# Prints the RMSD of the protein atoms between each \timestep
# and the first \timestep for the given molecule id (default: top)
puts "-----------------------------------------------------------------------------------------------"
set USAGE "md-dcd-RMSDs.tcl <PSF file> <DCD trajectory> \[all|protein|protein-noH\]"
puts "-----------------------------------------------------------------------------------------------"

set PSF  [lindex $argv 0];
set DCD  [lindex $argv 1];
set SELECTION [lindex $argv 2];   

if {$PSF eq "" || $DCD eq ""} then {
	puts $USAGE
	exit
}

switch $SELECTION {
	"protein" { set SELECTION "protein"; }
	"protein-noH" { set SELECTION "protein and backbone and noh"; }
	default { set SELECTION "all"; }
}

# Calculates RMSD for all frames vs frame 0
proc print_rmsd_through_time {SELECTION {mol top}} {
	puts [format ">>> SELECTION: %s" $SELECTION]
	# use frame 0 for the reference
	#set reference [atomselect $mol "protein and backbone and noh" frame 0]
	set reference [atomselect $mol $SELECTION frame 0]
	$reference writepdb ref.pdb
	# the frame being compared
	#set compare [atomselect $mol "protein and backbone and noh"]
	set compare [atomselect $mol $SELECTION]
	$compare writepdb trg.pdb

	set num_steps [molinfo $mol get numframes]
	for {set frame 0} {$frame < $num_steps} {incr frame} {
		# get the correct frame
		$compare frame $frame

		# compute the transformation
		set trans_mat [measure fit $compare $reference]
		# do the alignment
		$compare move $trans_mat
		# compute the RMSD
		set rmsd [measure rmsd $compare $reference]
		# print the RMSD
		puts "RMSD of $frame is $rmsd"
	}
}
#---------------------------------------------------------

mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1
mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0

print_rmsd_through_time $SELECTION 
exit
