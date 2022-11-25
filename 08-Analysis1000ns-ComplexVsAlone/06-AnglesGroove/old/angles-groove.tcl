#!/usr/bin/env xvmd.py
#
set USAGE "Compute rotation distances and translation angles from trajectory file
USAGE: angles-groove.tcl <PSF file> <DCD trajectory> <OUT filename>";list

if { $argc < 0 } then {
	puts "---------------------------------------------------------------"
	puts $USAGE
	puts "---------------------------------------------------------------"
	exit
}

package require Orient
namespace import Orient::orient

package require math::bigfloat
namespace import ::math::bigfloat::*

	#set FRAME1  [lindex $argv 0]
	#set FRAME1  [lindex $argv 1];list
	#set OUTFILE  "angles.csv"

#mol addrep 0
#display resetview
#mol new "frame999.pdb" type {pdb} first 0 last -1 step 1 waitfor 1
#animate style Loop
	#set frame1 [mol new $FRAME1 type {pdb} first 0 last -1 step 1 waitfor 1]
	#
	#
proc main {} {
	global argv argc USAGE
	#set argv [list "frame0.pdb"]
	puts ">>> NARGS: $argc"

	set FRAME1  [lindex $argv 0]
	#set FRAME1  [lindex $argv 1];list
	set OUTFILE  "angles.csv"

	#mol addrep 0
	mol new $FRAME1 type {pdb} first 0 last -1 step 1 waitfor 1
	#set frame1 [mol new $FRAME1 type {pdb} first 0 last -1 step 1 waitfor 1]
	#set frame2 [mol new $TARGET type {pdb} first 0 last -1 step 1 waitfor 1]
	
	set frame1 [atomselect top "all" frame 1]

	anglesGroove $frame1 $OUTFILE 
	exit
}

proc anglesGroove {frame1 OUTFILE} {
	puts ">>> $frame1"
	#set SEL "protein and backbone and noh and not resid 65 to 84 and not resid 208 to 231"
	#set SEL "protein and backbone and noh"
	#set SELGROOVE "protein and backbone and noh and resid 104 to 132"
	#set SELGROOVE "protein and backbone and noh and resid 104 to 156"
	puts "Calculating groove angles using transformation matrix..."

	set outfile [open $OUTFILE w];
	puts $outfile "xAxis, yAxis, zAxis"

	set I [Orient::calc_principalaxes $frame1]
	set A [orient $frame1 [lindex $I 1] {0 0 -1}]

	set angles [eulerAngles $A ]
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

main
