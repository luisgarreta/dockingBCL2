#!/home/lg/.bin/xvmd
# Get frame from trajectory
#
puts "-----------------------------------------------------------------------------------------------"
set USAGE "md-dcd-get-frame.tcl <PSF file> <DCD trajectory> \[Frame number|first|last\] \[all|protein|protein-noH|HETA]"
puts "-----------------------------------------------------------------------------------------------"

set PSF  [lindex $argv 0];
set DCD  [lindex $argv 1];
set nFRAME [lindex $argv 2];
set SELECTION [lindex $argv 3];   

set OUTNAME "frame.pdb";

if {$PSF eq "" || $DCD eq ""} then {
	puts $USAGE
	exit
}

set id [mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1]
mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0

set n_frames [molinfo $id get numframes]
puts ">>> NFrames: $n_frames"

if {$nFRAME eq ""} then {
	puts [format ">>> NFrames: %s " [molinfo top get numframes]];
	exit
}
switch $nFRAME {
	"last" {
		set OUTNAME "frame-LAST"
		set nFrame [expr {$n_frames - 1}]
	}
	"first" {
		set OUTNAME "frame-FIRST"
		set nFrame 0
	}
	default {
		set OUTNAME [format "frame-%.2d" $nFRAME];
	}
}

switch $SELECTION {
	"protein" {
		set SELECTION "protein";
		set OUTNAME [format "%s-protH.pdb" $OUTNAME];
	}
	"protein-noH" {
		set SELECTION "protein and backbone and noh";
		set OUTNAME [format "%s-protNoH.pdb" $OUTNAME];
	}
	"all" {
		set SELECTION "all";
		set OUTNAME [format "%s-all.pdb" $OUTNAME;
	}
	"HETA" {
		set SELECTION "segname HETA";
		set OUTNAME [format "%s-heta.pdb" $OUTNAME];
	}
}
puts [format ">>> SELECTION: %s" $SELECTION]
#if {$SELECTION eq "protein"} then {
#	set SELECTION "protein and backbone and noh";
#}



#set frame0 [atomselect top "protein and backbone and noh" frame $nFRAME]
set frame0 [atomselect top $SELECTION frame $nFRAME]
$frame0 writepdb $OUTNAME
render snapshot f.png
exit

