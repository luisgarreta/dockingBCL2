#!/users/legarreta/opt/miniconda3/envs/sims/bin/python
#!/usr/bin/python3

"""

"""

import cv2
import numpy as np
import os, sys

args = sys.argv
imagesDir    = args [1]
snapshotName = args [2]
workingDir   = os.path.basename (os.getcwd ())

imagesList = os.listdir (imagesDir)
n      = len (imagesList)
k      = int (n / 5)
paths = []
for i in range (0, n, k):
    name = "%s/snap.%.4d.png" % (imagesDir, i)
    image = cv2.imread(name)
    paths.append (image)

# concatenating images horizontally
horizontal_concat = np.concatenate(paths, axis=1)
cv2.putText (horizontal_concat, text=workingDir, org=(10,80), fontFace=cv2.FONT_HERSHEY_TRIPLEX, fontScale=3, color=(255, 255, 0),thickness=2)
cv2.imwrite("%s.png" % snapshotName, horizontal_concat)

