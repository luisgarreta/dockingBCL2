#!/home/lg/.bin/xvmd
#
# Calculates RMSD between two molecules
puts "-----------------------------------------------------------------------------------------------"
set USAGE "md-pdbs-RMSDs.tcl <REF PDB file> <TARGET PDB File> \[all|protein|protein-noH\]"
puts "-----------------------------------------------------------------------------------------------"

set REF  [lindex $argv 0];
set TARGET  [lindex $argv 1];
set SELECTION [lindex $argv 2];   

if {$REF eq "" || $TARGET eq ""} then {
	puts $USAGE
	exit
}

switch $SELECTION {
	"protein" { set SELECTION "protein"; }
	"protein-noH" { set SELECTION "protein and backbone and noh"; }
	default { set SELECTION "all"; }
}

# Calculates RMSD for all frames vs frame 0
proc print_rmsd {SELECTION REF TARGET} {
	puts [format ">>> SELECTION: %s" $SELECTION]

	set reference [atomselect $REF $SELECTION]
	$reference writepdb ref.pdb
	set target [atomselect $TARGET $SELECTION]
	$target writepdb trg.pdb

	# compute the transformation
	set trans_mat [measure fit $target $reference]
	# do the alignment
	$target move $trans_mat
	# compute the RMSD
	set rmsd [measure rmsd $target $reference]
	# print the RMSD
	puts ">>>> RMSD: $rmsd"
}
#---------------------------------------------------------

set ref [mol new $REF type {pdb} first 0 last -1 step 1 waitfor 1]
set target [mol new $TARGET type {pdb} first 0 last -1 step 1 waitfor 1]

print_rmsd $SELECTION $ref $target
exit
