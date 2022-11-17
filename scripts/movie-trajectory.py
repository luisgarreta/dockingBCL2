#!/usr/bin/env python3

#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python3
import sys
args = sys.argv
USAGE="USAGE: movie-trajectory.py <Input dir> <Frames per second number>"

if (len (args) < 3):
    print (USAGE)
    sys.exit()

imagesDir = args [1]
FPS = args [2]
movieName = imagesDir + "-" + FPS + "FPS.mp4"

"Create movie from raw .rgb snapshots from VMD"

import moviepy.editor as mpy
clip = mpy.ImageSequenceClip(imagesDir, fps=int (FPS))
clip.write_videofile (movieName) # or any other format

