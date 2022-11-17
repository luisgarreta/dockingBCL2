#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/opt/miniconda3/envs/prolif/bin/python

USAGE="\
Creates movie for each ligand dcd trajectory \
USAGE: movie-trajectory-ALL.py <input trajectories dir>"

import os, sys
import moviepy.editor as mpy
import multiprocessing as mp
from functools import partial
import cv2
import numpy as np

def main ():
	args = sys.argv

	inputDir   = args [1]	# trajectories
	outputDir  = "out-movies"
	WORKINGDIR = os.getcwd()

	# Execute in parallel with multiple arguments
	pool = mp.Pool (maxtasksperchild=1)
	dirList = os.listdir (inputDir)
	params = [inputDir, outputDir, WORKINGDIR]
	#pool.map (partial (createMovie, inputDir, outputDir, WORKINGDIR), dirList) 
	for dir in dirList:
		createMovie (inputDir, outputDir, WORKINGDIR, dir) 
		# Create snapshot movie
		os.chdir (WORKINGDIR)

#---------------------------------------------------------------------
#---------------------------------------------------------------------
def createMovie (inputDir, outputDir, WORKINGDIR, dir):
	inputPath  = "%s/%s/%s" % (WORKINGDIR, inputDir, dir)

	# Create and change to out dir and run commands
	outputPath = "%s/%s/%s" % (WORKINGDIR, outputDir, dir)
	os.system ("mkdir -p %s" % outputPath)
	os.chdir (outputPath)

	# Create movie
	clip = mpy.ImageSequenceClip (inputPath, fps=10)
	clip.write_videofile ("movie-trajectory.mp4") 
	createSnapshotMovie (inputPath, dir)

#---------------------------------------------------------------------
def createSnapshotMovie (inputPath, dir):
	imagesList = ["%s/%s" % (inputPath, x) for x in sorted (os.listdir (inputPath))]
	n      = len (imagesList)
	print (">>>", n)
	k      = int (n / 5)
	paths = []
	for i in range (0, n, k):
		name = imagesList[i]
		print (name)
		image = cv2.imread(name)
		paths.append (image)

	# concatenating images horizontally
	snapshotName = "movie-snapshot.png"
	horizontal_concat = np.concatenate(paths, axis=1)
	snapshotName = dir.split ("-")[1]
	cv2.putText (horizontal_concat, text=snapshotName, org=(10,80), fontFace=cv2.FONT_HERSHEY_TRIPLEX, fontScale=3, color=(255, 255, 0),thickness=2)
	cv2.imwrite("moviesnapshot-%s.png" % snapshotName, horizontal_concat)
#
#---------------------------------------------------------------------
main ()

