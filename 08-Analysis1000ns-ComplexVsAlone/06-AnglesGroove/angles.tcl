# angle calculation loop
#
proc angleVectors {v1 v2} {
	set C 57.2975
	set theta [expr acos ([vecdot $v1 $v2]) * $C]

	#if { $theta > 90.0 } {
    #	set theta [expr 180.0 - $theta]
  	#}
  	return $theta
}

proc angleAxes {I1 I2} {
	set a1 [angleVectors [lindex $I1 0] [lindex $I2 0]];list
	set a2 [angleVectors [lindex $I1 1] [lindex $I2 1]];list
	set a3 [angleVectors [lindex $I1 2] [lindex $I2 2]];list

	return [list $a1 $a2 $a3]
}

proc calcAngles {} {
	global resg
	graphics 0 delete "all"
	set selg [atomselect 0 $resg]
	#set Ig [draw principalaxes $selg];list
	set Ig [Orient::calc_principalaxes $selg]

	set a1 [angleVectors [lindex $Ig 0] {1 0 0}];list
	set a2 [angleVectors [lindex $Ig 0] {0 1 0}];list
	set a3 [angleVectors [lindex $Ig 0] {0 0 1}];list

	# Vector for groove
	set Wg [$selg get mass]
	set Cg [Orient::sel_com $selg $Wg]
	#set Ag [Orient::calc_principalaxes $selg]

	set scale 50 
	set va1 [vecscale $scale [lindex $Ig 0]]
	set va2 [vecscale $scale [lindex $Ig 1]]
	set va3 [vecscale $scale [lindex $Ig 2]]

	graphics 0 color red
	vmd_draw_vector 0 $Cg [vecscale 1 $va1]

	# Vector for system
	graphics 0 color green
	vmd_draw_vector 0 $Cg {0 0 50}

	return [list $a1 $a2 $a3]
}

proc initVMD {} {
	lappend auto_path /home/lg/BIO/omicas/dockingBCL2/opt/vmdplugins/orient/
	lappend auto_path /home/lg/BIO/omicas/dockingBCL2/opt/vmdplugins/la1.0/

	package require Orient
	namespace import Orient::orient

	mol modstyle 0 0 NewCartoon 0.300000 10.000000 4.100000 0
	mol representation NewCartoon 0.300000 10.000000 4.100000 0
	mol selection protein
	mol modrep 0 0

	mol addrep 0
	mol color ColorID 2
	mol modstyle 1 0 Points 1.000000
	mol representation Points 1.000000
	mol selection lipids
	mol modrep 1 0

	set resg "segname PROA and resid 104 to 132" 
	#set resg "segname PROA and resid 104 to 156"
	set selg [atomselect top $resg]
	set resm "lipids and resid 400 to 823 and noh"
	set selm [atomselect top $resm]

	mol addrep 0
	mol color ColorID 4
	mol representation NewCartoon 0.300000 10.000000 4.100000 0
	mol selection $resg
	mol modrep 2 0


	rotate x by 100
	scale by 1.5
	axes location Origin
}
