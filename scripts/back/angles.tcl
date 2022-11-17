#!/usr/bin/env xvmd.py
package require Orient
namespace import Orient::orient

#package require math::bigfloat
#namespace import ::math::bigfloat::*

# Calculate the center of mass and the three principal axes 
proc calcComAxes {sel} {
	# Getting the center-of-mass
	set weights [ $sel get mass ];list
    set COM [Orient::sel_com $sel $weights];list
    puts [format ">>> COM: %s" $COM]	

    # Computing the inertia tensor
    set I [Orient::sel_it $sel $COM $weights];list
    La::mevsvd_br I evals
    puts [format ">>> I: %s" $I]	

    # now $I holds in its columns the principal axes
    set a1 "[lindex $I 3] [lindex $I 6] [lindex $I 9]";list
    set a2 "[lindex $I 4] [lindex $I 7] [lindex $I 10]";list
    set a3 "[lindex $I 5] [lindex $I 8] [lindex $I 11]";list

	set paxes [list $a1 $a2 $a3];list
	puts [format ">>> PAXES: %s" $paxes]
	return [list $COM $paxes]
}

proc calcAngleVectors {vector1 vector2} {
    set vec1 [vecnorm $vector1]
    set vec2 [vecnorm $vector2]

    # compute the angle and axis of rotation
    set rotvec [veccross $vec1 $vec2]
    set sine   [veclength $rotvec]
    set cosine [vecdot $vec1 $vec2]
    set value [expr atan2($sine,$cosine)]
    
    # return the rotation matrix
    puts ">>>>>>>>>>>>>>>>>>>>"
    puts $value
    set angle [Rad2Deg $value]
    puts $angle
    puts ">>>>>>>>>>>>>>>>>>>>"

    return $angle
    #return $value
}

proc calcRotationTranslationFrames {frame1 frame2} {
	set Icomaxes [calcComAxes $frame1]
	#puts ">>> I: "; puts $I; puts ">>>"
	set Jcomaxes [calcComAxes $frame2];
	#puts ">>> J: "; puts $I; puts ">>>"

#	# Get vector for each dimension
	puts ">>>>>>>>>>>>>>>>>>>>>>>>>>"
	set Icom [lindex $Icomaxes 0]; puts $Icom
	set I [lindex $Icomaxes 1]
	set Ix [lindex $I 0]; puts $Ix
	set Iy [lindex $I 1]; puts $Iy
	set Iz [lindex $I 2]; puts $Iz
#
	set Jcom [lindex $Jcomaxes 0]; puts $Jcom
	set J [lindex $Jcomaxes 1]
	set Jx [lindex $J 0]; puts $Jx
	set Jy [lindex $J 1]; puts $Jy
	set Jz [lindex $J 2]; puts $Jz
	puts ">>>>>>>>>>>>>>>>>>>>>>>>>>"

	# Translation
	set IJcom [vecsub $Icom $Jcom]
	puts [format ">>> dCOM: %s " $IJcom]
	set transX [lindex $IJcom 0]
	set transY [lindex $IJcom 1]
	set transZ [lindex $IJcom 2]

	# Rotation
	set rotX [calcAngleVectors $Ix $Jx]
	set rotY [calcAngleVectors $Iy $Jy]
	set rotZ [calcAngleVectors $Iz $Jz]

	set values [list $transX $transY $transZ $rotX $rotY $rotZ]
	return $values
}

proc calcRotationTranslationTrajectory {} {
	puts "Calculating rotations and translations..."
	set outfile [open "out-RotationTranslation.csv" w];
	puts $outfile "FRAME, xTrans, yTrans, zTrans, xRot, yRot, zRot"
	for {set i 0} {$i < 6} {incr i} {
		set frame1 [atomselect top "segname PROA" frame $i]
		set j [expr {$i+1}]
		set frame2 [atomselect top "segname PROA" frame $j]

		set values [calcRotationTranslationFrames $frame1 $frame2]
		set xTrans [lindex $values 0]; puts $xTrans
		set yTrans [lindex $values 1]; puts $yTrans
		set zTrans [lindex $values 2]; puts $zTrans
		set xRot [lindex $values 3]
		set yRot [lindex $values 4]
		set zRot [lindex $values 5]
		puts [format ">>> Values: %s,%s,%s,%s,%s,%s,%s" $i $xTrans $yTrans $zTrans $xRot $yRot $zRot ]
		puts $outfile [format "%s,%s,%s,%s,%s,%s,%s" $i $xTrans $yTrans $zTrans $xRot $yRot $zRot ]
	}
	close $outfile
}

proc Rad2Deg {angle} {
	set PI 3.141592653589793238
	set d [expr {$angle * 180.0 / $PI}]	;# decimal degrees
	set dd [expr {int(floor($d))}]
	set m [expr {($d -$dd) * 60.0}]
	set mm [expr {int(floor($m))}]
	set ss [expr {int(($m -$mm) * 60.0)}]
	return "$dd.$mm$ss"
}

proc loadTrajectory {argv} {
	# Extracts the protein and ligand PDB files from each step.
	#
	puts "---------------------------------------------------------------"
	set USAGE "
	Extracts the protein and ligand PDB files from each step.
	frame-trajectory.tcl <PSF file> <DCD trajectory>" 
	puts "---------------------------------------------------------------"

	set PSF  [lindex $argv 0];list
	set DCD  [lindex $argv 1];list

	if {$PSF eq "" || $DCD eq ""} then {
		puts $USAGE
		exit
	}

	set id [mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1]
	mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0

	set nFrames [molinfo $id get numframes]
	puts ">>> nFrames: $nFrames"
}


