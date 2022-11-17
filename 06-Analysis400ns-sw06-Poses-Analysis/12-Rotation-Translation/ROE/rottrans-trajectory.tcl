#!/usr/bin/env xvmd.py
package require Orient
namespace import Orient::orient

package require math::bigfloat
namespace import ::math::bigfloat::*

set USAGE "Compute rotation distances and translation angles from trajectory file
USAGE: rotation-translation-trajectory.tcl <PSF file> <DCD trajectory>";list

# Reference frame0 COM and Principal axes
set REFCX "{0.48833586922292893 -0.456006772259496 -43.59587226434773} {{0.21393974427292534 -0.9766500122687108 0.019609675060091158} {0.9670405141944067 0.2145866813293018 0.13705911170985302} {-0.13806675822605752 -0.010359041056184487 0.9903687497802744}}"

proc main {} {
	global argv argc USAGE

	if { $argc < 3 } then {
		puts "---------------------------------------------------------------"
		puts $USAGE
		puts "---------------------------------------------------------------"
		exit
	}

	set PSF  [lindex $argv 0];list
	set DCD  [lindex $argv 1];list
	set X  [lindex $argv 2];list
	set Y  [lindex $argv 3];list
	set Z  [lindex $argv 4];list

	set id [mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1]
	mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0

	set nFrames [molinfo $id get numframes]
	puts ">>> nFrames: $nFrames"

	set OUTFILE [format "%s-rotations.csv" [lindex [split $DCD "."] 0]]
	calcRotationsReference $nFrames $OUTFILE
	#calcTranslationGeomCenters $nFrames $OUTFILE $X $Y $Z
	#calcRotationTranslationTrajectoryReference $nFrames $OUTFILE
	exit
}

proc calcRotationsReference {nFrames OUTFILE} {
	global REFCX
	puts ">>>Calculating rotations..."

	set outfile [open $OUTFILE w];
	puts $outfile "FRAME, xRot, yRot, zRot"

	# Init last frame and vector
	set referenceComAxes $REFCX
	for {set i 1} {$i < [expr {$nFrames-1}]} {incr i} {
		puts [format ">>>>>>>>>>>>>>> FRAME: %s <<<<<<<<<<<<<<<<<<" $i]
		set j [expr {$i+1}]
		set frame2 [atomselect top "segname PROA" frame $j]

		set Jcomaxes [calcComAxes $frame2]
		set values [calcRotationsFrames $referenceComAxes $Jcomaxes]

		# Save values to file
		set csvValues [join $values ","]
		puts [format ">>> Values: %s" $csvValues]
		puts $outfile [format "%s,%s" $i $csvValues]
	}
	close $outfile
}



proc calcRotationTranslationTrajectoryReference {nFrames OUTFILE} {
	puts ">>>Calculating rotations and translations..."

	set outfile [open $OUTFILE w];
	puts $outfile "FRAME, xTrans, yTrans, zTrans, xRot, yRot, zRot"

	# Init last frame and vector
	set referenceFrame [atomselect top "segname PROA" frame 0]
	set referenceComAxes [calcComAxes $referenceFrame]
	for {set i 0} {$i < [expr {$nFrames-1}]} {incr i} {
		puts [format ">>>>>>>>>>>>>>> FRAME: %s <<<<<<<<<<<<<<<<<<" $i]
		set j [expr {$i+1}]
		set frame2 [atomselect top "segname PROA" frame $j]

		set Jcomaxes [calcComAxes $frame2]
		set values [calcRotationTranslationFrames $referenceComAxes $Jcomaxes]

		# Save values to file
		set csvValues [join $values ","]
		puts [format ">>> Values: %s" $csvValues]
		puts $outfile [format "%s,%s" $i $csvValues]
	}
	close $outfile
}

