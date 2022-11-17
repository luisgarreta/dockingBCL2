#!/bin/bash
#SBATCH --job-name=COF-5_nuc
#SBATCH --output=logfile.NAMD.%A.out
#SBATCH --partition=FULL
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --tasks-per-node=10
#SBATCH --mem=10G

# Version: 0.1

NP=380

# Run namd2 in parallel with two input parameters: 
INPUT_CONFIG=$1
OUTPUT_LOG=$2

#cmm="mpirun -bind-to core -np $NP namd2 $INPUT_CONFIG &> $OUTPUT_LOG"
cmm="namd2 +idlepoll +p${SLURM_CPUS_PER_TASK-1} $INPUT_CONFIG > $OUTPUT_LOG"
echo ">>>>>> :" $cmm
namd2 +idlepoll +p${SLURM_CPUS_PER_TASK-1} $INPUT_CONFIG > $OUTPUT_LOG
#eval $cmm


