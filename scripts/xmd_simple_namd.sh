#!/bin/bash
#SBATCH --job-name=COF-5_nuc
#SBATCH --output=logfile.NAMD.%A.out
#SBATCH --partition=FULL
#SBATCH --nodes=10
#SBATCH --tasks-per-node=38
#SBATCH --mem=10G

# Version: 0.1

NP=380

# Run namd2 in parallel with two input parameters: 
INPUT_CONFIG=$1
OUTPUT_LOG=$2

cmm="mpirun -bind-to core -np $NP namd2 $INPUT_CONFIG &> $OUTPUT_LOG"
echo ">>>>>> :" $cmm
#mpirun -bind-to core -np $NP namd2 $RUN_INPUT &> $OUT
eval $cmm