proc calcRotationTranslationTrajectory {nFrames OUTFILE} {
	puts ">>>Calculating rotations and translations..."

	set outfile [open $OUTFILE w];
	puts $outfile "FRAME, xTrans, yTrans, zTrans, xRot, yRot, zRot"

	# Init last frame and vector
	set lastFrame [atomselect top "segname PROA" frame 0]
	set lastComAxes [calcComAxes $lastFrame]
	for {set i 0} {$i < [expr {$nFrames-1}]} {incr i} {
		puts [format ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> FRAME: %s <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" $i]
		set frame1 $lastFrame
		set j [expr {$i+1}]
		set frame2 [atomselect top "segname PROA" frame $j]

		set Icomaxes $lastComAxes
		set Jcomaxes [calcComAxes $frame2]
		set values [calcRotationTranslationFrames $Icomaxes $Jcomaxes]

		# Save values to file
		set csvValues [join $values ","]
		puts [format ">>> Values: %s" $csvValues]
		puts $outfile [format "%s,%s" $i $csvValues]

		# Update last frame and values
		set lastFrame $frame2
		set lastComAxes $Jcomaxes
	}
	close $outfile
}



# Calculate the center of mass and the three principal axes 
proc calcComAxes {sel} {
	# Getting the center-of-mass
	set weights [ $sel get mass ];list
    set COM [Orient::sel_com $sel $weights];list
    #puts [format ">>> COM: %s" $COM]	

    # Computing the inertia tensor
    set I [Orient::sel_it $sel $COM $weights];list
    La::mevsvd_br I evals
    #puts [format ">>> I: %s" $I]	

    # now $I holds in its columns the principal axes
    set a1 "[lindex $I 3] [lindex $I 6] [lindex $I 9]";list
    set a2 "[lindex $I 4] [lindex $I 7] [lindex $I 10]";list
    set a3 "[lindex $I 5] [lindex $I 8] [lindex $I 11]";list

	set paxes [list $a1 $a2 $a3];list
	#puts [format ">>> PAXES: %s" $paxes]
	return [list $COM $paxes]
}

#------------------------------------------------------
#------------------------------------------------------
proc calcAngleVectors {vector1 vector2} {
    set vec1 [vecnorm $vector1]
    set vec2 [vecnorm $vector2]

    # compute the angle and axis of rotation
    set rotvec [veccross $vec1 $vec2]
    set sine   [veclength $rotvec]
    set cosine [vecdot $vec1 $vec2]
    set radians [expr atan2($sine,$cosine)]
    
    # return the rotation matrix
    set angle [Rad2Deg $radians]

    return $angle
}

proc calcRotationsFrames {Icomaxes Jcomaxes} {
#	# Get vector for each dimension
	puts ">>>>>>>>>>>>>>>>>>>>>>>>>>"
	set I [lindex $Icomaxes 1]
	set Ix [lindex $I 0]; #puts $Ix
	set Iy [lindex $I 1]; #puts $Iy
	set Iz [lindex $I 2]; #puts $Iz
#
	set J [lindex $Jcomaxes 1]
	set Jx [lindex $J 0]; #puts $Jx
	set Jy [lindex $J 1]; #puts $Jy
	set Jz [lindex $J 2]; #puts $Jz
	puts ">>>>>>>>>>>>>>>>>>>>>>>>>>"

	# Rotation
	set rotX [calcAngleVectors $Ix $Jx]
	set rotY [calcAngleVectors $Iy $Jy]
	set rotZ [calcAngleVectors $Iz $Jz]

	set values [list $rotX $rotY $rotZ]
	return $values
}


proc calcRotationTranslationFrames {Icomaxes Jcomaxes} {
	#set Icomaxes [calcComAxes $frame1]
	#puts ">>> I: "; puts $I; puts ">>>"
	#puts ">>> J: "; puts $I; puts ">>>"

#	# Get vector for each dimension
	puts ">>>>>>>>>>>>>>>>>>>>>>>>>>"
	set Icom [lindex $Icomaxes 0]; puts $Icom
	set I [lindex $Icomaxes 1]
	set Ix [lindex $I 0]; #puts $Ix
	set Iy [lindex $I 1]; #puts $Iy
	set Iz [lindex $I 2]; #puts $Iz
#
	set Jcom [lindex $Jcomaxes 0]; puts $Jcom
	set J [lindex $Jcomaxes 1]
	set Jx [lindex $J 0]; #puts $Jx
	set Jy [lindex $J 1]; #puts $Jy
	set Jz [lindex $J 2]; #puts $Jz
	puts ">>>>>>>>>>>>>>>>>>>>>>>>>>"

	# Translation
	set IJcom [vecsub $Icom $Jcom]
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

proc calcTranslationGeomCenters {nFrames OUTFILE X Y Z} {
	puts ">>> Calculating translations using geometric centers..."
	set outfile [open $OUTFILE w];
	puts $outfile "FRAME, xTrans, yTrans, zTrans"

	# Init last frame and vector
	#set referenceFrame [atomselect top "segname PROA" frame 0]
	#set referenceFrame [atomselect top "segname PROA" frame 0]
	set referenceCenter [list $X $Y $Z]
	for {set i 1} {$i < [expr {$nFrames-1}]} {incr i} {
		puts [format ">>>>>>>>>>> FRAME: %s <<<<<<<<<<<<<<<<<<" $i]
		set j [expr {$i+1}]
		set target [atomselect top "segname PROA" frame $j]
		set targetCenter [measure center $target]
		set values [vecsub $referenceCenter $targetCenter]

		# Save values to file
		puts ">>> Formating..."
		set fvalues [string map {" " ","} $values]
		set csvValues [format "%s, %s" $i $fvalues]
		puts [format ">>> Values: %s" $csvValues]
		puts $outfile $csvValues
	}
	close $outfile
}



proc calcDistanceTwoCOM {} {
	foreach i in (selection for monomer) {
		set sel [atomselect top "fragment $i"]
		set com1 [measure center $sel weight mass]
		$sel delete
		foreach j in (selection for monomer) {
			set sel [atomselect top "fragment $i"]
			set com2 [measure center $sel weight mass]
			set dist [veclength [vecsub $com1 $com2]]
			#(you can write this distance to an output)
			$sel delete
		}
	}
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

#main
