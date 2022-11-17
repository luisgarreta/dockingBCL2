#!/usr/bin/python3
import sys
args = sys.argv

imagesDir = args[1]

"Create movie from raw .rgb snapshots from VMD"

import moviepy.editor as mpy
clip = mpy.ImageSequenceClip(imagesDir, fps=10)
clip.write_videofile ("trajectory_movie.mp4") # or any other format
