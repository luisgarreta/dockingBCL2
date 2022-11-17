#!/bin/bash
#SBATCH --job-name=COF-5_nuc
#SBATCH --output=logfile.NAMD.%A.out
#SBATCH --partition=FULL
#SBATCH --nodes=20
#SBATCH --tasks-per-node=39
#SBATCH --mem=10G

NP=780

# Run namd2 in paraller with two input parameters: 
# INPUT: input config file
# OUT:   output log file

prod_step=$1
cnt=$2 
prod_prefix=$3
equi_prefix=$4

#echo ">>>>>>> VARS: <<<<<<<<"
#echo $prod_step
#echo $cnt
#echo $prod_prefix
#echo $equi_prefix
#echo ">>>>>>>       <<<<<<<<"

echo ">>>>>>>>>>>>> STEP $cnt  <<<<<<<<<<<<"
outputname="${prod_step}_${cnt}"
RUN_INPUT="${prod_step}_${cnt}_run.inp"
if [ $cnt == 1 ]; then
	# change only the output name
	cmm1="sed "s/${prod_prefix}/${outputname}/" ${prod_prefix}.inp > \
		$RUN_INPUT"
	echo ">>> " $cmm1
	eval $cmm1
else
	cntprev=$((cnt-1))
	equi_last=`printf ${equi_prefix} 6`
	inputname="${prod_step}_${cntprev}"
	# change input and output names from template file
	cmm2="sed "s/${equi_last}/${inputname}/" ${prod_prefix}.inp | \
	    sed "s/${prod_prefix}/${outputname}/" > $RUN_INPUT"
	echo ">>> " $cmm2
	eval $cmm2
fi
	
OUT=${outputname}.out

#echo ">>>>>>>>>>>>> NAMD STEP: $cnt <<<<<<<<<<<<"
#echo "INPUT: " $INPUT
#echo "OUT: " $OUT

#set cmm="python3 ./test.py"
cmm="mpirun -bind-to core -np $NP namd2 $RUN_INPUT &> $OUT"
echo "Running :" $cmm
mpirun -bind-to core -np $NP namd2 $RUN_INPUT &> $OUT

#sbatch <script>

