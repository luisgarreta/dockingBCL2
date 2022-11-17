#!/home/lg/.bin/xvmdg
# Create movie from VMD trajectory
# First create snapshots then create movie using a python library.

set USAGE "create_trajectory_movie.tcl"

set IMAGESDIR       [lindex $argv 0]

if {$IMAGESDIR eq ""} then {
	puts $USAGE; exit
}

# VMD for LINUXAMD64, version 1.9.4a51 (December 21, 2020)
# Log file '/home/lg/BIO/omicas/simulations/03-Docking/03-PreparingComplexes-for-MD/conformation02/outputs/prep.tcl', created by user lg

proc make_trajectory_movie {imagesDir} {
	set freq = 1
	# get the number of frames in the movie
	set num [molinfo top get numframes]
	# loop through the frames
	for {set i 0} {$i < $num} {incr i $freq} {
		# go to the given frame
		animate goto $i
                # for the display to update
                display update
		# take the picture
		set filename $imagesDir/snap.[format "%04d" [expr $i/$freq]].rgb
		render snapshot $filename
	}
}

mol addrep 0
mol new {step3_input.psf} type {psf} first 0 last -1 step 1 waitfor 1
mol addfile {step4_equilibration.dcd} type {dcd} first 0 last -1 step 1 waitfor 1 0
mol addfile {step5_1.dcd} type {dcd} first 0 last -1 step 1 waitfor 1 0

#mol modcolor 0 0 ColorID 7
mol color ColorID 7
mol representation NewCartoon 0.300000 10.000000 4.100000 0
mol selection protein
mol modrep 0 0

mol addrep 0
mol color Name
mol representation Licorice 0.300000 12.000000 12.000000
mol selection segname HETA
mol modrep 1 0
# VMD for LINUXAMD64, version 1.9.4a51 (December 21, 2020)
# end of log file.


exec mkdir images
make_trajectory_movie $IMAGESDIR
exec create_movie_from_images.py $IMAGESDIR
exec rm -rf images
exit
