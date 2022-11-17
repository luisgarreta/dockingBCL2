#!/usr/bin/env python3

import numpy as np
import math

# Checks if a matrix is a valid rotation matrix.
def isRotationMatrix(R) :
    Rt = np.transpose(R)
    shouldBeIdentity = np.dot(Rt, R)
    I = np.identity(3, dtype = R.dtype)
    n = np.linalg.norm(I - shouldBeIdentity)
    return n < 1e-6

# Calculates rotation matrix to euler angles
# The result is the same as MATLAB except the order
# of the euler angles ( x and z are swapped ).
def rotationMatrixToEulerAngles(R) :

    assert(isRotationMatrix(R))

    sy = math.sqrt(R[0,0] * R[0,0] +  R[1,0] * R[1,0])
    print ("sy = ", sy)
    print ("%s %s %s | %s %s %s | %s %s %s" % (R[0,0],R[0,1],R[0,2],R[1,0],R[1,1],R[1,2],R[2,0],R[2,1],R[2,2]))

    singular = sy < 1e-6

    if  not singular :
        x = math.atan2(R[2,1] , R[2,2])
        y = math.atan2(-R[2,0], sy)
        z = math.atan2(R[1,0], R[0,0])
    else :
        x = math.atan2(-R[1,2], R[1,1])
        y = math.atan2(-R[2,0], sy)
        z = 0

    return np.array([x*(180/math.pi), y*(180/math.pi), z*(180/math.pi)])

#--------------------------------------------------------------------
#--------------------------------------------------------------------
#--------------------------------------------------------------------
#--------------------------------------------------------------------
R1 = np.array ( [ 
    [ 0.9999814629554749, 0.00020133047655690461, -0.006083567626774311], 
    [ -0.00017090550682041794, 0.9999874830245972, 0.00500127 ], 
    [ 0.006084498483687639, -0.005000146105885506, 0.9999690055847168 ] ])

R2 = np.array ([
    [ 0.9999423027038574, -0.010726002976298332, -0.0005592816742137074  ],
    [ 0.01074045430868864, 0.9988203644752502, 0.0473554655909],
    [ 5.0687060138443485e-5, -0.047358740121126175, 0.9988779425621033]])

print (isRotationMatrix (R1))
print (rotationMatrixToEulerAngles (R1))

