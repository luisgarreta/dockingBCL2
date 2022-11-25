#!/usr/bin/env xvmd.py
set USAGE "Compute rotation distances and translation angles from trajectory file
USAGE: angles-groove.tcl <PSF file> <DCD trajectory> <OUT filename>";list

if { $argc < 2 } then {
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
	puts ">>> NARGS: $argc"

	set PSF  [lindex $argv 0];list
	set DCD  [lindex $argv 1];list
	set FRAME1  [lindex $argv 2];list
	set FRAME2  [lindex $argv 3];list
	set OUTFILE  "angles.csv"
	if { $argc == 6 } then {
		set OUTFILE  [lindex $argv 4];list
	}

	mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1
	mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0

	set nFrames [molinfo 0 get numframes]
	puts ">>> OUTFILE: $OUTFILE"
	puts ">>> nFrames: $nFrames"

	#set OUTFILE [format "%s-rotations.csv" [lindex [split $DCD "."] 0]]
	anglesGroove $FRAME1 $FRAME2 $OUTFILE 
	exit
}

proc anglesGroove {frame1 frame2 OUTFILE} {
	#set SEL "protein and backbone and noh and not resid 65 to 84 and not resid 208 to 231"
	set SEL "protein and backbone and noh"
	set SELGROOVE "protein and backbone and noh and resid 104 to 156"
	puts "Calculating groove angles using transformation matrix..."
	set DEGPI 57.29578

	set outfile [open $OUTFILE w];
	puts $outfile "xAxis, yAxis, zAxis"

	# Get frames
	set f1 [atomselect 0 $SELGROOVE frame $frame1]
	$f1 writepdb [format "frame%s.pdb" $frame1]
	set I [draw principalaxes $f1]
	set A [orient $f1 [lindex $I 2] {0 0 1}]
	$f1 move $A

	set f2 [atomselect 0 $SELGROOVE frame $frame2]
	$f2 writepdb [format "frame%s.pdb" $frame2]

	set T [measure fit $f1 $f2]
	set angles [eulerAngles $T ]
	set Theta [lindex $angles 0]
	set Phi [lindex $angles 1]
	set Psi [lindex $angles 2]

	puts [format ">>> Values: %s %s %s" $Theta $Phi $Psi]
	puts $outfile [format "%s,%s,%s" $Theta $Phi $Psi]
	close $outfile
}

proc eulerAngles { T } {
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

#main
