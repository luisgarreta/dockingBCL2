#!/users/legarreta/bin/xvmdg
#!/home/lg/.bin/xvmdg
#
# Create movie from VMD trajectory
# First create snapshots then create movie using a python library.
#

set USAGE "md_dcd_create_snapshots.tcl <PSF file path> <DCD file path>"

set PSFFILE [lindex $argv 0];
set DCDFILE [lindex $argv 1];
set IMAGESDIR "snapshots"

if {$PSFFILE eq ""} then {
	puts $USAGE; exit
}

# VMD for LINUXAMD64, version 1.9.4a51 (December 21, 2020)
# Log file '/home/lg/BIO/omicas/simulations/03-Docking/03-PreparingComplexes-for-MD/conformation02/outputs/prep.tcl', created by user lg

proc make_trajectory_snapshots {imagesDir} {
	set freq 1
	# get the number of frames in the movie
	set num [molinfo top get numframes]
	# loop through the frames
	for {set i 0} {$i < $num} {incr i $freq} {
		# go to the given frame
		animate goto $i
        # for the display to update
        display update
		# take the picture
		set filename snap[format "%05d" [expr $i/$freq]].rgb
		render snapshot $filename
	}
}

# Load molecules
mol addrep 0
mol new ${PSFFILE} type {psf} first 0 last -1 step 1 waitfor 1
mol addfile ${DCDFILE} type {dcd} first 0 last -1 step 1 waitfor 1 0

# Add cartoon view to protein
mol color ColorID 10
mol representation NewCartoon 0.300000 10.000000 4.100000 0
mol selection protein
mol modrep 0 0

# Add licorice view to ligand
mol addrep 0
mol color ColorID 7
mol representation Licorice 0.300000 12.000000 12.000000
mol selection segname HETA
mol modrep 1 0
rotate x by 90
scale by 2

# Create snapshots
exec mkdir snapshots
make_trajectory_snapshots $IMAGESDIR
#exec create_movie_from_images.py $IMAGESDIR
#exec rm -rf images
exit
