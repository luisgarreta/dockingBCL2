#!/usr/bin/env xvmdg.py

#!/users/legarreta/bin/xvmdg
#!/home/lg/.bin/xvmdg
#
# Create movie from VMD trajectory
# First create snapshots then create movie using a python library.
#
set USAGE "\n
---------------------------------------------------------------------------------------------------------
Create snapshots for DCD trajectory
USAGE: snapshots-trajectory.tcl <PSF file path> <DCD file path> <Perecentage of snapshots (100% default)>
---------------------------------------------------------------------------------------------------------";list

if {$argc < 3} {
	puts $USAGE; exit
}

set PSFFILE [lindex $argv 0];
set DCDFILE [lindex $argv 1];
set PERCENTAJE [lindex $argv 2];


# VMD for LINUXAMD64, version 1.9.4a51 (December 21, 2020)
# Log file '/home/lg/BIO/omicas/simulations/03-Docking/03-PreparingComplexes-for-MD/conformation02/outputs/prep.tcl', created by user lg

proc take_picture {args} {
  global take_picture

  # when called with no parameter, render the image
  if {$args == {}} {
    set f [format $take_picture(format) $take_picture(frame)]
    # take 1 out of every modulo images
    if { [expr $take_picture(frame) % $take_picture(modulo)] == 0 } {
      render $take_picture(method) $f
      # call any unix command, if specified
      if { $take_picture(exec) != {} } {
        set f [format $take_picture(exec) $f $f $f $f $f $f $f $f $f $f]
        eval "exec $f"
       }
    }
    # increase the count by one
    incr take_picture(frame)
    return $f
  }
  lassign $args arg1 arg2
  # reset the options to their initial stat
  # (remember to delete the files yourself
  if {$arg1 == "reset"} {
    set take_picture(frame)  0
    set take_picture(format) "frame%05d.rgb"
    set take_picture(method) snapshot
    set take_picture(modulo) 1
    set take_picture(exec)    {}
    return
  }
  # set one of the parameters
  if [info exists take_picture($arg1)] {
    if { [llength $args] == 1} {
      return "$arg1 is $take_picture($arg1)"
    }
    set take_picture($arg1) $arg2
    return
  }
  # otherwise, there was an error
  error {take_picture: [ | reset | frame | format  | \
  method  | modulo ]}

}

proc make_trajectory_movie_files {PERCENTAJE} {
	set totalFrames [molinfo top get numframes]
	set freq [expr {$totalFrames / ($totalFrames * $PERCENTAJE/100)}]
	puts "--------------"
	puts $totalFrames
	puts $PERCENTAJE
	puts $freq
	if {$freq < 1} then {
		set $freq 1
	}
	puts $freq
	puts "--------------"
	# loop through the frames
	for {set i 0} {$i < $totalFrames} {incr i $freq} {
		# go to the given frame
		animate goto $i
        # force display update
        display update 
		# take the picture
		take_picture
    }
}

# Load molecules
mol addrep 0
mol new ${PSFFILE} type {psf} first 0 last -1 step 1 waitfor 1
mol addfile ${DCDFILE} type {dcd} first 0 last -1 step 1 waitfor -1 0

# Add cartoon view to protein
mol color ColorID 4
mol representation NewCartoon 0.300000 10.000000 4.100000 0
mol selection segname PROA
mol modrep 0 0

# Add licorice view to ligand
mol addrep 0
mol color ColorID 7
mol representation Licorice 0.300000 12.000000 12.000000
mol selection segname HETA
mol modrep 1 0

# Add membrane view to protein

mol color Name
mol representation CPK 1.000000 0.300000 12.000000 12.000000
mol selection segname MEMB
mol material Transparent
mol addrep 0


rotate x by 90
#scale by 1.5

# to complete the initialization, this must be the first function
# called.  Do so automatically.
take_picture reset
make_trajectory_movie_files $PERCENTAJE
exit
