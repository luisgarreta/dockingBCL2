DIR1="trajectory1000ns-noLOOPs-Protein"
DIR2="trajectory1000ns-noLOOPs-Complex"
OUT="out-rmsds-1000ns-noLOOPs"

rmsds-ALLP.py $DIR1 
rmsds-ALLP.py $DIR2 

mkdir $OUT
cp out-$DIR1/out-$DIR1.csv $OUT
cp out-$DIR2/out-$DIR2.csv $OUT

cmm="create-longtable-fromFiles.py $OUT"; echo $cmm; eval $cmm
cmm='plot-XY-MultiLine.R $OUT-LONG.csv "FRAME" "RMSD" "SYSTEM" "RMSDs complex vs. protein" "FRAME (ns)"'; echo $cmm; eval $cmm

