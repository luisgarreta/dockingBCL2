#!/usr/bin/env xvmd.py
set USAGE "Compute rotation distances and translation angles from trajectory file
USAGE: rotation-trajectory.tcl <PSF file> <DCD trajectory> <PDB filename> <OUT filename>";list

if { $argc < 3 } then {
	puts "---------------------------------------------------------------"
	puts $USAGE
	puts "---------------------------------------------------------------"
	exit
}

package require Orient
namespace import Orient::orient

package require math::bigfloat
namespace import ::math::bigfloat::*

proc main {} {
	global argv argc USAGE

	set PSF  [lindex $argv 0];list
	set DCD  [lindex $argv 1];list
	set PDBFILE  [lindex $argv 2];list
	set OUTFILE  "out-rotations.csv"
	if { $argc == 5 } then {
		set OUTFILE  [lindex $argv 3];list
	}

	mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1
	mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0
	mol new $PDBFILE type {pdb} first 0 last -1 step 1 waitfor 1

	set nFrames [molinfo 0 get numframes]
	puts ">>> nFrames: $nFrames"

	#set OUTFILE [format "%s-rotations.csv" [lindex [split $DCD "."] 0]]
	rotationsTransfMatrix $nFrames $OUTFILE 
	exit
}

proc eulerAngles { T last } {
	set DEGPI 57.29578

	set R11 [lindex [lindex $T 0] 0]; set R12 [lindex [lindex $T 0] 1]; set R13 [lindex [lindex $T 0] 2] 
    set R21 [lindex [lindex $T 1] 0]; set R22 [lindex [lindex $T 1] 1]; set R23 [lindex [lindex $T 1] 2] 
    set R31 [lindex [lindex $T 2] 0]; set R32 [lindex [lindex $T 2] 1]; set R33 [lindex [lindex $T 2] 2] 

    set sy [expr {sqrt ($R11 * $R11 +  $R21 * $R21)}]
    set singular [expr $sy < 1e-6]

    if  { $singular==0 } {
        #set x [expr atan2 (-$R23 , $R33) * $DEGPI]
        #set sy [expr $R13 * cos ($x)]
        #set y [expr atan2 ($sy, $R33) * $DEGPI]
        #set z [expr atan2 (-$R12, $R11) * $DEGPI]

		# Meth 2
        set x [expr atan2 ($R32 , $R33) * $DEGPI]
        set y [expr atan2 (-$R31, $sy) * $DEGPI]
        set z [expr atan2 ($R21, $R11) * $DEGPI]

		# Meth 3
        #set x [expr atan2 (-$R12 , $R22) * $DEGPI]
        #set sy [expr {sqrt (1 - $R32*$R32)}]
        #set y [expr atan2 ($R32, $sy) * $DEGPI]
        #set z [expr atan2 (-$R31, $R33) * $DEGPI]
        #set z [expr [expr int ($z)] % -360]
    }  else {
        set x [expr atan2 (-$R23, $R22) * $DEGPI]
        set y [expr atan2 (-$R31, $sy) * $DEGPI]
        set z [expr 0 * $DEGPI]
    }

    set angles [list $x $y $z]
    return $angles
}



proc rotationsTransfMatrix {nFrames OUTFILE} {
	#set SEL "protein and backbone and noh and not resid 65 to 84 and not resid 208 to 231"
	set SEL "protein and backbone and noh"
	puts "Calculating angles using transformation matrix..."
	set DEGPI 57.29578

	set outfile [open $OUTFILE w];
	puts $outfile "FRAME, xAxis, yAxis, zAxis"

	# Init last frame and vector
	set f0 [atomselect 1 $SEL]
	#set f0 [atomselect 0 $SEL frame 0]

	#set nFrames 2
	set last 0
	for {set i 0} {$i < $nFrames} {incr i} {
		puts [format ">>>>>>>>>>>>>>> FRAME: %s <<<<<<<<<<<<<<<<<<" $i]
		#set j [expr {$i+1}]
		set f1 [atomselect 0 $SEL frame $i]

		#puts ">>>>>>>>>>>>>>>>>>>>>>>"
		set T [measure fit $f1 $f0]
		set angles [eulerAngles $T $last]
		set Theta [lindex $angles 0]
		set Phi [lindex $angles 1]
		set Psi [lindex $angles 2]
		set last $Psi

		puts [format ">>> Values: %s %s %s %s" $i $Theta $Phi $Psi]
		puts $outfile [format "%s,%s,%s,%s" $i $Theta $Phi $Psi]
	}
	close $outfile
}

main
