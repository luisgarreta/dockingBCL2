#!/usr/bin/python3

"Creates movie for each ligand dcd trajectory"

import os, sys
import moviepy.editor as mpy

#----------------------------------------------------------
def createLigandsDic (ligandsDirName):
	# Create dic with ligand names (e.g. {"conf01":"av0001","conf02":"ad0020"...})
	ligandsDic = {}
	ligandNames = os.listdir (ligandsDirName)
	for name in ligandNames:
		conf = name.split ("_")[0]
		lign = name.split ("_")[1].split(".")[0]
		ligandsDic [conf] = lign
	return (ligandsDic)
#----------------------------------------------------------

args = sys.argv
args = ["", "namdouts"]

namdoutsDirname = args [1]
ligandsDic	    = createLigandsDic ("ligands")
imagesDir	    = "IMAGES"
videosDir	    = "%s/%s" % (os.getcwd(), "trajectory_videos")

os.system ("mkdir %s" % videosDir)

allNamdoutsDirs	= ["%s/%s" % (namdoutsDirname, x) for x in os.listdir (namdoutsDirname)] 
for namdDir in allNamdoutsDirs:
	confDir   = namdDir.split ("-")[1]
	outDir	= videosDir + "/" + confDir + "-" + ligandsDic [confDir]
	imagesDir = "%s/IMAGES" % outDir
	os.system ("mkdir -p %s" % imagesDir)

	workingDir = os.getcwd()
	# Change to NAMD dir
	os.chdir (namdDir)
	os.system ("md_dcd_create_snapshots.tcl %s" % imagesDir)
	
	clip = mpy.ImageSequenceClip (imagesDir, fps=10)
	clip.write_videofile ("%s/%s_%s_trajectory_movie.mp4" % (outDir, confDir, ligandsDic [confDir])) # or any other format

	os.system ("rm -rf %s" % imagesDir)
	os.chdir (workingDir)

